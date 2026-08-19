/**
 * Cloud Functions for DailyDee / Akh-ira.
 *
 * sendNudge — fired when a client writes a new nudge document at
 *   users/{recipientUid}/nudges/{nudgeId}
 * The function validates the sender is a friend, applies the recipient's
 * daily cap, and delivers an FCM push to every registered iOS token.
 *
 * sendFriendRequestPush — fired when a friend request lands at
 *   users/{recipientUid}/incomingRequests/{fromUid}
 * Notifies the recipient that someone wants to add them.
 *
 * sendFriendAcceptedPush — fired when a confirmed friendship doc appears at
 *   users/{uid}/friends/{friendUid}
 * The accept batch writes the doc on BOTH sides; only the original requester
 * (doc field `requesterUid` == list owner) gets the "accepted" push.
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
setGlobalOptions({ region: "europe-west3", maxInstances: 10 });

function todayKey() {
  const d = new Date();
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

// --- Localised copy for system pushes (friend requests / accepts). ---------
// The client mirrors the recipient's app language ("de" | "en" | "tr") into
// users/{uid}.language; German is the app default and the fallback.
const STRINGS = {
  de: {
    friendRequestTitle: "Neue Freundschaftsanfrage",
    friendRequestBody: (name) => `${name} möchte dein Freund sein.`,
    friendAcceptedTitle: "Anfrage angenommen",
    friendAcceptedBody: (name) => `${name} hat deine Freundschaftsanfrage angenommen.`,
  },
  en: {
    friendRequestTitle: "New friend request",
    friendRequestBody: (name) => `${name} wants to be your friend.`,
    friendAcceptedTitle: "Request accepted",
    friendAcceptedBody: (name) => `${name} accepted your friend request.`,
  },
  tr: {
    friendRequestTitle: "Yeni arkadaşlık isteği",
    friendRequestBody: (name) => `${name} arkadaşın olmak istiyor.`,
    friendAcceptedTitle: "İstek kabul edildi",
    friendAcceptedBody: (name) => `${name} arkadaşlık isteğini kabul etti.`,
  },
};

async function stringsFor(db, uid) {
  try {
    const doc = await db.doc(`users/${uid}`).get();
    const lang = doc.exists ? doc.data().language : null;
    return STRINGS[lang] || STRINGS.de;
  } catch (e) {
    return STRINGS.de;
  }
}

/** Reads every registered FCM token of a user. */
async function fetchTokens(db, uid) {
  const snap = await db.collection(`users/${uid}/fcmTokens`).get();
  const tokens = [];
  snap.docs.forEach((doc) => {
    const t = doc.data().token;
    if (typeof t === "string" && t.length > 0) tokens.push({ id: doc.id, token: t });
  });
  return tokens;
}

/**
 * Sends one notification to every token of `uid` and prunes tokens FCM
 * reports as dead. Returns the multicast response (or null without tokens).
 */
async function pushToUser(db, uid, { title, body, data }) {
  const tokens = await fetchTokens(db, uid);
  if (tokens.length === 0) return null;

  const response = await getMessaging().sendEachForMulticast({
    tokens: tokens.map((x) => x.token),
    notification: { title, body },
    apns: {
      payload: {
        aps: { sound: "default", badge: 1 },
      },
    },
    data: data || {},
  });

  const removals = [];
  response.responses.forEach((r, idx) => {
    if (!r.success) {
      const code = r.error && r.error.code;
      if (
        code === "messaging/invalid-registration-token" ||
        code === "messaging/registration-token-not-registered"
      ) {
        removals.push(db.doc(`users/${uid}/fcmTokens/${tokens[idx].id}`).delete());
      }
    }
  });
  if (removals.length > 0) await Promise.allSettled(removals);

  return response;
}

function visibleName(docData) {
  const dn = docData.displayName;
  if (typeof dn === "string" && dn.length > 0) return dn;
  const un = docData.username;
  if (typeof un === "string" && un.length > 0) return `@${un}`;
  return "Jemand";
}

// --- Nudges -----------------------------------------------------------------

exports.sendNudge = onDocumentCreated(
  "users/{recipientUid}/nudges/{nudgeId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const db = getFirestore();
    const { recipientUid, nudgeId } = event.params;
    const nudge = snap.data() || {};

    const finish = async (status, reason) => {
      await snap.ref.set(
        {
          delivered: status === "delivered",
          status,
          reason: reason || null,
          processedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    };

    // 1) Sender must be a confirmed friend of the recipient.
    const senderUid = nudge.senderUid;
    if (!senderUid || senderUid === recipientUid) {
      await finish("rejected", "invalid_sender");
      return;
    }
    const friendDoc = await db
      .doc(`users/${recipientUid}/friends/${senderUid}`)
      .get();
    if (!friendDoc.exists) {
      await finish("rejected", "not_friend");
      return;
    }

    // 2) Recipient preferences. Defaults: receive=true, cap=3/day.
    const prefsSnap = await db
      .doc(`users/${recipientUid}/notificationPreferences/main`)
      .get();
    const prefs = prefsSnap.exists ? prefsSnap.data() : {};
    if (prefs.receiveNudges === false) {
      await finish("rejected", "recipient_disabled");
      return;
    }
    const cap =
      typeof prefs.maxNudgesPerDay === "number" && prefs.maxNudgesPerDay > 0
        ? prefs.maxNudgesPerDay
        : 3;

    // 3) Registered tokens — checked BEFORE the daily-count gate so that
    //    undeliverable nudges don't consume the recipient's quota.
    const tokens = await fetchTokens(db, recipientUid);
    if (tokens.length === 0) {
      await finish("rejected", "no_tokens");
      return;
    }

    // 4) Atomic daily-count gate.
    const dayKey = todayKey();
    const countRef = db.doc(
      `users/${recipientUid}/dailyNudgeCounts/${dayKey}`
    );
    const allowed = await db.runTransaction(async (tx) => {
      const cdoc = await tx.get(countRef);
      const current = cdoc.exists ? cdoc.data().count || 0 : 0;
      if (current >= cap) return false;
      tx.set(
        countRef,
        {
          count: current + 1,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return true;
    });
    if (!allowed) {
      await finish("rejected", "daily_cap_reached");
      return;
    }

    // 5) Fan out to every registered token.
    const title = (typeof nudge.title === "string" && nudge.title) || "Akh-ira";
    const body = (typeof nudge.body === "string" && nudge.body) || "";
    const response = await pushToUser(db, recipientUid, {
      title,
      body,
      data: {
        kind: "nudge",
        nudgeId,
        senderUid: String(senderUid),
        senderUsername: String(nudge.senderUsername || ""),
        goalType: String(nudge.goalType || ""),
      },
    });

    const delivered = response !== null && response.successCount > 0;
    await finish(
      delivered ? "delivered" : "failed",
      delivered ? null : "no_token_succeeded"
    );
  }
);

// --- Friend requests ---------------------------------------------------------

exports.sendFriendRequestPush = onDocumentCreated(
  "users/{recipientUid}/incomingRequests/{fromUid}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const db = getFirestore();
    const { recipientUid, fromUid } = event.params;
    const request = snap.data() || {};

    const t = await stringsFor(db, recipientUid);
    await pushToUser(db, recipientUid, {
      title: t.friendRequestTitle,
      body: t.friendRequestBody(visibleName(request)),
      data: {
        kind: "friendRequest",
        senderUid: String(fromUid),
        senderUsername: String(request.username || ""),
      },
    });
  }
);

exports.sendFriendAcceptedPush = onDocumentCreated(
  "users/{uid}/friends/{friendUid}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { uid, friendUid } = event.params;
    const friendship = snap.data() || {};

    // The accept batch creates the doc on both sides. Only the doc that lands
    // in the ORIGINAL requester's list (requesterUid == list owner) triggers
    // the "your request was accepted" push. Docs written before this field
    // existed (or the accepter's own copy) stay silent.
    if (friendship.requesterUid !== uid) return;

    const db = getFirestore();
    const t = await stringsFor(db, uid);
    await pushToUser(db, uid, {
      title: t.friendAcceptedTitle,
      body: t.friendAcceptedBody(visibleName(friendship)),
      data: {
        kind: "friendAccepted",
        senderUid: String(friendUid),
        senderUsername: String(friendship.username || ""),
      },
    });
  }
);

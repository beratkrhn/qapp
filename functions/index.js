/**
 * Cloud Functions for DailyDee / Akh-ira.
 *
 * sendNudge — fired when a client writes a new nudge document at
 *   users/{recipientUid}/nudges/{nudgeId}
 * The function validates the sender is a friend, applies the recipient's
 * daily cap, and delivers an FCM push to every registered iOS token.
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
    const tokensSnap = await db
      .collection(`users/${recipientUid}/fcmTokens`)
      .get();
    const tokens = [];
    tokensSnap.docs.forEach((doc) => {
      const t = doc.data().token;
      if (typeof t === "string" && t.length > 0) tokens.push({ id: doc.id, token: t });
    });
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
    const response = await getMessaging().sendEachForMulticast({
      tokens: tokens.map((x) => x.token),
      notification: { title, body },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
      data: {
        nudgeId,
        senderUid: String(senderUid),
        senderUsername: String(nudge.senderUsername || ""),
        goalType: String(nudge.goalType || ""),
      },
    });

    // 6) Prune tokens the FCM service tells us are invalid.
    const removals = [];
    response.responses.forEach((r, idx) => {
      if (!r.success) {
        const code = r.error && r.error.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          removals.push(
            db
              .doc(`users/${recipientUid}/fcmTokens/${tokens[idx].id}`)
              .delete()
          );
        }
      }
    });
    if (removals.length > 0) await Promise.allSettled(removals);

    await finish(
      response.successCount > 0 ? "delivered" : "failed",
      response.successCount > 0 ? null : "no_token_succeeded"
    );
  }
);

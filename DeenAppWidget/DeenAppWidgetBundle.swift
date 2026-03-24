//
//  DeenAppWidgetBundle.swift
//  DailyDeen Widget
//

import WidgetKit
import SwiftUI

@main
struct DailyDeenWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyDeenOverviewWidget()
        DailyDeenTimerWidget()
    }
}

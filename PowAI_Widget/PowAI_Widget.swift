//
//  PowAI_Widget.swift
//  PowAI_Widget
//
//  Created by Daniel Pinilla on 6/16/24.
//
import WidgetKit
import SwiftUI
import ActivityKit

private func widgetLocalized(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}




struct PowAI_Widget: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeTrackingAttributes.self) { context in
            if context.state.dayPlanTitle != nil {
                DayPlanLockScreenView(context: context)
            } else {
                TimerLockScreenView(context: context)
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading){
                    if context.state.dayPlanTitle != nil {
                        DayPlanIslandStatusView(context: context)
                    } else {
                        TimerIslandStatusView(context: context)
                    }
                }
                DynamicIslandExpandedRegion(.center){
                    if context.state.dayPlanTitle != nil {
                        DayPlanIslandTitleView(context: context)
                    } else {
                        TimerIslandTitleView(context: context)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.dayPlanTitle != nil {
                        DayPlanIslandCountdownView(context: context)
                    } else {
                        TimerIslandCountdownView(context: context)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.dayPlanTitle != nil {
                        DayPlanIslandNextView(context: context)
                    } else {
                        TimerIslandMetricsView(context: context)
                    }
                }
            } compactLeading: {
                if context.state.dayPlanTitle != nil {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.cyan)
                } else {
                    HStack{
                        Image(systemName: "timer").foregroundStyle(Color.red)
                        Text(context.state.startTime,style: .timer).frame(width: 50).foregroundStyle(Color.red)
                    }
                }
                
            } compactTrailing: {
                if let dayPlanTimerTime = dayPlanPrimaryCountdownTime(context.state) {
                    Text(dayPlanTimerTime, style: .timer)
                        .font(.caption2.weight(.black))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .frame(width: 56, alignment: .trailing)
                        .foregroundStyle(.cyan)
                } else {
                    Text("Set \(context.state.set)")
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            } minimal: {
                if let dayPlanTimerTime = dayPlanPrimaryCountdownTime(context.state) {
                    Text(dayPlanTimerTime, style: .timer)
                        .bold()
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                } else {
                    Text(context.state.startTime, style: .timer)
                        .bold()
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
        }
    }
    func getTat(dta: Date)-> String {
       // let date = dta
        //let calendar = Calendar.current
       
        
        return ""
    }
    
}

private func dayPlanPrimaryCountdownTime(_ state: TimeTrackingAttributes.ContentState) -> Date? {
    if state.dayPlanIsCurrentBlock == true {
        return state.dayPlanEndTime
    }
    return state.dayPlanLeaveTime ?? state.dayPlanEndTime
}

private func dayPlanPrimaryCountdownLabel(_ state: TimeTrackingAttributes.ContentState) -> String {
    if state.dayPlanIsCurrentBlock == true {
        return widgetLocalized("LEFT")
    }
    return widgetLocalized(state.dayPlanLeaveTime != nil ? "LEAVE" : "STARTS")
}

struct DayPlanLockScreenView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    private var nextStartTime: Date? {
        context.state.dayPlanNextStartTime
    }

    private var hasLeaveTime: Bool {
        context.state.dayPlanLeaveTime != nil
    }

    private var primaryCountdownTime: Date? {
        dayPlanPrimaryCountdownTime(context.state)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(context.state.dayPlanStatus ?? widgetLocalized("Now"), systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.cyan)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(context.state.dayPlanTitle ?? widgetLocalized("Day Plan"))
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(dayPlanPrimaryCountdownLabel(context.state))
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let primaryCountdownTime {
                        Text(primaryCountdownTime, style: .timer)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.cyan)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                }
                .frame(width: 96, alignment: .trailing)
            }

            Divider()

            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        if let nextStartTime {
                            countdownPill(label: widgetLocalized("NEXT IN"), date: nextStartTime)
                        }
                        if hasLeaveTime, let leaveTime = context.state.dayPlanLeaveTime {
                            countdownPill(label: widgetLocalized("LEAVE BY"), date: leaveTime)
                        }
                    }
                    Text(context.state.dayPlanNextTitle ?? widgetLocalized("No next activity"))
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Text(context.state.dayPlanCategory ?? widgetLocalized("Plan"))
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.cyan.opacity(0.16), in: Capsule())
                    .foregroundStyle(.cyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .activityBackgroundTint(Color.black.opacity(0.48))
    }

    private func countdownPill(label: String, date: Date) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            Text(date, style: .timer)
                .font(.caption2.weight(.black))
                .foregroundStyle(.cyan)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .lineLimit(1)
    }
}

struct DayPlanIslandStatusView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "calendar.badge.clock")
                .font(.caption.weight(.black))
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 1) {
                Text(context.state.dayPlanStatus ?? widgetLocalized("Now"))
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.cyan)
                    .lineLimit(1)
                Text(context.state.dayPlanCategory ?? widgetLocalized("Plan"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: 86, alignment: .leading)
    }
}

struct DayPlanIslandTitleView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    var body: some View {
        Text(context.state.dayPlanTitle ?? widgetLocalized("Day Plan"))
            .font(.headline.weight(.black))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: 140)
    }
}

struct DayPlanIslandNextView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    private var hasLeaveTime: Bool {
        context.state.dayPlanLeaveTime != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                if let nextStartTime = context.state.dayPlanNextStartTime {
                    islandCountdown(label: widgetLocalized("NEXT IN"), date: nextStartTime)
                }
                if hasLeaveTime, let leaveTime = context.state.dayPlanLeaveTime {
                    islandCountdown(label: widgetLocalized("LEAVE BY"), date: leaveTime)
                }
            }

            HStack(spacing: 5) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                Text(context.state.dayPlanNextTitle ?? widgetLocalized("None"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func islandCountdown(label: String, date: Date) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            Text(date, style: .timer)
                .font(.caption2.weight(.black))
                .foregroundStyle(.cyan)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .lineLimit(1)
    }
}

struct DayPlanIslandCountdownView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(dayPlanPrimaryCountdownLabel(context.state))
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            if let countdownTime = dayPlanPrimaryCountdownTime(context.state) {
                Text(countdownTime, style: .timer)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.cyan)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .frame(width: 66, alignment: .trailing)
            }
        }
        .frame(width: 70, alignment: .trailing)
    }
}

struct TimerIslandStatusView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "timer")
                .font(.caption.weight(.black))
                .foregroundStyle(.red)
            Text("Rest")
                .font(.caption.weight(.black))
                .foregroundStyle(.red)
                .lineLimit(1)
        }
        .frame(maxWidth: 78, alignment: .leading)
    }
}

struct TimerIslandTitleView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    var body: some View {
        Text("Recovery")
            .font(.headline.weight(.black))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

struct TimerIslandCountdownView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("ELAPSED")
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            Text(context.state.startTime, style: .timer)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.red)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(width: 66, alignment: .trailing)
        }
        .frame(width: 70, alignment: .trailing)
    }
}

struct TimerIslandMetricsView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Label("Set \(context.state.set)", systemImage: "number.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            if let bpm = context.state.heartRate {
                Label("\(bpm) BPM", systemImage: "heart.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}



struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    // Zone color matching HealthKitManager's 5-zone model
    private var zoneColor: Color {
        guard let bpm = context.state.heartRate else { return .gray }
        switch bpm {
        case ..<100:  return Color(red: 0.2, green: 0.8, blue: 0.4)
        case 100..<130: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case 130..<155: return Color(red: 1.0, green: 0.75, blue: 0.0)
        case 155..<175: return Color(red: 1.0, green: 0.4,  blue: 0.0)
        default:        return Color(red: 1.0, green: 0.1,  blue: 0.1)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // ── Set counter ───────────────────────────────────────────────
            VStack(spacing: 2) {
                Text("SET")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("\(context.state.set)")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 36)

            // ── Elapsed timer ─────────────────────────────────────────────
            VStack(spacing: 2) {
                Text("ELAPSED")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.tint)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 36)

            // ── Heart rate ────────────────────────────────────────────────
            VStack(spacing: 2) {
                Text("BPM")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(zoneColor)
                    if let bpm = context.state.heartRate {
                        Text("\(bpm)")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundStyle(zoneColor)
                            .contentTransition(.numericText())
                    } else {
                        Text("--")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}

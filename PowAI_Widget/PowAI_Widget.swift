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
                if let endTime = context.state.dayPlanEndTime {
                    Text(endTime, style: .timer)
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
                if let endTime = context.state.dayPlanEndTime {
                    Text(endTime, style: .timer)
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

struct DayPlanLockScreenView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    private var endTime: Date {
        context.state.dayPlanEndTime ?? Date()
    }

    private var nextStartTime: Date? {
        context.state.dayPlanNextStartTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(context.state.dayPlanStatus ?? widgetLocalized("Now"), systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.cyan)

                    Text(context.state.dayPlanTitle ?? widgetLocalized("Day Plan"))
                        .font(.title3.weight(.black))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(widgetLocalized("LEFT"))
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                    Text(endTime, style: .timer)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.cyan)
                        .monospacedDigit()
                }
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(widgetLocalized("NEXT"))
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                        if let nextStartTime {
                            Text(widgetLocalized("IN"))
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.secondary)
                            Text(nextStartTime, style: .timer)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.cyan)
                                .monospacedDigit()
                        }
                    }
                    Text(context.state.dayPlanNextTitle ?? widgetLocalized("No next activity"))
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                }

                Spacer()

                Text(context.state.dayPlanCategory ?? widgetLocalized("Plan"))
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.cyan.opacity(0.16), in: Capsule())
                    .foregroundStyle(.cyan)
            }
        }
        .padding(.vertical, 8)
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

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)

            Text("\(widgetLocalized("Next:")) \(context.state.dayPlanNextTitle ?? widgetLocalized("None"))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let nextStartTime = context.state.dayPlanNextStartTime {
                Text(widgetLocalized("in"))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(nextStartTime, style: .timer)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.cyan)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DayPlanIslandCountdownView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(widgetLocalized("LEFT"))
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            if let endTime = context.state.dayPlanEndTime {
                Text(endTime, style: .timer)
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

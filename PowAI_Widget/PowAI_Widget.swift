//
//  PowAI_Widget.swift
//  PowAI_Widget
//
//  Created by Daniel Pinilla on 6/16/24.
//
import WidgetKit
import SwiftUI
import ActivityKit




struct PowAI_Widget: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeTrackingAttributes.self) { context in
            TimerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.trailing) {
                    HStack {
                        //Text("Time So far:").bold().font(.title2)
                        Text(context.state.startTime, style: .timer)
                            .bold()
                            .font(.title2)
                            .foregroundColor(.red) // Example of adding color
                        
                    }
                }
                DynamicIslandExpandedRegion(.center){
                    Text("Time So far:").bold().font(.title2)
                }
                DynamicIslandExpandedRegion(.leading){
                    Text("Resting...").font(.title)
                }
            } compactLeading: {
                HStack{
                    Image(systemName: "timer").foregroundStyle(Color.red)
                    Text(context.state.startTime,style: .timer).frame(width: 50).foregroundStyle(Color.red)
                    //Text("Set: \(context.state.startTime.timeIntervalSince())")
                    
                }
                
            } compactTrailing: {
                Text("Set \(context.state.set)")
            } minimal: {
                
                Text(context.state.startTime, style: .timer)
                    .bold()
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
        }
    }
    func getTat(dta: Date)-> String {
       // let date = dta
        //let calendar = Calendar.current
       
        
        return ""
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


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
                    .foregroundColor(.accentColor)
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

    var body: some View {
        HStack{
            Spacer(minLength: 20)
            Text("Set: \(context.state.set)").font(.title)
                .bold()
                .foregroundColor(.red) // Example of adding color
            Spacer(minLength: 20)
            Text(context.state.startTime, style: .timer)
                .font(.title)
                .bold()
                .foregroundColor(.accentColor) // Example of adding color
        }
    }
}


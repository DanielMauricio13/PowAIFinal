//
//  staringWorkWindow.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/31/24.
//

import SwiftUI
import ActivityKit
import Foundation
import BackgroundTasks
import UserNotifications
import AudioToolbox

struct StaringWorkWindow: View {
    var todaysWork: workout_plans?
    @State private var timeRemaining = 5
    @State private var timerIsRunning = false
    @State private var timeRemaining2 = 60
    @State private var timerIsRunning2 = false
    @State var totalTime = 5
    @State var totalTime2 = 60
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let timer2 = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @Binding var exToday: String
    @State var index = 0
    @State var set = 1
    var cals: Int
    @State var finishedSet = false
    @State var finishedRecover = false
    
    @State var activity: Activity<TimeTrackingAttributes>? = nil
    @State var isTrackingTime: Bool = false
    @State var startTime: Date? = nil
    @State var excSer: Int? = 3

        
    
    var body: some View {
        if timeRemaining == 0 || index >= todaysWork?.exercises.count ?? 1 {                //if strting exercise time has ended or workout is over
            VStack {
                if index >= todaysWork?.exercises.count ?? 1 {                              //if workout is over
                    Spacer()
                    Text("All Done!").font(.title3).italic().bold().foregroundStyle(Color.orange).font(.title2)
                    Text("You just burned \(cals) calories 🔥").font(.title2).italic().bold().foregroundStyle(Color.red)

                    Button {
                        exToday = ""
                    } label: {
                        Text("Go Back").foregroundStyle(Color.white).font(.title2).bold().background(Rectangle().clipShape(.buttonBorder).frame(width: 100, height: 40)).padding(.top)
                    }
                }                       //workout is over
                else {
                    Text("\(todaysWork?.exercises[index].name ?? "PullUps")").font(.largeTitle).italic().bold().foregroundStyle(Color.white)

                    ImageView(imageURL: "https://app-couples-gym-5f9da74d1aec.herokuapp.com/images/imageName?name=\(todaysWork?.exercises[index].name ?? "bad").jpeg")
                        .frame(width: 400, height: 300)
                    if finishedSet == false ||  finishedRecover == true  {
                        HStack {
                            Text("Set \(set):").font(.title).padding(.leading).padding(.top).foregroundStyle(Color.white).bold()
                            Spacer()
                        }
                        Text("Reps \(todaysWork?.exercises[index].reps ?? "1")").font(.title).padding(.leading).padding(.top).foregroundStyle(Color.white).bold()
                        
                        HStack{
                            if set + 1 > excSer ?? 9{
                                Spacer()
                            }
                            if set + 1 > excSer ?? 9{
                                Button {
                                    set += 1
                                    excSer! += 1
                                    finishedSet = true
                                    finishedRecover = false
                                } label: {
                                    Text("Add Set").foregroundStyle(Color.white).font(.title2).bold().background(Capsule().frame(width: 100).foregroundStyle(.red)).padding(.top)
                                }
                            }
                            if set + 1 > excSer ?? 9{
                                Spacer()
                            }
                            Button {
                                set += 1
                                if (set > excSer ?? 4) {
                                    index += 1
                                    totalTime = 5
                                    timeRemaining = 5
                                    set = 1
                                } else {
                                    finishedSet = true
                                    finishedRecover = false
                                }
                            } label: {
                                Text("Finish Set").foregroundStyle(Color.white).font(.title2).bold().background(Rectangle().clipShape(.buttonBorder).frame(width: 100, height: 40)).padding(.top)
                            }.onAppear{
                                finishedSet = false
                                finishedRecover = false
                                triggerVibration()
                                excSer = todaysWork?.exercises[index].sets
                            }
                            if set + 1 > excSer ?? 9{
                                Spacer()
                            }
                        }
                    }
                    else {
                        
                        Text("Recovering from set \(set - 1)").font(.title).fontDesign(.rounded).bold()
                            Spacer()
                          
                        if let startTime {
                            
                            Text(startTime,style: .relative).foregroundStyle(Color.white).font(.title).fontDesign(.rounded).bold()
                        }
                        
                            Button {
                                isTrackingTime.toggle()
                                if isTrackingTime{
                                    startTime = .now
                                    
                                    let attriutes = TimeTrackingAttributes(Initial: .now)
                                    let state = TimeTrackingAttributes.ContentState(startTime: .now, set: set - 1)
                                    let contrent = ActivityContent(state: state, staleDate: nil)
                                    
                                    activity = try?  Activity<TimeTrackingAttributes>.request(attributes: attriutes, content: contrent, pushType: nil)
                                    
                                    
                                    let content = UNMutableNotificationContent()
                                    content.title = "60 Seconds and going!"
                                    content.body = "60 Seconds of  recovery time hvae passed. Go into the next set!"
                                    content.sound = .default

                                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(60), repeats: false)
                                    let request = UNNotificationRequest(identifier: "timerNotification", content: content, trigger: trigger)
                                    
                                    UNUserNotificationCenter.current().add(request) { error in
                                        if let error = error {
                                            print("Failed to schedule notification: \(error)")
                                        }
                                    }
                                    let content2 = UNMutableNotificationContent()
                                    content2.title = "90 Seconds and going!"
                                    content2.body = "90 Seconds of  recovery time have passed. Jump into the next set!"
                                    content2.sound = .default

                                    let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(90), repeats: false)
                                    let request2 = UNNotificationRequest(identifier: "timerNotification2", content: content2, trigger: trigger2)
                                    
                                    UNUserNotificationCenter.current().add(request2) { error in
                                        if let error = error {
                                            print("Failed to schedule notification: \(error)")
                                        }
                                    }
                                    
                                }
                                else {
                                    
                                    guard startTime != nil else {return}
                                    let finalContentState = TimeTrackingAttributes.ContentState(startTime: .now, set: set - 1)
                                    let finalContent = ActivityContent(state: finalContentState, staleDate: nil)
                                    
                                    Task {
                                        await activity?.end(finalContent, dismissalPolicy: .immediate)
                                       // cancelNotification()
                                    }
                                    
                                    
                                    self.startTime = nil
                                    finishedRecover = true
                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timerNotification", "timerNotification2"])
                                    
                                }
                            }label: {
                                Text(isTrackingTime ? "Stop" : "Start").font(.title).bold().fontDesign(.rounded).foregroundStyle(Color.red).background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).frame(width: 120, height: 60)).padding(.top)
                            }
                                
                       
                    }
                }
                Spacer()
            }
        } 
        else {
            VStack {
                Spacer()
                Text("Get Ready!\nNext Exercise is \(todaysWork?.exercises[index].name ?? "pushdowns")").font(.title).foregroundStyle(Color.white).padding(.bottom)
                ZStack {
                    CircularProgressView(progress: Double(totalTime - timeRemaining) / Double(totalTime))
                        .frame(width: 200, height: 200)
                    Text("\(timeRemaining)")
                        .font(.system(size: 100, weight: .bold, design: .monospaced))
                        .foregroundColor(timeRemaining > 3 ? .cyan : timeRemaining > 2 ? .yellow : .red)
                        .scaleEffect(timerIsRunning && timeRemaining > 0 ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: timeRemaining)
                }
                .padding()
                Spacer()
            }.onAppear {
                self.timeRemaining = totalTime
                self.timerIsRunning = true
            }
            .onReceive(timer) { _ in
                if self.timerIsRunning && self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                }
            }
        }
    }

    struct ImageView: View {
        let imageURL: String

        var body: some View {
            AsyncImage(url: URL(string: imageURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if phase.error != nil {
                    Text("Failed to load image")
                } else {
                    ProgressView()
                }
            }
            .frame(width: 400, height: 300)
           
        }
    }

    private func triggerVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

struct ImageView: View {
    let imageURL: String

    var body: some View {
        AsyncImage(url: URL(string: imageURL)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if phase.error != nil {
                Text("Failed to load image")
            } else {
                ProgressView()
            }
        }
        .frame(width: 400, height: 300)
       
    }
}

struct CircularProgressView: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var color: Color = .blue

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear(duration: 0.5), value: progress)
        }
    }
}


class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
 

    private init() {}

    

    private func scheduleNotification(in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Recovery Timer Ended"
        content.body = "Your recovery time has finished. Go into the next set!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "timerNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timerNotification"])
    }

    private func triggerVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

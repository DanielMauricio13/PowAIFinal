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
    @StateObject private var hkManager = HealthKitManager()
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
    
    private let gymBackground = LinearGradient(
        colors: [Color.black, Color(red: 0.12, green: 0.02, blue: 0.18), Color(red: 0.35, green: 0.04, blue: 0.12)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

        
    
    var body: some View {
        ZStack {
            gymBackground.ignoresSafeArea()
            if timeRemaining == 0 || index >= todaysWork?.exercises.count ?? 1 {                //if strting exercise time has ended or workout is over
                VStack {
                if index >= todaysWork?.exercises.count ?? 1 {                              //if workout is over
                    Spacer()
                    Text("All Done!").font(.title3).italic().bold().foregroundStyle(Color.orange).font(.title2)
                    Text("You just burned \(cals) calories 🔥").font(.title2).italic().bold().foregroundStyle(Color.red)

                    Button {
                        exToday = ""
                    } label: {
                        Text("Go Back")
                            .foregroundStyle(Color.white)
                            .font(.title3)
                            .bold()
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.red.opacity(0.9)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1.5))
                            .shadow(color: .red.opacity(0.35), radius: 12, x: 0, y: 6)
                            .padding(.top)
                    }
                }                       //workout is over
                else {
                    Text("\(todaysWork?.exercises[index].name ?? "PullUps")")
                        .font(.largeTitle)
                        .italic()
                        .bold()
                        .foregroundStyle(Color.white)
                        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 3)

                    ImageView(imageURL: "\(Constants.baseURL)images/imageName?name=\(todaysWork?.exercises[index].name ?? "bad").jpg")
                        .frame(width: 400, height: 300)
                    HeartRateOverlay(
                               bpm: hkManager.latestBPM,
                               isMonitoring: hkManager.isMonitoring
                           )
                           .padding(.top, 54)     // clears the safe-area / Dynamic Island
                           .padding(.trailing, 18)
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
                                    excSer = (excSer ?? set) + 1
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
                                Text("Finish Set")
                                    .foregroundStyle(Color.white)
                                    .font(.title3)
                                    .bold()
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.green.opacity(0.85)))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                    .shadow(color: .green.opacity(0.35), radius: 12, x: 0, y: 6)
                                    .padding(.top)
                            }.onAppear{
                                finishedSet = false
                                finishedRecover = false
                                triggerVibration()
                                excSer = todaysWork?.exercises[index].sets
                                
                            }.task { await hkManager.requestAuthorization() }
                               
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
                                    let state = TimeTrackingAttributes.ContentState(
                                        startTime: .now,
                                        set: set - 1,
                                        heartRate: hkManager.latestBPM   // ← seed with current reading
                                    )
                                    let contrent = ActivityContent(state: state, staleDate: nil)
                                    
                                    activity = try?  Activity<TimeTrackingAttributes>.request(attributes: attriutes, content: contrent, pushType: nil)
                                    
                                    
                                    let content = UNMutableNotificationContent()
                                    content.title = "60 Seconds and going!"
                                    content.body = "60 Seconds of  recovery time have passed. Go into the next set!"
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
                                    let finalContentState = TimeTrackingAttributes.ContentState(
                                        startTime: .now,
                                        set: set - 1,
                                        heartRate: hkManager.latestBPM
                                    )
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
                                Text(isTrackingTime ? "Stop" : "Start")
                                    .font(.title2)
                                    .bold()
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 14)
                                    .background(Capsule().fill(isTrackingTime ? Color.red : Color.orange))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1.2))
                                    .shadow(color: (isTrackingTime ? Color.red : Color.orange).opacity(0.4), radius: 14, x: 0, y: 8)
                                    .padding(.top)
                            }
                                
                       
                    }
                }
                Spacer()
                } .onDisappear { hkManager.stopMonitoring() }
                    .onChange(of: hkManager.latestBPM) { _, newBPM in   // ← add here
                          guard let activity else { return }
                          let updatedState = TimeTrackingAttributes.ContentState(
                              startTime: activity.content.state.startTime,
                              set: activity.content.state.set,
                              heartRate: newBPM
                          )
                          Task {
                              await activity.update(
                                  ActivityContent(state: updatedState, staleDate: nil)
                              )
                          }
                      }
            }
            else {
                VStack {
                Spacer()
                Text("Get Ready!\nNext Exercise is \(todaysWork?.exercises[index].name ?? "pushdowns")")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)
                    .padding(.bottom)
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
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 28).fill(.ultraThinMaterial).opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .padding(.horizontal)
                .onAppear {
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

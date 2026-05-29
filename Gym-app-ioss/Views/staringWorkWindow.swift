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
    var onWorkoutFinished: (() -> Void)? = nil
    var routineDay: Int? = nil
    var routineExerciseWeights: [Double] = []
    var routineExerciseUnits: [String] = []
    var onRoutineHome: (() -> Void)? = nil
    @State private var localRoutineWeights: [Double] = []
    @State private var localRoutineUnits: [String] = []
    @State private var showRoutineWeightMenu = false
    @State private var routineWeightDraft = ""
    @State private var routineUnitDraft = "lb"
    @State private var isSavingRoutineWeight = false
    @State private var routineWeightError = ""
    @State private var showRoutineWeightError = false
    
    @State var activity: Activity<TimeTrackingAttributes>? = nil
    @State var isTrackingTime: Bool = false
    @State var startTime: Date? = nil
    @State var excSer: Int? = 3
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            if routineDay != nil {
                VStack {
                    HStack {
                        Spacer()

                        Button {
                            exToday = ""
                            onRoutineHome?()
                        } label: {
                            Image(systemName: "house.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.orange.opacity(0.88))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Go Home")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    Spacer()
                }
                .zIndex(10)
            }

            if timeRemaining == 0 || index >= todaysWork?.exercises.count ?? 1 {                //if strting exercise time has ended or workout is over
                VStack {
                if index >= todaysWork?.exercises.count ?? 1 {                              //if workout is over
                    Spacer()
                    Text("All Done!").font(.title3).italic().bold().foregroundStyle(Color.orange).font(.title2)
                    Text("You just burned \(cals) calories 🔥").font(.title2).italic().bold().foregroundStyle(Color.red)

                    Button {
                        onWorkoutFinished?()
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
                        .frame(
                            width: AdaptiveLayout.clampedWidth(400, horizontalPadding: 24),
                            height: AdaptiveLayout.scaled(300, compact: 220)
                        )
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
                        if routineDay != nil {
                            Button {
                                prepareRoutineWeightMenu()
                            } label: {
                                Label(currentRoutineWeightText(), systemImage: "scalemass.fill")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.14))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                        
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
                        .frame(
                            width: AdaptiveLayout.scaled(200, compact: 160),
                            height: AdaptiveLayout.scaled(200, compact: 160)
                        )
                    Text("\(timeRemaining)")
                        .font(.system(size: AdaptiveLayout.scaled(100, compact: 76), weight: .bold, design: .monospaced))
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
        .onAppear {
            syncRoutineWeights()
        }
        .sheet(isPresented: $showRoutineWeightMenu) {
            routineWeightMenu
                .presentationDetents([.height(300)])
        }
        .alert("Couldn’t Update Weight", isPresented: $showRoutineWeightError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(routineWeightError)
        }
    }

    private var routineWeightMenu: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            VStack(spacing: 4) {
                Text("Update Weight")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .fontDesign(.rounded)

                Text(todaysWork?.exercises[safe: index]?.name ?? "Current Exercise")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                TextField("Weight", text: $routineWeightDraft)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                Picker("Unit", selection: $routineUnitDraft) {
                    Text("lb").tag("lb")
                    Text("kg").tag("kg")
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            Button {
                Task { await saveRoutineWeight() }
            } label: {
                HStack {
                    if isSavingRoutineWeight {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark")
                    }

                    Text(isSavingRoutineWeight ? "Saving..." : "Save Weight")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.orange)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(isSavingRoutineWeight)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
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
                    ImagePlaceholderView()
                } else {
                    ImagePlaceholderView()
                }
            }
            .frame(
                width: AdaptiveLayout.clampedWidth(400, horizontalPadding: 24),
                height: AdaptiveLayout.scaled(300, compact: 220)
            )
        }
    }

    private func triggerVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private func syncRoutineWeights() {
        guard localRoutineWeights.isEmpty, localRoutineUnits.isEmpty else { return }
        localRoutineWeights = routineExerciseWeights
        localRoutineUnits = routineExerciseUnits
    }

    private func prepareRoutineWeightMenu() {
        syncRoutineWeights()
        let weight = routineWeight(at: index)
        routineWeightDraft = weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
        routineUnitDraft = routineUnit(at: index)
        showRoutineWeightMenu = true
    }

    private func currentRoutineWeightText() -> String {
        "\(formattedRoutineWeight(at: index)) \(routineUnit(at: index))"
    }

    private func formattedRoutineWeight(at exerciseIndex: Int) -> String {
        let weight = routineWeight(at: exerciseIndex)
        return weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
    }

    private func routineWeight(at exerciseIndex: Int) -> Double {
        if localRoutineWeights.indices.contains(exerciseIndex) {
            return localRoutineWeights[exerciseIndex]
        }
        if routineExerciseWeights.indices.contains(exerciseIndex) {
            return routineExerciseWeights[exerciseIndex]
        }
        return 0
    }

    private func routineUnit(at exerciseIndex: Int) -> String {
        if localRoutineUnits.indices.contains(exerciseIndex) {
            return localRoutineUnits[exerciseIndex]
        }
        if routineExerciseUnits.indices.contains(exerciseIndex) {
            return routineExerciseUnits[exerciseIndex]
        }
        return "lb"
    }

    private func saveRoutineWeight() async {
        guard let routineDay else { return }
        guard let exercise = todaysWork?.exercises[safe: index] else {
            presentRoutineWeightError("Missing current exercise.")
            return
        }

        let trimmedWeight = routineWeightDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let weight = Double(trimmedWeight), weight >= 0 else {
            presentRoutineWeightError("Enter a valid weight.")
            return
        }

        isSavingRoutineWeight = true
        defer { isSavingRoutineWeight = false }

        do {
            guard let url = URL(string: Constants.baseURL + "routine/weight") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.applyBearerToken()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "day": routineDay,
                "exerciseIndex": index,
                "exerciseName": exercise.name,
                "weight": weight,
                "unit": routineUnitDraft
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard (200..<300).contains(http.statusCode) else {
                presentRoutineWeightError("Server returned status \(http.statusCode).")
                return
            }

            setRoutineWeight(weight, unit: routineUnitDraft, at: index)
            showRoutineWeightMenu = false
        } catch {
            presentRoutineWeightError(error.localizedDescription)
        }
    }

    private func setRoutineWeight(_ weight: Double, unit: String, at exerciseIndex: Int) {
        while localRoutineWeights.count <= exerciseIndex {
            localRoutineWeights.append(0)
        }
        while localRoutineUnits.count <= exerciseIndex {
            localRoutineUnits.append("lb")
        }

        localRoutineWeights[exerciseIndex] = weight
        localRoutineUnits[exerciseIndex] = unit
    }

    private func presentRoutineWeightError(_ message: String) {
        routineWeightError = message
        showRoutineWeightError = true
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
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
                ImagePlaceholderView()
            } else {
                ImagePlaceholderView()
            }
        }
        .frame(
            width: AdaptiveLayout.clampedWidth(400, horizontalPadding: 24),
            height: AdaptiveLayout.scaled(300, compact: 220)
        )
    }
}

struct ImagePlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(1.2)

            Text("Generating image for this exercise...")
                .font(.headline)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(
            width: AdaptiveLayout.clampedWidth(400, horizontalPadding: 24),
            height: AdaptiveLayout.scaled(300, compact: 220)
        )
        .background(Color.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
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

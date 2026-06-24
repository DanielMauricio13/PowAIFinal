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

private struct SetWeightLookupResponse: Decodable {
    let weight: Double
    let unit: String?
    let date: String?
}

private struct FetchedSetWeight {
    let weight: Double
    let unit: String
}

struct StaringWorkWindow: View {
    var todaysWork: workout_plans?
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @State private var activeWorkout: workout_plans?
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
    @State private var workoutCaloriesOverride: Int?
    @State var finishedSet = false
    @State var finishedRecover = false
    var onWorkoutFinished: (() -> Void)? = nil
    var routineDay: Int? = nil
    var challengeID: UUID? = nil
    var isHIITWorkout = false
    var isCustomWorkout = false
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
    @State private var showSetLogMenu = false
    @State private var setLogWeightDraft = ""
    @State private var setLogRepsDraft = ""
    @State private var setLogUnitDraft = "lb"
    @State private var setLogCompleted = true
    @State private var setWeightDisplayUnit = "lb"
    @State private var isSavingSetLog = false
    @State private var setLogError = ""
    @State private var showSetLogError = false
    @State private var fetchedSetWeights: [String: FetchedSetWeight] = [:]
    @State private var isReplacingExercise = false
    @State private var isAddingExtraExercise = false
    @State private var replaceExerciseError = ""
    @State private var showReplaceExerciseError = false
    @State private var hiitElapsedSeconds = 0
    @State private var hiitStopwatchRunning = false
    @State private var workoutStartedAt = Date()
    @State private var didPostWorkoutCompletion = false
    
    @State var activity: Activity<TimeTrackingAttributes>? = nil
    @State var isTrackingTime: Bool = false
    @State var startTime: Date? = nil
    @State var excSer: Int? = 3
    
    var body: some View {
        ZStack {
            AppBackgroundView()
            if shouldShowHomeButton {
                VStack {
                    HStack {
                        Spacer()

                        Button {
                            if isCustomWorkout {
                                onRoutineHome?()
                            } else {
                                exToday = ""
                                onRoutineHome?()
                            }
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

            if timeRemaining == 0 || index >= currentWorkout?.exercises.count ?? 1 {                //if strting exercise time has ended or workout is over
	                VStack {
	                if index >= currentWorkout?.exercises.count ?? 1 {                              //if workout is over
	                    workoutCompleteView
	                }                       //workout is over
	                else {
	                    exerciseWorkoutContent
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
                                  ActivityContent(
                                      state: updatedState,
                                      staleDate: nil,
                                      relevanceScore: LiveActivityRelevance.workout
                                  )
                              )
                          }
                      }
            }
            else {
                VStack {
                Spacer()
                Text("Get Ready!\nNext Exercise is \(currentExercise?.name ?? "pushdowns")")
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
                .padding(routineDay == nil ? 16 : 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if routineDay == nil {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial)
                            .opacity(0.95)
                    }
                }
                .overlay {
                    if routineDay == nil {
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                }
                .padding(.horizontal, routineDay == nil ? 16 : 0)
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
            activeWorkout = todaysWork
            workoutStartedAt = Date()
            didPostWorkoutCompletion = false
            syncRoutineWeights()
            if isHIITWorkout {
                hiitElapsedSeconds = 0
                hiitStopwatchRunning = true
            }
        }
        .onDisappear {
            hiitStopwatchRunning = false
        }
        .onReceive(timer) { _ in
            if isHIITWorkout && hiitStopwatchRunning {
                hiitElapsedSeconds += 1
            }
        }
        .task(id: currentSetFetchID) {
            await fetchLatestSetWeight()
        }
        .sheet(isPresented: $showRoutineWeightMenu) {
            routineWeightMenu
                .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showSetLogMenu) {
            setLogMenu
                .presentationDetents([.height(360)])
        }
        .alert("Couldn’t Update Weight", isPresented: $showRoutineWeightError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(routineWeightError)
        }
        .alert("Couldn’t Save Set", isPresented: $showSetLogError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(setLogError)
        }
        .alert("Couldn’t Replace Exercise", isPresented: $showReplaceExerciseError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(replaceExerciseError)
        }
    }

    private var currentWorkout: workout_plans? {
        activeWorkout ?? todaysWork
    }

    private var shouldShowHomeButton: Bool {
        routineDay != nil || isCustomWorkout
    }

    private var currentExercise: Excersise? {
        currentWorkout?.exercises[safe: index]
    }

    private var currentSetFetchID: String {
        guard let exercise = currentExercise else {
            return "missing-\(routineDay ?? 0)-\(index)-\(set)"
        }

        return setWeightLookupKey(exerciseName: exercise.name, setNumber: set)
    }

    private var currentExerciseDescription: String? {
        guard let exercise = currentExercise else { return nil }
        return localizedExerciseDescription(
            english: exercise.descriptionEng,
            spanish: exercise.descriptionEsp
        )
    }

    private var displayedCalories: Int {
        workoutCaloriesOverride ?? cals
    }

    private var workoutCompleteView: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Color.green)

                Text("All Done!")
                    .font(.system(size: AdaptiveLayout.scaled(34, compact: 29), weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)

                Text(localizedFormat("You just burned %d calories 🔥", displayedCalories))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.orange)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                if canAddExtraExercise {
                    Button {
                        Task { await addExtraExerciseFromReplacement() }
                    } label: {
                        HStack(spacing: 10) {
                            if isAddingExtraExercise {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "plus")
                            }

                            Text(isAddingExtraExercise ? "Adding..." : "Add One More Exercise")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(WorkoutPrimaryButtonStyle(tint: .orange))
                    .disabled(isAddingExtraExercise)
                }

                Button {
                    Task { await shareWorkoutCompletionIfNeeded() }
                    onWorkoutFinished?()
                    exToday = ""
                } label: {
                    Label("Finish Workout", systemImage: "house.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(WorkoutSecondaryButtonStyle(tint: .red))
                .disabled(isAddingExtraExercise)
            }
            .padding(16)
            .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .padding(.horizontal, AdaptiveLayout.isCompactPhone ? 12 : 18)

            Spacer()
        }
    }

    private var canAddExtraExercise: Bool {
        routineDay == nil && !isCustomWorkout && !(currentWorkout?.exercises.isEmpty ?? true)
    }

    private var exerciseWorkoutContent: some View {
        VStack(spacing: AdaptiveLayout.scaled(16, compact: 12)) {
            exerciseHeroView

            if finishedSet == false || finishedRecover == true {
                activeSetPanel
            } else {
                recoveryPanel
            }
        }
        .padding(.horizontal, AdaptiveLayout.isCompactPhone ? 12 : 18)
    }

    private var exerciseHeroView: some View {
        ZStack(alignment: .topTrailing) {
            ImageView(imageURL: "\(Constants.baseURL)images/imageName?name=\(currentExercise?.name ?? "bad").jpg")
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.72)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 10)

            VStack(alignment: .trailing, spacing: 8) {
                if isHIITWorkout {
                    hiitStopwatchView
                }

                HeartRateOverlay(
                    bpm: hkManager.latestBPM,
                    isMonitoring: hkManager.isMonitoring
                )
            }
            .padding(.top, 12)
            .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(currentExercise?.name ?? "Current Exercise")
                    .font(.system(size: AdaptiveLayout.scaled(28, compact: 23), weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 3)

                Text(currentSetProgressText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.42), in: Capsule())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(18)
        }
    }

    private var activeSetPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                workoutMetricPill(title: "Reps", value: currentExercise?.reps ?? "1", systemImage: "repeat")
                workoutMetricPill(title: "Saved", value: currentSetWeightText(), systemImage: "dumbbell.fill")
            }

            if let description = currentExerciseDescription {
                Text(description)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            workoutUtilityActions

            HStack(spacing: 12) {
                if shouldShowAddSet {
                    Button {
                        addExtraSet()
                    } label: {
                        Label("Add Set", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(WorkoutSecondaryButtonStyle(tint: .red))
                }

                Button {
                    finishCurrentSet()
                } label: {
                    Label("Finish Set", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(WorkoutPrimaryButtonStyle())
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .onAppear {
            finishedSet = false
            finishedRecover = false
            triggerVibration()
            excSer = currentExercise?.sets
        }
        .task { await hkManager.requestAuthorization() }
    }

    private var workoutUtilityActions: some View {
        HStack(spacing: 10) {
            Button {
                prepareSetLogMenu()
            } label: {
                Label("Log", systemImage: "square.and.pencil")
            }
            .buttonStyle(WorkoutChipButtonStyle(tint: .orange))
            .disabled(currentExercise == nil)

            Button {
                toggleSetWeightDisplayUnit()
            } label: {
                Label(setWeightDisplayUnit.uppercased(), systemImage: "arrow.left.arrow.right")
            }
            .buttonStyle(WorkoutChipButtonStyle(tint: .orange))

            if routineDay != nil {
                Button {
                    prepareRoutineWeightMenu()
                } label: {
                    Label(currentRoutineWeightText(), systemImage: "scalemass.fill")
                }
                .buttonStyle(WorkoutChipButtonStyle(tint: .orange))
            }

            if routineDay == nil && !isCustomWorkout {
                Button {
                    Task { await replaceCurrentExercise() }
                } label: {
                    if isReplacingExercise {
                        Label("Replacing", systemImage: "arrow.triangle.2.circlepath")
                    } else {
                        Label("Swap", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .buttonStyle(WorkoutChipButtonStyle(tint: .blue))
                .disabled(isReplacingExercise || currentExercise == nil)
            }
        }
        .labelStyle(.titleAndIcon)
    }

    private var recoveryPanel: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Recovering from set \(set - 1)")
                    .font(.system(size: AdaptiveLayout.scaled(26, compact: 22), weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)

                Text("Let your breathing settle before the next set.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .multilineTextAlignment(.center)
            }

            if let startTime {
                Text(startTime, style: .relative)
                    .font(.system(size: AdaptiveLayout.scaled(44, compact: 36), weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.orange)
                    .contentTransition(.numericText())
            } else {
                Text("Ready when you are")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.82))
            }

            Button {
                handleRecoveryTimerTap()
            } label: {
                Label(isTrackingTime ? "Stop Recovery" : "Start Recovery", systemImage: isTrackingTime ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(WorkoutPrimaryButtonStyle(tint: isTrackingTime ? .red : .orange))
        }
        .padding(20)
        .background(Color.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var currentSetProgressText: String {
        let totalSets = excSer ?? currentExercise?.sets ?? 0
        guard totalSets > 0 else { return "Set \(set)" }
        return "Set \(set) of \(max(set, totalSets))"
    }

    private var shouldShowAddSet: Bool {
        return set + 1 > (excSer ?? 9)
    }

    private var hiitStopwatchView: some View {
        HStack(spacing: 10) {
            Label(formattedHIITElapsedTime, systemImage: "stopwatch.fill")
                .font(.system(size: AdaptiveLayout.scaled(16, compact: 14), weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button {
                hiitStopwatchRunning.toggle()
            } label: {
                Image(systemName: hiitStopwatchRunning ? "pause.fill" : "play.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.16))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button {
                hiitElapsedSeconds = 0
                hiitStopwatchRunning = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.16))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.42))
        .overlay(
            Capsule()
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: Color.orange.opacity(0.25), radius: 10, x: 0, y: 4)
    }

    private var formattedHIITElapsedTime: String {
        let minutes = hiitElapsedSeconds / 60
        let seconds = hiitElapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func workoutMetricPill(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(Color.orange)
                .frame(width: 28, height: 28)
                .background(Color.orange.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.58))

                Text(value)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
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

                Text(currentExercise?.name ?? "Current Exercise")
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

    private var setLogMenu: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            VStack(spacing: 4) {
                Text("Log Set \(set)")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .fontDesign(.rounded)

                Text(currentExercise?.name ?? "Current Exercise")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                TextField("Reps", text: $setLogRepsDraft)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Weight (\(setLogUnitDraft))", text: $setLogWeightDraft)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            Picker("Unit", selection: $setLogUnitDraft) {
                Text("lb").tag("lb")
                Text("kg").tag("kg")
            }
            .pickerStyle(.segmented)
            .onChange(of: setLogUnitDraft) { oldUnit, newUnit in
                convertSetLogDraft(from: oldUnit, to: newUnit)
            }

            Toggle("Completed", isOn: $setLogCompleted)
                .font(.headline)

            Button {
                Task { await saveSetLog() }
            } label: {
                HStack {
                    if isSavingSetLog {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark")
                    }

                    Text(isSavingSetLog ? "Saving..." : "Save Set")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.orange)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(isSavingSetLog)
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

    private func addExtraSet() {
        resetHIITStopwatchAfterSet()
        set += 1
        excSer = (excSer ?? set) + 1
        finishedSet = true
        finishedRecover = false
    }

    private func finishCurrentSet() {
        resetHIITStopwatchAfterSet()
        set += 1
        if set > (excSer ?? 4) {
            index += 1
            totalTime = 5
            timeRemaining = 5
            set = 1
        } else {
            finishedSet = true
            finishedRecover = false
        }
    }

    private func resetHIITStopwatchAfterSet() {
        guard isHIITWorkout else { return }
        hiitElapsedSeconds = 0
        hiitStopwatchRunning = true
    }

    private func handleRecoveryTimerTap() {
        isTrackingTime.toggle()
        if isTrackingTime {
            startTime = .now

            let attributes = TimeTrackingAttributes(Initial: .now)
            let state = TimeTrackingAttributes.ContentState(
                startTime: .now,
                set: set - 1,
                heartRate: hkManager.latestBPM
            )
            let content = ActivityContent(
                state: state,
                staleDate: nil,
                relevanceScore: LiveActivityRelevance.workout
            )
            activity = try? Activity<TimeTrackingAttributes>.request(attributes: attributes, content: content, pushType: nil)
            LiveActivityManager.shared.prioritizeWorkoutOverDayPlan()

            scheduleRecoveryNotification(
                identifier: "timerNotification",
                seconds: 60,
                title: "60 Seconds and going!",
                body: "60 Seconds of recovery time have passed. Go into the next set!"
            )
            scheduleRecoveryNotification(
                identifier: "timerNotification2",
                seconds: 90,
                title: "90 Seconds and going!",
                body: "90 Seconds of recovery time have passed. Jump into the next set!"
            )
        } else {
            guard startTime != nil else { return }
            let finalContentState = TimeTrackingAttributes.ContentState(
                startTime: .now,
                set: set - 1,
                heartRate: hkManager.latestBPM
            )
            let finalContent = ActivityContent(
                state: finalContentState,
                staleDate: nil,
                relevanceScore: LiveActivityRelevance.workout
            )

            Task {
                await activity?.end(finalContent, dismissalPolicy: .immediate)
            }

            startTime = nil
            finishedRecover = true
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timerNotification", "timerNotification2"])
        }
    }

    private func scheduleRecoveryNotification(identifier: String, seconds: TimeInterval, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
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
        guard let exercise = currentExercise else {
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

    private func prepareSetLogMenu() {
        setLogUnitDraft = setWeightDisplayUnit
        if let fetchedWeight = fetchedSetWeightForCurrentSet() {
            let loggedSet = lastLoggedSetForCurrentExerciseAndSet()
            setLogRepsDraft = loggedSet.map { String($0.reps) } ?? defaultRepsForCurrentExercise()
            setLogWeightDraft = formattedDisplayWeight(fromPounds: fetchedWeight.weight, unit: setLogUnitDraft)
            setLogCompleted = loggedSet?.completed ?? true
        } else if let loggedSet = lastLoggedSetForCurrentExerciseAndSet() {
            setLogRepsDraft = String(loggedSet.reps)
            setLogWeightDraft = formattedDisplayWeight(fromPounds: loggedSet.weight, unit: setLogUnitDraft)
            setLogCompleted = loggedSet.completed
        } else {
            setLogRepsDraft = defaultRepsForCurrentExercise()
            setLogWeightDraft = "0"
            setLogCompleted = true
        }

        showSetLogMenu = true
    }

    private func currentSetLogText() -> String {
        "Set \(set): \(currentSetWeightText())"
    }

    private func currentSetWeightText() -> String {
        if let fetchedWeight = fetchedSetWeightForCurrentSet() {
            return "\(formattedDisplayWeight(fromPounds: fetchedWeight.weight, unit: setWeightDisplayUnit)) \(setWeightDisplayUnit)"
        }

        let weight = lastLoggedSetForCurrentExerciseAndSet()?.weight ?? 0
        return "\(formattedDisplayWeight(fromPounds: weight, unit: setWeightDisplayUnit)) \(setWeightDisplayUnit)"
    }

    private func currentSetWeightUnit() -> String {
        "lb"
    }

    private func currentSetWeightUnitFallback() -> String {
        "lb"
    }

    private func fetchedSetWeightForCurrentSet() -> FetchedSetWeight? {
        guard let exercise = currentExercise else { return nil }
        return fetchedSetWeights[setWeightLookupKey(exerciseName: exercise.name, setNumber: set)]
    }

    private func setWeightLookupKey(exerciseName: String, setNumber: Int) -> String {
        let source = challengeID == nil ? (routineDay == nil ? "training" : "routine") : "challenge"
        let normalizedName = exerciseName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return "\(source)|\(normalizedName)|\(setNumber)"
    }

    private func lastLoggedSetForCurrentExerciseAndSet() -> SetEntry? {
        currentExercise?.loggedSets
            .filter { $0.setNumber == set }
            .sorted { $0.date > $1.date }
            .first
    }

    private func defaultRepsForCurrentExercise() -> String {
        guard let reps = currentExercise?.reps,
              let range = reps.range(of: #"\d+"#, options: .regularExpression) else {
            return ""
        }

        return String(reps[range])
    }

    private func formattedWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
    }

    private func formattedDisplayWeight(fromPounds pounds: Double, unit: String) -> String {
        formattedWeight(displayWeight(fromPounds: pounds, unit: unit))
    }

    private func displayWeight(fromPounds pounds: Double, unit: String) -> Double {
        unit == "kg" ? pounds / 2.2046226218 : pounds
    }

    private func pounds(fromDisplayedWeight weight: Double, unit: String) -> Double {
        unit == "kg" ? weight * 2.2046226218 : weight
    }

    private func toggleSetWeightDisplayUnit() {
        setWeightDisplayUnit = setWeightDisplayUnit == "lb" ? "kg" : "lb"
    }

    private func convertSetLogDraft(from oldUnit: String, to newUnit: String) {
        guard oldUnit != newUnit else { return }
        let trimmedWeight = setLogWeightDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let displayedWeight = Double(trimmedWeight.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        let pounds = pounds(fromDisplayedWeight: displayedWeight, unit: oldUnit)
        setLogWeightDraft = formattedDisplayWeight(fromPounds: pounds, unit: newUnit)
        setWeightDisplayUnit = newUnit
    }

    private func fetchLatestSetWeight() async {
        guard let exercise = currentExercise else { return }

        let lookupKey = setWeightLookupKey(exerciseName: exercise.name, setNumber: set)

        do {
            let path = isCustomWorkout
                ? "training/custom-set-weight"
                : (routineDay == nil ? "training/set-weight" : "routine/set-weight")
            guard let url = URL(string: Constants.baseURL + path) else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.applyBearerToken()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "exerciseName": exercise.name,
                "setNumber": set
            ])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard (200..<300).contains(http.statusCode) else {
                print("Fetch set weight failed \(http.statusCode): \(responseBodyDescription(from: data))")
                return
            }

            let decoded = try JSONDecoder().decode(SetWeightLookupResponse.self, from: data)
            fetchedSetWeights[lookupKey] = FetchedSetWeight(
                weight: decoded.weight,
                unit: decoded.unit ?? currentSetWeightUnitFallback()
            )
        } catch {
            print("Failed to fetch set weight: \(error.localizedDescription)")
        }
    }

    private func saveSetLog() async {
        guard let workout = currentWorkout,
              let exercise = currentExercise else {
            presentSetLogError("Missing current exercise.")
            return
        }

        let trimmedReps = setLogRepsDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWeight = setLogWeightDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let reps = Int(trimmedReps), reps >= 0 else {
            presentSetLogError("Enter valid reps.")
            return
        }

        guard let displayedWeight = Double(trimmedWeight.replacingOccurrences(of: ",", with: ".")), displayedWeight >= 0 else {
            presentSetLogError("Enter a valid weight.")
            return
        }
        let weightInPounds = pounds(fromDisplayedWeight: displayedWeight, unit: setLogUnitDraft)

        isSavingSetLog = true
        defer { isSavingSetLog = false }

        do {
            let path = isCustomWorkout
                ? "training/custom-current-set"
                : challengeSetLogPath ?? (routineDay == nil ? "training/current-set" : "routine/current-set")
            guard let url = URL(string: Constants.baseURL + path) else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.applyBearerToken()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let now = Date()
            var body: [String: Any] = [
                "day": routineDay ?? workout.day,
                "exerciseIndex": index,
                "exerciseName": exercise.name,
                "currentSet": set,
                "reps": reps,
                "weight": weightInPounds,
                "unit": "lb",
                "completed": setLogCompleted,
                "date": SetEntry.isoDateString(from: now)
            ]
            if isCustomWorkout {
                body["muscleGroup"] = workout.muscle_group
                body["exercise"] = [
                    "name": exercise.name,
                    "reps": exercise.reps,
                    "sets": exercise.sets,
                    "calories_burned": exercise.calories_burned,
                    "descriptionEng": exercise.descriptionEng ?? "",
                    "descriptionEsp": exercise.descriptionEsp ?? "",
                    "loggedSets": []
                ]
            }
            let bodyData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = bodyData

#if DEBUG
            print("Save set POST \(url.absoluteString): \(responseBodyDescription(from: bodyData))")
#endif

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

#if DEBUG
            print("Save set response \(http.statusCode) (\(data.count) bytes)")
#endif

            guard (200..<300).contains(http.statusCode) else {
                presentSetLogError("Server returned status \(http.statusCode): \(responseBodyDescription(from: data))")
                return
            }

            setLoggedSet(
                SetEntry(
                    setNumber: set,
                    reps: reps,
                    weight: weightInPounds,
                    completed: setLogCompleted,
                    date: now
                ),
                at: index
            )
            fetchedSetWeights[setWeightLookupKey(exerciseName: exercise.name, setNumber: set)] = FetchedSetWeight(
                weight: weightInPounds,
                unit: "lb"
            )
            showSetLogMenu = false
        } catch {
            presentSetLogError(error.localizedDescription)
        }
    }

    private func setLoggedSet(_ entry: SetEntry, at exerciseIndex: Int) {
        guard var workout = activeWorkout,
              workout.exercises.indices.contains(exerciseIndex) else { return }

        var loggedSets = workout.exercises[exerciseIndex].loggedSets
        loggedSets.removeAll {
            $0.setNumber == entry.setNumber && Calendar.current.isDate($0.date, inSameDayAs: entry.date)
        }
        loggedSets.append(entry)

        loggedSets.sort {
            if Calendar.current.isDate($0.date, inSameDayAs: $1.date) {
                return $0.setNumber < $1.setNumber
            }
            return $0.date < $1.date
        }
        workout.exercises[exerciseIndex].loggedSets = loggedSets
        activeWorkout = workout
    }

    private func addExtraExerciseFromReplacement() async {
        guard routineDay == nil else { return }
        guard var workout = currentWorkout, !workout.exercises.isEmpty else {
            presentReplaceExerciseError("No exercises available to use as a template.")
            return
        }

        let sourceIndex = workout.exercises.indices.randomElement() ?? workout.exercises.startIndex
        let sourceExercise = workout.exercises[sourceIndex]

        isAddingExtraExercise = true
        defer { isAddingExtraExercise = false }

        do {
            guard let url = URL(string: Constants.baseURL + "ai/replaceExercise") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.applyBearerToken()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "day": workout.day,
                "muscleGroup": workout.muscle_group,
                "exerciseName": sourceExercise.name,
                "exerciseIndex": sourceIndex
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard (200..<300).contains(http.statusCode) else {
                let reason = (try? JSONDecoder().decode([String: String].self, from: data))?["reason"]
                    ?? "Server returned status \(http.statusCode)."
                presentReplaceExerciseError(reason)
                return
            }

            let updatedWorkout = try JSONDecoder().decode(workout_plans.self, from: data)
            guard updatedWorkout.exercises.indices.contains(sourceIndex) else {
                presentReplaceExerciseError("The server did not return the extra exercise.")
                return
            }

            var extraExercise = updatedWorkout.exercises[sourceIndex]
            extraExercise.loggedSets = []
            workout.exercises.append(extraExercise)
            activeWorkout = workout
            workoutCaloriesOverride = workout.exercises.reduce(0) { $0 + $1.calories_burned }
            index = workout.exercises.count - 1
            excSer = extraExercise.sets
            set = 1
            totalTime = 5
            timeRemaining = 0
            finishedSet = false
            finishedRecover = false
            startTime = nil
            isTrackingTime = false
        } catch {
            presentReplaceExerciseError(error.localizedDescription)
        }
    }

    private func presentSetLogError(_ message: String) {
        setLogError = message
        showSetLogError = true
    }

    private func responseBodyDescription(from data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let reason = object["reason"] as? String {
                return reason
            }
            if let error = object["error"] as? String {
                return error
            }
            if let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                return prettyString
            }
        }

        let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "No response body" : text
    }

    private func replaceCurrentExercise() async {
        guard routineDay == nil else { return }
        guard let workout = currentWorkout, let exercise = currentExercise else {
            presentReplaceExerciseError("Missing current exercise.")
            return
        }

        isReplacingExercise = true
        defer { isReplacingExercise = false }

        do {
            guard let url = URL(string: Constants.baseURL + "ai/replaceExercise") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.applyBearerToken()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "day": workout.day,
                "muscleGroup": workout.muscle_group,
                "exerciseName": exercise.name,
                "exerciseIndex": index
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard (200..<300).contains(http.statusCode) else {
                let reason = (try? JSONDecoder().decode([String: String].self, from: data))?["reason"]
                    ?? "Server returned status \(http.statusCode)."
                presentReplaceExerciseError(reason)
                return
            }

            let updatedWorkout = try JSONDecoder().decode(workout_plans.self, from: data)
            guard updatedWorkout.exercises.indices.contains(index) else {
                presentReplaceExerciseError("The replacement did not include the current exercise.")
                return
            }

            activeWorkout = updatedWorkout
            workoutCaloriesOverride = updatedWorkout.exercises.reduce(0) { $0 + $1.calories_burned }
            excSer = updatedWorkout.exercises[index].sets
            set = 1
            finishedSet = false
            finishedRecover = false
            startTime = nil
            isTrackingTime = false
        } catch {
            presentReplaceExerciseError(error.localizedDescription)
        }
    }

    private func presentReplaceExerciseError(_ message: String) {
        replaceExerciseError = message
        showReplaceExerciseError = true
    }

    @MainActor
    private func shareWorkoutCompletionIfNeeded() async {
        guard !didPostWorkoutCompletion else { return }
        didPostWorkoutCompletion = true
        guard let challengeID, let challengeDay = routineDay else { return }

        let group = (currentWorkout?.muscle_group ?? exToday).trimmingCharacters(in: .whitespacesAndNewlines)
        let duration = isHIITWorkout ? hiitElapsedSeconds : max(0, Int(Date().timeIntervalSince(workoutStartedAt)))
        let payload = WorkoutCompletionPayload(
            workoutType: socialWorkoutType,
            title: group.isEmpty ? "Workout" : group,
            muscleGroup: group.isEmpty ? nil : group,
            durationSeconds: duration,
            calories: displayedCalories,
            completedDate: FriendshipAPI.localDayFormatter.string(from: Date()),
            challengeID: challengeID,
            challengeDay: challengeDay
        )

        do {
            _ = try await FriendshipAPI.postWorkoutCompletion(payload)
        } catch {
            print("Could not share workout completion: \(error)")
        }
    }

    private var socialWorkoutType: String {
        if isHIITWorkout { return "hiit" }
        if challengeID != nil { return "challenge" }
        if isCustomWorkout { return "custom" }
        if routineDay != nil { return "routine" }
        return "training"
    }

    private var challengeSetLogPath: String? {
        guard let challengeID else { return nil }
        return "friends/challenges/\(challengeID.uuidString)/set-log"
    }

    private func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
        let format = AppLanguageManager.shared.localizedString(forKey: key)
        return String(format: format, locale: AppLanguageManager.shared.locale, arguments: arguments)
    }

    private func localizedExerciseDescription(english: String?, spanish: String?) -> String? {
        let prefersSpanish = languageManager.locale.languageCode?.lowercased().hasPrefix("es") == true
        let preferred = prefersSpanish ? spanish : english
        let fallback = prefersSpanish ? english : nil

        return [preferred, fallback]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct WorkoutPrimaryButtonStyle: ButtonStyle {
    var tint: Color = .green

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(Color.white)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.92), tint.opacity(0.68)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.34 : 0.2), lineWidth: 1)
            )
            .shadow(color: tint.opacity(configuration.isPressed ? 0.12 : 0.3), radius: 12, x: 0, y: 7)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct WorkoutSecondaryButtonStyle: ButtonStyle {
    var tint: Color = .orange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(Color.white)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(tint.opacity(configuration.isPressed ? 0.2 : 0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(0.38), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct WorkoutChipButtonStyle: ButtonStyle {
    var tint: Color = .orange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.heavy))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(configuration.isPressed ? 0.2 : 0.12), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.34), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
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

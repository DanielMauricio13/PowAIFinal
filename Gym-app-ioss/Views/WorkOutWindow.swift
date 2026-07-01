//
//  WorkOutWindow.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/30/24.
//
import SwiftUI

struct WorkOutWindow: View {
    var mainUser: User?
    var userFullWork: fullTraining?
    @Binding var exToday:String
    @State var todaysWork: workout_plans?
    @State var begginButton = false
    @State var cals = 0
    @State var temp = "\n\n"
    @State private var showAlternatePrompt = false
    @State private var isRequestingAlternate = false
    @State private var showAlternateError = false
    @State private var alternateErrorMessage = ""
    @State private var showingSharePicker = false
    @State private var showingFriendRoutinePicker = false
    var isHIITWorkout = false

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: AdaptiveLayout.isCompactPhone ? 136 : 150), spacing: 12)
        ]
    }

    private var titleSize: CGFloat { AdaptiveLayout.scaled(35, compact: 27) }
    private var muscleGroupTitle: String {
        localizedFormat("Today is %@", localizedWorkoutText(todaysWork?.muscle_group ?? "Failed to pull"))
    }

    private var alternatePromptMessage: String {
        localizedFormat(
            "Ask Gemini for a different routine for %@.",
            localizedWorkoutText(todaysWork?.muscle_group ?? "this muscle group")
        )
    }

    var body: some View {
        ZStack{

          
            if begginButton {
                StaringWorkWindow(todaysWork: todaysWork, exToday: $exToday, cals: cals, isHIITWorkout: isHIITWorkout)
            }else{
                
                VStack(spacing: AdaptiveLayout.scaled(8, compact: 6)) {
                    
                    HStack(alignment: .center) {
                        Text(muscleGroupTitle)
                            .font(.system(size: titleSize, weight: .bold,design: .rounded))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                        Spacer()
                        Button {
                            showAlternatePrompt = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(Color.accentColor)
                                .padding(.trailing, 8)
                        }
                        .disabled(isRequestingAlternate || todaysWork?.exercises.isEmpty != false)

                        Menu {
                            Button {
                                showingSharePicker = true
                            } label: {
                                Label(
                                    AppLanguageManager.shared.localizedString(forKey: "Share today’s routine"),
                                    systemImage: "paperplane.fill"
                                )
                            }

                            Button {
                                showingFriendRoutinePicker = true
                            } label: {
                                Label(
                                    AppLanguageManager.shared.localizedString(forKey: "Use friend’s routine"),
                                    systemImage: "person.2.fill"
                                )
                            }
                        } label: {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .resizable()
                                .frame(width: 34, height: 34)
                                .foregroundStyle(Color.accentColor)
                        }
                        .disabled(todaysWork == nil)
                    }
                        
                    
                    
                    HStack(alignment:.bottom ) {
                        Text("Your exercises today are:").font(.title2).fontDesign(.rounded).bold().foregroundStyle(LinearGradient(colors: [Color.red.opacity(0.7),Color.purple.opacity(0.7), Color.white.opacity(0.7)],startPoint: .topLeading,endPoint: .bottomTrailing))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .padding(.top, 12)
                        Spacer(minLength: 12)
                    }
                    ScrollView {
                                if let exercises = todaysWork?.exercises {
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(exercises.indices, id: \.self) { i in
                                            let exercise = exercises[i]
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(localizedWorkoutText(exercise.name))
                                                    .font(.headline)
                                                Text(localizedFormat("%@ reps x %d sets", exercise.reps, exercise.sets))
                                                    .font(.subheadline)
                                                Text(localizedFormat("~ %d cal", exercise.calories_burned))
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        }
                                    }
                                    .padding()
                                } else {
                                    Text("No exercises available.")
                                        .padding()
                                }
                            }
                    Text(localizedFormat("Burn approx %d calories 🔥 in this workout!", cals))
                        .font(.title3)
                        .bold()
                        .foregroundStyle(Color.orange)
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal)
                    Spacer(minLength: AdaptiveLayout.scaled(40, compact: 16))
                    HStack(spacing: 14) {
                        Button{
                            exToday = ""
                        }label: {
                            Text("Go Back")
                                .bold()
                                .font(.title3)
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.gray.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        Button{
                            begginButton = true
                        }label: {
                            Text("Begin")
                                .bold()
                                .font(.title3)
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20)
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, AdaptiveLayout.isCompactPhone ? 10 : 16)
            }
        }
        .onAppear{
            if exToday != "failed",
               let plans = userFullWork?.userExcersises.workout_plan {
                todaysWork = plans.first(where: { $0.muscle_group == exToday })
            }
            recalculateSummary()
          
        }
        .alert("Change today’s workout?", isPresented: $showAlternatePrompt) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, create new") {
                Task { await requestAlternateWorkout() }
            }
        } message: {
            Text(alternatePromptMessage)
        }
        .alert("Couldn’t update workout", isPresented: $showAlternateError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alternateErrorMessage)
        }
        .sheet(isPresented: $showingSharePicker) {
            if let day = todaysWork?.day {
                FriendSharePickerView(
                    title: AppLanguageManager.shared.localizedString(forKey: "Share today’s routine"),
                    target: .workoutDay(day)
                )
            }
        }
        .sheet(isPresented: $showingFriendRoutinePicker) {
            FriendWorkoutShareSheet(targetDay: todaysWork?.day ?? 1) { updatedPlan in
                todaysWork = updatedPlan
                exToday = updatedPlan.muscle_group
                recalculateSummary()
                showingFriendRoutinePicker = false
            }
        }
    }
    
    func recalculateSummary() {
        cals = 0
        temp = "\n\n"
        guard let exercises = todaysWork?.exercises else { return }
        for exercise in exercises {
            cals += exercise.calories_burned
            temp += " - \(exercise.name): \(exercise.reps) reps, x \(exercise.sets) sets. Approx \(exercise.calories_burned) calories burned\n\n"
        }
    }
    
    func requestAlternateWorkout() async {
        guard let todaysWork else {
            alternateErrorMessage = localizedText("Missing today's workout details.")
            showAlternateError = true
            return
        }
        guard !todaysWork.exercises.isEmpty else {
            alternateErrorMessage = localizedText("There are no exercises to base a new routine on.")
            showAlternateError = true
            return
        }

        isRequestingAlternate = true
        defer { isRequestingAlternate = false }

        do {
            let urlString = Constants.baseURL + "/ai/alternateWorkout"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Build existing exercises list for backend
            let existingExercises = todaysWork.exercises.map { ex -> [String: Any] in
                ["name": ex.name, "reps": ex.reps,
                 "sets": ex.sets, "calories_burned": ex.calories_burned,
                 "descriptionEng": ex.descriptionEng ?? "",
                 "descriptionEsp": ex.descriptionEsp ?? ""]
            }

            let body: [String: Any] = [
                "day":               todaysWork.day,
                "muscleGroup":       todaysWork.muscle_group,
                "numHours":          WorkoutSessionDuration.normalizedHours(from: mainUser?.numHours),
                "existingExercises": existingExercises
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(workout_plans.self, from: data)

            await MainActor.run {
                self.todaysWork = decoded
                recalculateSummary()
            }
        } catch {
            alternateErrorMessage = localizedFormat("Error: %@", error.localizedDescription)
            showAlternateError = true
        }
    }

    private func localizedText(_ key: String) -> String {
        AppLanguageManager.shared.localizedString(forKey: key)
    }

    private func localizedWorkoutText(_ key: String) -> String {
        AppLanguageManager.shared.localizedString(forKey: key)
    }

    private func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
        let format = AppLanguageManager.shared.localizedString(forKey: key)
        return String(format: format, locale: AppLanguageManager.shared.locale, arguments: arguments)
    }
}

private struct FriendWorkoutShareSheet: View {
    let targetDay: Int
    let onUse: (workout_plans) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var shares: [SharedFriendItemDTO] = []
    @State private var isLoading = false
    @State private var message: String?

    private var workoutShares: [SharedFriendItemDTO] {
        shares.filter { $0.status == "pending" && $0.type == "workout_day" }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView()

                Group {
                    if isLoading && shares.isEmpty {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else if workoutShares.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 42, weight: .light))
                                .foregroundStyle(.secondary)
                            Text(AppLanguageManager.shared.localizedString(forKey: "No friend routines waiting."))
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Text(AppLanguageManager.shared.localizedString(forKey: "Ask a friend to share today’s routine with you."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(workoutShares, id: \.stableID) { share in
                                Button {
                                    Task { await use(share) }
                                } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(share.title)
                                            .font(.headline.weight(.bold))
                                        Text(share.sender.displayName)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text(AppLanguageManager.shared.localizedString(forKey: "Tap to use this as today’s routine."))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color.accentColor)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(AppLanguageManager.shared.localizedString(forKey: "Use friend’s routine"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(AppLanguageManager.shared.localizedString(forKey: "Close")) {
                        dismiss()
                    }
                }
            }
            .task { await load() }
            .alert(AppLanguageManager.shared.localizedString(forKey: "Friends"), isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button(AppLanguageManager.shared.localizedString(forKey: "OK"), role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            shares = try await FriendshipAPI.fetchShares()
        } catch {
            message = AppLanguageManager.shared.localizedString(forKey: "Could not load shared routines.")
        }
    }

    @MainActor
    private func use(_ share: SharedFriendItemDTO) async {
        guard let shareID = share.id else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await FriendshipAPI.acceptShare(id: shareID, targetDay: targetDay)
            let training = try await fetchUpdatedTraining()
            guard let plan = training.userExcersises.workout_plan.first(where: { $0.day == targetDay }) else {
                message = AppLanguageManager.shared.localizedString(forKey: "Friend routine was added, but could not be opened.")
                return
            }
            onUse(plan)
        } catch {
            message = AppLanguageManager.shared.localizedString(forKey: "Could not use friend’s routine.")
        }
    }

    private func fetchUpdatedTraining() async throws -> fullTraining {
        guard let url = URL(string: Constants.baseURL + "training/userExcersises") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.applyBearerToken()
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(fullTraining.self, from: data)
    }
}


struct WorkOutWindow_Previews: PreviewProvider {
    static var previews: some View {
        WorkOutWindow(exToday: .constant("Preview Workout"))
    }
}

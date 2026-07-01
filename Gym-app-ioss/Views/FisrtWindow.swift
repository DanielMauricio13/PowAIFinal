//
//  FisrtWindow.swift
//  Gym-app-ioss
//

import SwiftUI
import UIKit

struct FisrtWindow: View {
    var mainUser: User?
    var userFullWork: fullTraining?
    @StateObject var viewModel: ListViewModel
    @StateObject var viewModel2: ListViewModel
    @State var expandedIndexes = Set<Int>()
    @State var temp = ""
    @Binding var exToday: String

    // ── HIIT state ────────────────────────────────────────────────────────────
    @Binding var hiitWork: fullTraining?
    @State private var isLoadingHIIT = false
    @State private var hiitError: String? = nil
    @State private var showHIITError = false
    @State private var showRoutineWindow = false
    @State private var showMakeYourOwnWindow = false
    @State private var showSavedCustomWorkouts = false
    @State private var savedCustomWorkouts: [SavedCustomWorkout] = []
    @State private var selectedSavedCustomSession: MakeYourOwnWorkoutSession?
    @State private var savedCustomWorkoutMessage: String?
    @State private var showSavedCustomWorkoutMessage = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack {
                Text("Happy \(currentDayOfWeek())!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                    .foregroundStyle(LinearGradient(
                        colors: [.white, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .italic()
                    .shadow(color: .red.opacity(0.6), radius: 12)

                Text("Choose today's workout!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                    .fontDesign(.rounded)
                    .foregroundColor(.white.opacity(0.95))

                ScrollView {
                    VStack {
                        Spacer()

                        // ── Regular workout days ──────────────────────────────
                        ForEach(viewModel.items) { item in
                            ExpandableBoxView(item: item, exToday: $exToday)
                                .onTapGesture { viewModel.toggleExpand(for: item) }
                                .animation(.easeInOut, value: item.isExpanded)
                        }

                        Button {
                            showRoutineWindow = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.22))
                                        .frame(width: 48, height: 48)

                                    Image(systemName: "calendar.badge.clock")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Routine")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)

                                    Text("Open your 30-day training plan")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundColor(.orange.opacity(0.9))
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                            )
                            .cornerRadius(12)
                            .shadow(color: .orange.opacity(0.12), radius: 8)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                        Button {
                            showMakeYourOwnWindow = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.22))
                                        .frame(width: 48, height: 48)

                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Make Your Own")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)

                                    Text("Build a custom workout from all exercises")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundColor(.orange.opacity(0.9))
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                            )
                            .cornerRadius(12)
                            .shadow(color: .orange.opacity(0.12), radius: 8)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                        savedCustomWorkoutsSection

                        // ── HIIT section ──────────────────────────────────────
                        Text("Short On Time? Do a HIIT!")
                            .font(.title3)
                            .fontWeight(.heavy)
                            .padding()
                            .foregroundStyle(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .italic()
                            .shadow(color: .red, radius: 20, y: 1)
                            .underline()

                        if isLoadingHIIT {
                            // Loading state while backend generates HIIT
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(
                                        CircularProgressViewStyle(tint: .orange)
                                    )
                                    .scaleEffect(1.5)
                                Text("Generating your HIIT workout...")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.subheadline)
                                    .fontDesign(.rounded)
                            }
                            .padding(30)
                        } else if let hiit = hiitWork {
                            // Show generated HIIT days
                            ForEach(hiit.userExcersises.workout_plan, id: \.day) { day in
                                HIITDayView(day: day, exToday: $exToday)
                                    .padding(.vertical, 4)
                            }
                        } else {
                            // Show level selection buttons
                            HStack(spacing: 16) {
                                ForEach(["Beginner", "Medium", "Expert"], id: \.self) { level in
                                    Button {
                                        Task { await requestHIIT(level: level) }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: hiitIcon(for: level))
                                                .font(.title2)
                                            Text(level)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .fontDesign(.rounded)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(hiitColor(for: level).opacity(0.25))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(hiitColor(for: level).opacity(0.6), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)

                            Text("Tap a level to generate your HIIT")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 4)
                        }

                        // Regenerate button if HIIT already loaded
                        if hiitWork != nil && !isLoadingHIIT {
                            Button {
                                hiitWork = nil
                            } label: {
                                Label("Generate Different HIIT", systemImage: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundColor(.orange.opacity(0.8))
                            }
                            .padding(.top, 6)
                        }

                        Spacer(minLength: 30)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            refreshSavedCustomWorkouts()
            guard viewModel.items.isEmpty else { return }
            buildRegularWorkout()
        }
        .onChange(of: showMakeYourOwnWindow) { _, isPresented in
            if !isPresented {
                refreshSavedCustomWorkouts()
            }
        }
        .alert("HIIT Error", isPresented: $showHIITError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(hiitError ?? "Something went wrong generating your HIIT workout.")
        }
        .alert("Saved Workouts", isPresented: $showSavedCustomWorkoutMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(savedCustomWorkoutMessage ?? "")
        }
        .sheet(isPresented: $showRoutineWindow) {
            RoutineView(mainUser: mainUser) {
                showRoutineWindow = false
            }
        }
        .sheet(isPresented: $showMakeYourOwnWindow) {
            MakeYourOwnWorkoutView(
                savedWorkoutCount: savedCustomWorkouts.count,
                onReturnHome: {
                    showMakeYourOwnWindow = false
                },
                onSaved: {
                    refreshSavedCustomWorkouts()
                    showSavedCustomWorkouts = true
                }
            )
        }
        .fullScreenCover(item: $selectedSavedCustomSession) { session in
            MakeYourOwnWorkoutSessionView(session: session) {
                selectedSavedCustomSession = nil
            }
        }
    }

    @ViewBuilder
    private var savedCustomWorkoutsSection: some View {
        if !savedCustomWorkouts.isEmpty {
            VStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut) {
                        showSavedCustomWorkouts.toggle()
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 48, height: 48)

                            Image(systemName: "bookmark.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Saved Own Workouts")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("\(savedCustomWorkouts.count) saved - show and start later")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()

                        Image(systemName: showSavedCustomWorkouts ? "chevron.up" : "chevron.down")
                            .font(.headline)
                            .foregroundColor(.green.opacity(0.9))
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.35), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.1), radius: 8)
                }
                .buttonStyle(.plain)

                if showSavedCustomWorkouts {
                    ForEach(savedCustomWorkouts) { savedWorkout in
                        savedCustomWorkoutRow(savedWorkout)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }

    private func savedCustomWorkoutRow(_ savedWorkout: SavedCustomWorkout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "dumbbell.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .frame(width: 34, height: 34)
                    .background(Color.orange.opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(savedWorkout.name)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text("\(savedWorkout.exerciseCount) exercises - ~\(savedWorkout.totalCalories) cal")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                Button(role: .destructive) {
                    Task { await deleteSavedCustomWorkout(savedWorkout) }
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.red.opacity(0.9))
                        .frame(width: 34, height: 34)
                        .background(Color.red.opacity(0.13))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Button {
                selectedSavedCustomSession = MakeYourOwnWorkoutSession(
                    plan: savedWorkout.plan,
                    totalCalories: savedWorkout.totalCalories
                )
            } label: {
                Label("Start Saved Workout", systemImage: "play.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.green.opacity(0.85))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.black.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    private func refreshSavedCustomWorkouts() {
        savedCustomWorkouts = MakeYourOwnRoutineStore.loadLocal()
        if savedCustomWorkouts.isEmpty {
            showSavedCustomWorkouts = false
        }

        Task {
            do {
                let serverWorkouts = try await MakeYourOwnRoutineStore.fetchFromBackend()
                savedCustomWorkouts = serverWorkouts
                if savedCustomWorkouts.isEmpty {
                    showSavedCustomWorkouts = false
                }
            } catch {
                savedCustomWorkoutMessage = "Could not refresh saved workouts from the database."
                showSavedCustomWorkoutMessage = true
            }
        }
    }

    private func deleteSavedCustomWorkout(_ savedWorkout: SavedCustomWorkout) async {
        do {
            try await MakeYourOwnRoutineStore.deleteFromBackend(id: savedWorkout.id)
            savedCustomWorkouts = MakeYourOwnRoutineStore.loadLocal()
            if savedCustomWorkouts.isEmpty {
                showSavedCustomWorkouts = false
            }
        } catch {
            savedCustomWorkoutMessage = "Could not delete this saved workout from the database."
            showSavedCustomWorkoutMessage = true
        }
    }

    // ── Build regular workout list from userFullWork ───────────────────────────
    private func buildRegularWorkout() {
        guard let plan = userFullWork?.userExcersises.workout_plan else { return }
        for day in plan {
            var desc = ""
            var cal = 0
            for ex in day.exercises {
                desc += "\n\(ex.name): \(ex.sets) sets, \(ex.reps) reps"
                cal += ex.calories_burned
            }
            viewModel.items.append(ExcListItem(
                title: day.muscle_group,
                description: desc,
                totalCalories: cal,
                duration: 20,
                NumExcersises: day.exercises.count
            ))
        }
    }

    func requestHIIT(level: String) async {
        guard let user = mainUser else { return }

        await MainActor.run { isLoadingHIIT = true }
        defer { Task { @MainActor in isLoadingHIIT = false } }

        do {
            let urlString = Constants.baseURL + "/ai/requestHIIT"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // No ?? needed — User fields are non-optional Int/String
            let body: [String: Any] = [
                "age":           user.age ?? "20",
                "gender":        user.gender ?? "Male",
                "weight":        user.weight ?? 70,
                "weightUnit":    "kg",
                "height":        user.height ?? 150,
                "heightUnit":    "cm",
                "bodyStructure": user.bodyStructure ?? "Endomorph",
                "goal":          user.goal ?? "stay fit",
                "whereWork":     "gym",
                "level":         level.lowercased(),
                "numDays":       user.numDays ?? 4,
                "numHours":      WorkoutSessionDuration.normalizedHours(from: user.numHours)
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 60
            let session = URLSession(configuration: config)

            let (data, _) = try await session.data(for: request)

            // Decode using iOS-side WorkoutDTO
            let workoutDTO = try JSONDecoder().decode(WorkoutDTO.self, from: data)

            // Convert WorkoutDTO → userExcersise using the plain init
            var excersise = userExcersise()   // uses the init() { workout_plan = [] } you added
            excersise.workout_plan = workoutDTO.workout_plan.map { day in
                workout_plans(
                    day: day.day,
                    muscle_group: day.muscle_group,
                    exercises: day.exercises.map { ex in
                        Excersise(
                            name: ex.name,
                            reps: ex.reps,
                            sets: ex.sets,
                            calories_burned: ex.calories_burned,
                            descriptionEng: ex.descriptionEng,
                            descriptionEsp: ex.descriptionEsp,
                            loggedSets: ex.loggedSets ?? []
                        )
                    }
                )
            }

            let hiit = fullTraining(
                id:              nil,             // ← ADD this
                email:           user.email ?? "test" ,
                userExcersises:  excersise
            )

            await MainActor.run { hiitWork = hiit }

        } catch {
            await MainActor.run {
                hiitError = error.localizedDescription
                showHIITError = true
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    func currentDayOfWeek() -> String {
        let weekdays = ["Sunday","Monday","Tuesday","Wednesday",
                        "Thursday","Friday","Saturday"]
        let day = Calendar.current.component(.weekday, from: Date())
        return weekdays[day - 1]
    }

    private func hiitIcon(for level: String) -> String {
        switch level {
        case "Beginner": return "flame"
        case "Medium":   return "bolt.fill"
        case "Expert":   return "bolt.circle.fill"
        default:         return "flame"
        }
    }

    private func hiitColor(for level: String) -> Color {
        switch level {
        case "Beginner": return .green
        case "Medium":   return .orange
        case "Expert":   return .red
        default:         return .orange
        }
    }

    // ── Regular workout expandable row ────────────────────────────────────────
    struct ExpandableBoxView: View {
        var item: ExcListItem
        @Binding var exToday: String

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if item.isExpanded {
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.78))
                        .padding(.top, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    HStack {
                        Spacer()
                        Button { exToday = item.title } label: {
                            Text("Start")
                                .font(.title2)
                                .frame(maxWidth: AdaptiveLayout.clampedWidth(180, horizontalPadding: 96), minHeight: 44)
                                .padding(8)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                    Spacer()
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.3), radius: 6)
            .padding(.vertical, 5)
        }
    }

    // ── HIIT day row ──────────────────────────────────────────────────────────
    struct HIITDayView: View {
        var day: workout_plans
        @Binding var exToday: String
        @State private var expanded = false

        var totalCal: Int { day.exercises.reduce(0) { $0 + $1.calories_burned } }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Button { withAnimation { expanded.toggle() } } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Day \(day.day) — \(day.muscle_group)")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("\(day.exercises.count) exercises · ~\(totalCal) cal")
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.orange)
                    }
                    .padding()
                }

                if expanded {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(day.exercises, id: \.name) { ex in
                            HStack(alignment: .top, spacing: 8) {
                                Text("• \(ex.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(2)
                                Spacer()
                                Text("\(ex.reps) × \(ex.sets)  ~\(ex.calories_burned)cal")
                                    .font(.caption)
                                    .foregroundColor(.orange.opacity(0.7))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    HStack {
                        Spacer()
                        Button { exToday = day.muscle_group } label: {
                            Text("Start")
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: AdaptiveLayout.clampedWidth(180, horizontalPadding: 96), minHeight: 44)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 12)
                }
            }
            .background(Color.orange.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(10)
            .shadow(color: .orange.opacity(0.1), radius: 6)
        }
    }
}

private struct AllExerciseCatalogItem: Codable {
    let id: UUID?
    let exerciseName: String
    let muscleCategory: String
    let muscle: String
    let expectedCaloriesBurned: Int
    let descriptionEnglish: String
    let descriptionSpanish: String

    var stableID: String {
        id?.uuidString ?? "\(selectionKey)-\(muscleCategory)"
    }

    var selectionKey: String {
        exerciseName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    var workoutExercise: Excersise {
        Excersise(
            name: exerciseName,
            reps: "10-12",
            sets: 3,
            calories_burned: expectedCaloriesBurned,
            descriptionEng: descriptionEnglish,
            descriptionEsp: descriptionSpanish
        )
    }
}

private struct MakeYourOwnWorkoutSession: Identifiable {
    let id = UUID()
    let plan: workout_plans
    let totalCalories: Int
}

private struct SavedCustomWorkout: Identifiable, Codable {
    let id: UUID
    var name: String
    var plan: workout_plans
    var createdAt: Date

    var exerciseCount: Int {
        plan.exercises.count
    }

    var totalCalories: Int {
        plan.exercises.reduce(0) { $0 + $1.calories_burned }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case plan
        case createdAt
        case createdAtSnake = "created_at"
    }

    init(id: UUID, name: String, plan: workout_plans, createdAt: Date) {
        self.id = id
        self.name = name
        self.plan = plan
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        plan = try container.decode(workout_plans.self, forKey: .plan)

        if let decodedDate = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = decodedDate
        } else if let decodedDate = try? container.decode(Date.self, forKey: .createdAtSnake) {
            createdAt = decodedDate
        } else if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = Self.parseDate(dateString) ?? Date()
        } else if let dateString = try? container.decode(String.self, forKey: .createdAtSnake) {
            createdAt = Self.parseDate(dateString) ?? Date()
        } else {
            createdAt = Date()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(plan, forKey: .plan)
        try container.encode(createdAt, forKey: .createdAt)
    }

    private static func parseDate(_ value: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

private enum MakeYourOwnRoutineStore {
    static let primaryKey = "all_muscle_custom_routine"
    static let legacyTypoKey = "all_mucle_routine"
    static let maxSavedWorkouts = 5
    private static let savedListKey = "saved_make_your_own_workouts"
    private static let migrationKey = "saved_make_your_own_workouts_migrated"

    static func saveToBackend(_ plan: workout_plans, named rawName: String) async throws -> SavedCustomWorkout {
        let existing = try await fetchFromBackend()
        guard existing.count < maxSavedWorkouts else {
            throw SavedCustomWorkoutStoreError.limitReached
        }

        let fallbackNumber = min(existing.count + 1, maxSavedWorkouts)
        let requestBody = SavedCustomWorkoutCreateRequest(
            name: normalizedName(rawName, fallbackNumber: fallbackNumber),
            plan: plan
        )
        guard let url = URL(string: Constants.baseURL + "training/custom-workouts") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, timeoutInterval: 45)
        request.httpMethod = HttpMethods.POST.rawValue
        request.setValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HttpHeaders.contentType.rawValue)
        request.applyBearerToken()
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if http.statusCode == 409 {
            throw SavedCustomWorkoutStoreError.limitReached
        }

        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let savedWorkout = try JSONDecoder().decode(SavedCustomWorkout.self, from: data)
        persist([savedWorkout] + existing.filter { $0.id != savedWorkout.id })
        saveLegacyPlan(plan)
        return savedWorkout
    }

    static func fetchFromBackend() async throws -> [SavedCustomWorkout] {
        guard let url = URL(string: Constants.baseURL + "training/custom-workouts") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, timeoutInterval: 45)
        request.httpMethod = HttpMethods.GET.rawValue
        request.applyBearerToken()

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let savedWorkouts = try JSONDecoder().decode([SavedCustomWorkout].self, from: data)
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(maxSavedWorkouts)
        let limitedWorkouts = Array(savedWorkouts)
        persist(limitedWorkouts)
        return limitedWorkouts
    }

    static func deleteFromBackend(id: UUID) async throws {
        guard let url = URL(string: Constants.baseURL + "training/custom-workouts/\(id.uuidString)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, timeoutInterval: 45)
        request.httpMethod = HttpMethods.DELETE.rawValue
        request.applyBearerToken()

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        persist(loadLocal().filter { $0.id != id })
    }

    static func loadLocal() -> [SavedCustomWorkout] {
        if let data = UserDefaults.standard.data(forKey: savedListKey),
           let savedWorkouts = try? JSONDecoder().decode([SavedCustomWorkout].self, from: data) {
            return Array(savedWorkouts.sorted { $0.createdAt > $1.createdAt }.prefix(maxSavedWorkouts))
        }

        guard !UserDefaults.standard.bool(forKey: migrationKey),
              let legacyPlan = loadLegacyPlan() else {
            return []
        }

        let migratedWorkout = SavedCustomWorkout(
            id: UUID(),
            name: "Saved Custom Workout",
            plan: legacyPlan,
            createdAt: Date()
        )
        persist([migratedWorkout])
        UserDefaults.standard.set(true, forKey: migrationKey)
        return [migratedWorkout]
    }

    private static func persist(_ savedWorkouts: [SavedCustomWorkout]) {
        let limitedWorkouts = Array(savedWorkouts.sorted { $0.createdAt > $1.createdAt }.prefix(maxSavedWorkouts))
        guard let data = try? JSONEncoder().encode(limitedWorkouts) else { return }
        UserDefaults.standard.set(data, forKey: savedListKey)
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    private static func saveLegacyPlan(_ plan: workout_plans) {
        guard let data = try? JSONEncoder().encode(plan) else { return }
        UserDefaults.standard.set(data, forKey: primaryKey)
        UserDefaults.standard.set(data, forKey: legacyTypoKey)
    }

    private static func loadLegacyPlan() -> workout_plans? {
        let defaults = UserDefaults.standard
        let data = defaults.data(forKey: primaryKey) ?? defaults.data(forKey: legacyTypoKey)
        guard let data else { return nil }
        return try? JSONDecoder().decode(workout_plans.self, from: data)
    }

    private static func normalizedName(_ name: String, fallbackNumber: Int) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Custom Workout \(fallbackNumber)" : trimmedName
    }
}

private struct SavedCustomWorkoutCreateRequest: Encodable {
    let name: String
    let plan: workout_plans
}

private enum SavedCustomWorkoutStoreError: LocalizedError {
    case limitReached

    var errorDescription: String? {
        switch self {
        case .limitReached:
            return "You can save up to 5 make your own workouts. Remove one before saving another."
        }
    }
}

@MainActor
private final class MakeYourOwnExerciseViewModel: ObservableObject {
    static let categories = [
        "Arms",
        "Back",
        "Calves",
        "Chest",
        "Core",
        "Forearms and Grip",
        "Full Body",
        "Glutes",
        "Legs",
        "Lower Body",
        "Lower Legs",
        "Neck and Traps",
        "Posterior Chain",
        "Shoulders"
    ]

    @Published var selectedCategory = "Arms"
    @Published var exercises: [AllExerciseCatalogItem] = []
    @Published var selectedExercises: [AllExerciseCatalogItem] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var message: String?
    @Published var saveMessage: String?
    @Published var isSavingWorkout = false
    @Published var startingSession: MakeYourOwnWorkoutSession?

    private var cachedExercises: [String: [AllExerciseCatalogItem]] = [:]
    private let decoder = JSONDecoder()

    var filteredExercises: [AllExerciseCatalogItem] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return exercises }

        return exercises.filter { exercise in
            exercise.exerciseName.localizedCaseInsensitiveContains(trimmedSearch)
                || exercise.muscle.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var totalCalories: Int {
        selectedExercises.reduce(0) { $0 + $1.expectedCaloriesBurned }
    }

    func loadExercises(for category: String? = nil) async {
        let categoryToLoad = category ?? selectedCategory
        selectedCategory = categoryToLoad

        if let cached = cachedExercises[categoryToLoad] {
            exercises = cached
            message = cached.isEmpty ? "No exercises found for \(categoryToLoad)." : nil
            return
        }

        isLoading = true
        message = nil
        defer { isLoading = false }

        do {
            var components = URLComponents(string: Constants.baseURL + "all-exercises/category")
            components?.queryItems = [
                URLQueryItem(name: "muscleCategory", value: categoryToLoad)
            ]

            guard let url = components?.url else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url, timeoutInterval: 45)
            request.httpMethod = HttpMethods.GET.rawValue
            request.applyBearerToken()

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                message = "Could not read the server response."
                return
            }

            switch http.statusCode {
            case 200..<300:
                let decoded = try decoder.decode([AllExerciseCatalogItem].self, from: data)
                cachedExercises[categoryToLoad] = decoded
                exercises = decoded
                message = decoded.isEmpty ? "No exercises found for \(categoryToLoad)." : nil
            case 401:
                exercises = []
                message = "Please sign in again to load exercises."
            default:
                exercises = []
                message = "Exercises failed to load. Status \(http.statusCode)."
            }
        } catch {
            exercises = []
            message = error.localizedDescription
        }
    }

    func toggleSelection(_ exercise: AllExerciseCatalogItem) {
        if let index = selectedExercises.firstIndex(where: { $0.selectionKey == exercise.selectionKey }) {
            selectedExercises.remove(at: index)
        } else {
            selectedExercises.append(exercise)
        }
    }

    func isSelected(_ exercise: AllExerciseCatalogItem) -> Bool {
        selectedExercises.contains { $0.selectionKey == exercise.selectionKey }
    }

    func removeSelectedExercise(_ exercise: AllExerciseCatalogItem) {
        selectedExercises.removeAll { $0.selectionKey == exercise.selectionKey }
    }

    func startWorkout() {
        guard let plan = selectedWorkoutPlan() else { return }

        startingSession = MakeYourOwnWorkoutSession(plan: plan, totalCalories: totalCalories)
    }

    @discardableResult
    func saveSelectedWorkout(named name: String) async -> SavedCustomWorkout? {
        guard let plan = selectedWorkoutPlan() else { return nil }

        isSavingWorkout = true
        defer { isSavingWorkout = false }

        do {
            let savedWorkout = try await MakeYourOwnRoutineStore.saveToBackend(plan, named: name)
            saveMessage = "\"\(savedWorkout.name)\" saved for later."
            return savedWorkout
        } catch {
            saveMessage = error.localizedDescription
            return nil
        }
    }

    private func selectedWorkoutPlan() -> workout_plans? {
        guard !selectedExercises.isEmpty else { return nil }

        return workout_plans(
            day: 1,
            muscle_group: "All Muscle",
            exercises: selectedExercises.map(\.workoutExercise)
        )
    }
}

private struct MakeYourOwnWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MakeYourOwnExerciseViewModel()
    let savedWorkoutCount: Int
    let onReturnHome: () -> Void
    let onSaved: () -> Void
    @State private var showSaveWorkoutPrompt = false
    @State private var saveWorkoutName = ""

    private var exerciseGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private var surfaceColor: Color {
        Color.white.opacity(0.075)
    }

    private var surfaceStroke: Color {
        Color.white.opacity(0.12)
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                header

                searchField

                categoryScroller

                exerciseList

                readyBar
            }
        }
        .task {
            await viewModel.loadExercises()
        }
        .onChange(of: viewModel.selectedCategory) { _, newCategory in
            Task { await viewModel.loadExercises(for: newCategory) }
        }
        .fullScreenCover(item: $viewModel.startingSession) { session in
            MakeYourOwnWorkoutSessionView(session: session) {
                viewModel.startingSession = nil
                dismiss()
                onReturnHome()
            }
        }
        .alert("Save Workout", isPresented: $showSaveWorkoutPrompt) {
            TextField("Workout name", text: $saveWorkoutName)
            Button("Save") {
                Task {
                    if await viewModel.saveSelectedWorkout(named: saveWorkoutName) != nil {
                        onSaved()
                    }
                    saveWorkoutName = ""
                }
            }
            Button("Cancel", role: .cancel) {
                saveWorkoutName = ""
            }
        } message: {
                Text("Name this custom workout so you can start it from the first screen later.")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Make Your Own")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Pick exercises across muscle groups")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.58))
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.88))
                        .frame(width: 38, height: 38)
                        .background(surfaceColor)
                        .overlay(
                            Circle()
                                .stroke(surfaceStroke, lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                workoutStatPill(
                    value: "\(viewModel.selectedExercises.count)",
                    label: "selected",
                    systemImage: "checkmark.circle.fill",
                    tint: .green
                )

                workoutStatPill(
                    value: "~\(viewModel.totalCalories)",
                    label: "cal",
                    systemImage: "flame.fill",
                    tint: .orange
                )

                workoutStatPill(
                    value: "\(min(savedWorkoutCount, MakeYourOwnRoutineStore.maxSavedWorkouts))/5",
                    label: "saved",
                    systemImage: "bookmark.fill",
                    tint: .cyan
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private func workoutStatPill(value: String, label: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundColor(tint)

            Text(value)
                .font(.subheadline)
                .fontWeight(.heavy)
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.58))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .padding(.horizontal, 8)
        .background(surfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(surfaceStroke, lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private var categoryScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MakeYourOwnExerciseViewModel.categories, id: \.self) { category in
                    let isSelected = viewModel.selectedCategory == category

                    Button {
                        viewModel.selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : .white.opacity(0.68))
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color.orange.opacity(0.86) : surfaceColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.orange.opacity(0.7) : surfaceStroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.orange)

            TextField("Search exercises or muscles", text: $viewModel.searchText)
                .textInputAutocapitalization(.words)
                .foregroundColor(.white)
                .font(.subheadline)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 44)
        .background(surfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(surfaceStroke, lineWidth: 1)
        )
        .cornerRadius(8)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    private var exerciseList: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 14) {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(1.4)
                    Text("Loading \(viewModel.selectedCategory)...")
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                }
            } else if let message = viewModel.message {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.86))
                        .padding(.horizontal, 24)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        selectedStrip

                        LazyVGrid(columns: exerciseGridColumns, spacing: 10) {
                            ForEach(viewModel.filteredExercises, id: \.stableID) { exercise in
                                exerciseCard(exercise)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var selectedStrip: some View {
        if !viewModel.selectedExercises.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.selectedExercises, id: \.stableID) { exercise in
                        Button {
                            viewModel.removeSelectedExercise(exercise)
                        } label: {
                            HStack(spacing: 6) {
                                Text(exercise.exerciseName)
                                    .lineLimit(1)
                                Image(systemName: "xmark")
                            }
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.green.opacity(0.38))
                            .overlay(
                                Capsule()
                                    .stroke(Color.green.opacity(0.45), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func exerciseCard(_ exercise: AllExerciseCatalogItem) -> some View {
        let isSelected = viewModel.isSelected(exercise)

        return Button {
            viewModel.toggleSelection(exercise)
        } label: {
            ZStack(alignment: .topTrailing) {
                CachedExerciseImageView(exerciseName: exercise.exerciseName)
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                .black.opacity(0.0),
                                .black.opacity(0.28),
                                .black.opacity(0.82)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Spacer()

                    Text(exercise.exerciseName)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(exercise.muscle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.orange.opacity(0.95))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    HStack(spacing: 6) {
                        Text("3 x 10-12")
                        Text("~\(exercise.expectedCaloriesBurned) cal")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(10)

                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.subheadline.weight(.heavy))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(isSelected ? Color.green.opacity(0.94) : Color.black.opacity(0.48))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .clipShape(Circle())
                    .padding(8)
            }
            .aspectRatio(1, contentMode: .fit)
            .background(surfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green.opacity(0.72) : surfaceStroke, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "Remove \(exercise.exerciseName)" : "Add \(exercise.exerciseName)")
    }

    private var readyBar: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.selectedExercises.count) exercises")
                    .font(.subheadline)
                    .fontWeight(.heavy)
                    .fontDesign(.rounded)
                    .foregroundColor(.white)

                Text(viewModel.saveMessage ?? "Save this workout for later or start now")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                saveForLaterButton

                Button {
                    viewModel.startWorkout()
                } label: {
                    Label("I'm ready!", systemImage: "play.fill")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(viewModel.selectedExercises.isEmpty ? Color.gray.opacity(0.55) : Color.orange)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.selectedExercises.isEmpty)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(Color.black.opacity(0.42))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }

    private var saveForLaterButton: some View {
        Button {
            if savedWorkoutCount >= MakeYourOwnRoutineStore.maxSavedWorkouts {
                viewModel.saveMessage = "You can save up to 5 make your own workouts. Remove one before saving another."
            } else {
                saveWorkoutName = defaultWorkoutName()
                showSaveWorkoutPrompt = true
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSavingWorkout {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: savedWorkoutCount >= MakeYourOwnRoutineStore.maxSavedWorkouts ? "bookmark.slash" : "bookmark.fill")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Save")
                        .font(.subheadline)
                        .fontWeight(.heavy)

                    Text("\(min(savedWorkoutCount, MakeYourOwnRoutineStore.maxSavedWorkouts))/5")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .opacity(0.78)
                }
            }
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(saveButtonBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(saveButtonStroke, lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedExercises.isEmpty || viewModel.isSavingWorkout || savedWorkoutCount >= MakeYourOwnRoutineStore.maxSavedWorkouts)
        .accessibilityLabel("Save workout for later")
    }

    private var saveButtonBackground: Color {
        if viewModel.selectedExercises.isEmpty || savedWorkoutCount >= MakeYourOwnRoutineStore.maxSavedWorkouts {
            return Color.gray.opacity(0.45)
        }

        return Color.green.opacity(0.24)
    }

    private var saveButtonStroke: Color {
        if viewModel.selectedExercises.isEmpty || savedWorkoutCount >= MakeYourOwnRoutineStore.maxSavedWorkouts {
            return Color.white.opacity(0.14)
        }

        return Color.green.opacity(0.55)
    }

    private func defaultWorkoutName() -> String {
        guard let firstExercise = viewModel.selectedExercises.first?.exerciseName else {
            return ""
        }

        if viewModel.selectedExercises.count == 1 {
            return firstExercise
        }

        return "\(firstExercise) + \(viewModel.selectedExercises.count - 1)"
    }
}

private struct MakeYourOwnWorkoutSessionView: View {
    let session: MakeYourOwnWorkoutSession
    let onClose: () -> Void
    @State private var exToday: String

    init(session: MakeYourOwnWorkoutSession, onClose: @escaping () -> Void) {
        self.session = session
        self.onClose = onClose
        self._exToday = State(initialValue: session.plan.muscle_group)
    }

    var body: some View {
        StaringWorkWindow(
            todaysWork: session.plan,
            exToday: $exToday,
            cals: session.totalCalories,
            isCustomWorkout: true,
            onRoutineHome: onClose
        )
        .onChange(of: exToday) {
            if exToday.isEmpty {
                onClose()
            }
        }
    }
}

private struct CachedExerciseImageView: View {
    let exerciseName: String
    @StateObject private var loader = CatalogExerciseImageLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.orange.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    if loader.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    } else {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white.opacity(0.68))
                    }
                }
            }
        }
        .task(id: exerciseName) {
            await loader.load(exerciseName: exerciseName)
        }
    }
}

@MainActor
private final class CatalogExerciseImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false

    func load(exerciseName: String) async {
        if let cachedImage = CatalogExerciseImageDiskCache.image(for: exerciseName) {
            image = cachedImage
            return
        }

        guard let url = CatalogExerciseImageDiskCache.remoteURL(for: exerciseName) else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard
                let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode),
                let fetchedImage = UIImage(data: data)
            else {
                return
            }

            CatalogExerciseImageDiskCache.save(data, for: exerciseName)
            image = fetchedImage
        } catch {
            image = nil
        }
    }
}

private enum CatalogExerciseImageDiskCache {
    private static let directoryName = "all_exercise_images"

    static func remoteURL(for exerciseName: String) -> URL? {
        var components = URLComponents(string: Constants.baseURL + "images/imageName")
        components?.queryItems = [
            URLQueryItem(name: "name", value: "\(exerciseName).jpg")
        ]
        return components?.url
    }

    static func image(for exerciseName: String) -> UIImage? {
        guard let url = fileURL(for: exerciseName) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func save(_ data: Data, for exerciseName: String) {
        guard let url = fileURL(for: exerciseName) else { return }

        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: [.atomic])
        } catch {
            return
        }
    }

    private static func fileURL(for exerciseName: String) -> URL? {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }

        return cachesDirectory
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(cacheFileName(for: exerciseName))
    }

    private static func cacheFileName(for exerciseName: String) -> String {
        let normalizedName = exerciseName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        let safeName = normalizedName.unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? String($0) : "_" }
            .joined()

        return "\(safeName).jpg"
    }
}

private struct RoutineUserResponse: Codable, Identifiable {
    let id: UUID?
    let email: String
    let routineTraining: RoutineTraining
}

private struct RoutineTraining: Codable {
    var workout_plan: [RoutineWorkoutDay]
}

private struct RoutineWorkoutDay: Codable, Identifiable {
    var id: Int { day }
    var day: Int
    var muscle_group: String
    var exercises: [RoutineExercise]

    var workoutPlan: workout_plans {
        workout_plans(
            day: day,
            muscle_group: muscle_group,
            exercises: exercises.map { exercise in
                Excersise(
                    name: exercise.name,
                    reps: exercise.reps,
                    sets: exercise.sets,
                    calories_burned: exercise.calories_burned,
                    descriptionEng: exercise.descriptionEng,
                    descriptionEsp: exercise.descriptionEsp,
                    loggedSets: exercise.loggedSets ?? []
                )
            }
        )
    }
}

private struct RoutineExercise: Codable, Identifiable {
    var id: String { "\(name)-\(sets)-\(reps)" }
    var name: String
    var reps: String
    var sets: Int
    var calories_burned: Int
    var descriptionEng: String? = nil
    var descriptionEsp: String? = nil
    var weight: Double
    var unit: String
    var loggedSets: [SetEntry]? = nil
}

@MainActor
private final class RoutineViewModel: ObservableObject {
    @Published var routine: RoutineUserResponse?
    @Published var isLoading = false
    @Published var isRequestingNewRoutine = false
    @Published var isRefreshingDescriptions = false
    @Published var message: String?

    private let decoder = JSONDecoder()

    var routineDays: [RoutineWorkoutDay] {
        routine?.routineTraining.workout_plan.sorted { $0.day < $1.day } ?? []
    }

    var hasRoutine: Bool {
        !routineDays.isEmpty
    }

    private var routineNeedsDescriptions: Bool {
        routineDays.contains { day in
            day.exercises.contains { exercise in
                isMissingDescription(exercise.descriptionEng)
                    || isMissingDescription(exercise.descriptionEsp)
            }
        }
    }

    func fetchRoutine() async {
        guard !isLoading else { return }

        isLoading = true
        message = nil
        defer { isLoading = false }

        do {
            let (data, response) = try await sendRoutineRequest(path: "routine", method: "GET")
            guard let http = response as? HTTPURLResponse else {
                message = "Could not read the server response."
                return
            }

            switch http.statusCode {
            case 200..<300:
                routine = try decoder.decode(RoutineUserResponse.self, from: data)
                if routineNeedsDescriptions {
                    Task { await refreshRoutineDescriptions() }
                }
            case 404:
                routine = nil
                message = "No routine has been saved yet."
            case 401:
                routine = nil
                message = "Please sign in again to load your routine."
            default:
                routine = nil
                message = "Routine failed to load. Status \(http.statusCode)."
            }
        } catch {
            routine = nil
            message = error.localizedDescription
        }
    }

    func requestNewRoutine(numHours: String? = nil) async {
        guard !isRequestingNewRoutine else { return }

        isRequestingNewRoutine = true
        message = nil
        defer { isRequestingNewRoutine = false }

        do {
            var payload: [String: Any] = [:]
            if let numHours {
                payload["numHours"] = WorkoutSessionDuration.normalizedHours(from: numHours)
            }
            let body = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await sendRoutineRequest(
                path: "routine/request-new",
                method: "POST",
                body: body,
                timeout: 120
            )
            guard let http = response as? HTTPURLResponse else {
                message = "Could not read the server response."
                return
            }

            if (200..<300).contains(http.statusCode) {
                routine = try decoder.decode(RoutineUserResponse.self, from: data)
                if routineNeedsDescriptions {
                    message = "Routine ready. Adding exercise descriptions..."
                    Task { await refreshRoutineDescriptions(showProgressMessage: true) }
                }
            } else if http.statusCode == 401 {
                message = "Please sign in again before requesting a routine."
            } else if http.statusCode == 503 {
                message = "Routine generation is busy. Please try again in a moment."
            } else {
                message = "Routine request failed. Status \(http.statusCode)."
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func refreshRoutineDescriptions(showProgressMessage: Bool = false) async {
        guard hasRoutine, routineNeedsDescriptions, !isRefreshingDescriptions else { return }

        isRefreshingDescriptions = true
        if showProgressMessage {
            message = "Routine ready. Adding exercise descriptions..."
        }
        defer { isRefreshingDescriptions = false }

        do {
            let (data, response) = try await sendRoutineRequest(
                path: "routine/descriptions",
                method: "POST",
                timeout: 120
            )
            guard let http = response as? HTTPURLResponse else {
                message = "Routine is ready. Exercise descriptions will be added later."
                return
            }

            if (200..<300).contains(http.statusCode) {
                routine = try decoder.decode(RoutineUserResponse.self, from: data)
                message = nil
            } else if http.statusCode == 404 {
                message = nil
            } else {
                message = "Routine is ready. Exercise descriptions will be added later."
            }
        } catch {
            message = "Routine is ready. Exercise descriptions will be added later."
        }
    }

    private func isMissingDescription(_ value: String?) -> Bool {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return true
        }

        return text.isEmpty || text == "0"
    }

    private func sendRoutineRequest(
        path: String,
        method: String,
        body: Data? = nil,
        timeout: TimeInterval = 60
    ) async throws -> (Data, URLResponse) {
        guard let url = URL(string: Constants.baseURL + path) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method
        request.applyBearerToken()

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: config)
        return try await session.data(for: request)
    }
}

private struct RoutineView: View {
    @Environment(\.dismiss) private var dismiss
    let mainUser: User?
    let onReturnHome: () -> Void
    @StateObject private var viewModel = RoutineViewModel()
    @State private var showRoutineDetails = false
    @AppStorage("routineCurrentDay") private var currentRoutineDay = 1

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasRoutine {
                    routineReadyView
                } else {
                    emptyView
                }
            }
        }
        .task {
            await viewModel.fetchRoutine()
        }
        .onChange(of: viewModel.routineDays.count) {
            clampCurrentRoutineDay()
        }
        .sheet(isPresented: $showRoutineDetails) {
            if let routine = viewModel.routine {
                RoutineDetailView(
                    routine: routine,
                    currentRoutineDay: $currentRoutineDay,
                    onReturnHome: {
                        showRoutineDetails = false
                        onReturnHome()
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("Routine")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [.white, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))

                Text("30-day training plan")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button {
                Task { await viewModel.fetchRoutine() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .frame(width: 38, height: 38)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading || viewModel.isRequestingNewRoutine)
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(1.6)

            Text("Loading your routine...")
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundColor(.white.opacity(0.85))

            Spacer()
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 58))
                .foregroundColor(.orange.opacity(0.9))

            Text(viewModel.message ?? "No routine found yet.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal)

            Button {
                Task { await requestNewRoutine() }
            } label: {
                HStack {
                    if viewModel.isRequestingNewRoutine {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "sparkles")
                    }

                    Text(viewModel.isRequestingNewRoutine ? "Creating Routine..." : "Create Routine")
                        .fontWeight(.bold)
                }
                .fontDesign(.rounded)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.orange)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRequestingNewRoutine)
            .padding(.horizontal, 34)

            Spacer()
        }
        .padding()
    }

    private var routineReadyView: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 58))
                .foregroundColor(.orange)

            VStack(spacing: 6) {
                Text("Routine Loaded")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Your 30-day plan is ready.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            routineProgressCard

            Button {
                clampCurrentRoutineDay()
                showRoutineDetails = true
            } label: {
                Label("Open Routine", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 34)

            Button {
                Task {
                    await requestNewRoutine()
                    clampCurrentRoutineDay()
                }
            } label: {
                Label(
                    viewModel.isRequestingNewRoutine ? "Creating New Routine..." : "Request New Routine",
                    systemImage: viewModel.isRequestingNewRoutine ? "hourglass" : "sparkles"
                )
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRequestingNewRoutine)
            .padding(.horizontal, 34)

            if let message = viewModel.message {
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 34)
            }

            Spacer()
        }
    }

    private var routineProgressCard: some View {
        let totalDays = max(viewModel.routineDays.count, 1)
        let clampedDay = min(max(currentRoutineDay, 1), totalDays)
        let progress = Double(clampedDay) / Double(totalDays)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Routine Day")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange.opacity(0.9))

                    Text("Day \(clampedDay) of \(totalDays)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.orange)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))

            HStack(spacing: 12) {
                Button {
                    currentRoutineDay = max(1, clampedDay - 1)
                } label: {
                    Image(systemName: "minus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .disabled(clampedDay <= 1)

                Button {
                    currentRoutineDay = min(totalDays, clampedDay + 1)
                } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .foregroundColor(.orange)
                .disabled(clampedDay >= totalDays)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.13), lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal, 34)
    }

    private func clampCurrentRoutineDay() {
        let totalDays = viewModel.routineDays.count
        guard totalDays > 0 else { return }
        currentRoutineDay = min(max(currentRoutineDay, 1), totalDays)
    }

    private func requestNewRoutine() async {
        await viewModel.requestNewRoutine(
            numHours: WorkoutSessionDuration.normalizedHours(from: mainUser?.numHours)
        )
    }
}

private struct RoutineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let routine: RoutineUserResponse
    @Binding var currentRoutineDay: Int
    let onReturnHome: () -> Void
    @State private var expandedDays: Set<Int> = []
    @State private var selectedWorkoutDay: RoutineWorkoutDay?
    @State private var sharingWorkoutDay: RoutineWorkoutDay?

    private var routineDays: [RoutineWorkoutDay] {
        routine.routineTraining.workout_plan.sorted { $0.day < $1.day }
    }

    private var totalDays: Int {
        max(routineDays.count, 1)
    }

    private var currentDay: Int {
        min(max(currentRoutineDay, 1), totalDays)
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                detailHeader

                ScrollView {
                    LazyVStack(spacing: 12) {
                        trackerCard

                        ForEach(routineDays) { day in
                            routineDayCard(day)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            clampCurrentRoutineDay()
            expandedDays.insert(currentDay)
        }
        .onChange(of: currentRoutineDay) {
            clampCurrentRoutineDay()
            expandedDays.insert(currentDay)
        }
        .sheet(item: $selectedWorkoutDay) { day in
            RoutineWorkoutWindow(
                day: day,
                totalRoutineDays: totalDays,
                currentRoutineDay: $currentRoutineDay,
                onReturnHome: onReturnHome
            )
        }
        .sheet(item: $sharingWorkoutDay) { day in
            FriendSharePickerView(
                title: AppLanguageManager.shared.localizedString(forKey: "Share Routine Day"),
                target: .routineDay(day.day)
            )
        }
    }

    private var detailHeader: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("Routine Info")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [.white, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))

                Text("Tracking day \(currentDay) of \(totalDays)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var trackerCard: some View {
        let progress = Double(currentDay) / Double(totalDays)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Progress")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange.opacity(0.9))

                    Text("Day \(currentDay)")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("This day is stored in UserDefaults.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.58))
                }

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.orange)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))

            Button {
                startCurrentRoutineWorkout()
            } label: {
                Label("Start Routine Workout", systemImage: "play.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button {
                    currentRoutineDay = max(1, currentDay - 1)
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .disabled(currentDay <= 1)

                Button {
                    currentRoutineDay = min(totalDays, currentDay + 1)
                } label: {
                    Label(currentDay >= totalDays ? "Done" : "Complete Day", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .disabled(currentDay >= totalDays)
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            Button {
                currentRoutineDay = 1
                expandedDays = [1]
            } label: {
                Label("Reset Routine Progress", systemImage: "arrow.counterclockwise")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.28), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func routineDayCard(_ day: RoutineWorkoutDay) -> some View {
        let isExpanded = expandedDays.contains(day.day)
        let totalCalories = day.exercises.reduce(0) { $0 + $1.calories_burned }
        let isCurrentDay = day.day == currentDay

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut) {
                    if isExpanded {
                        expandedDays.remove(day.day)
                    } else {
                        expandedDays.insert(day.day)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(spacing: 1) {
                        Text("DAY")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.orange.opacity(0.8))

                        Text("\(day.day)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(width: 52, height: 52)
                    .background(Color.orange.opacity(0.16))
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.muscle_group)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text("\(day.exercises.count) exercises - ~\(totalCalories) cal")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.orange)
                        .font(.headline)
                }
                .padding()
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(day.exercises) { exercise in
                        routineExerciseRow(exercise)
                    }

                    Button {
                        selectedWorkoutDay = day
                    } label: {
                        Label(
                            isCurrentDay ? "Start This Workout" : "Start Day \(day.day)",
                            systemImage: "play.circle.fill"
                        )
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(isCurrentDay ? Color.orange : Color.white.opacity(0.14))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        sharingWorkoutDay = day
                    } label: {
                        Label("Share Routine Day", systemImage: "square.and.arrow.up")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(isCurrentDay ? Color.orange.opacity(0.13) : Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentDay ? Color.orange.opacity(0.55) : Color.white.opacity(0.13), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.22), radius: 7)
    }

    private func routineExerciseRow(_ exercise: RoutineExercise) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "dumbbell.fill")
                .font(.caption)
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)
                .background(Color.orange.opacity(0.13))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(exercise.sets) sets x \(exercise.reps) reps")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.58))
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(weightText(for: exercise))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange.opacity(0.95))

                Text("~\(exercise.calories_burned) cal")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.48))
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.14))
        .cornerRadius(8)
    }

    private func weightText(for exercise: RoutineExercise) -> String {
        let weight = exercise.weight
        let formattedWeight = weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
        return "\(formattedWeight) \(exercise.unit)"
    }

    private func clampCurrentRoutineDay() {
        currentRoutineDay = min(max(currentRoutineDay, 1), totalDays)
    }

    private func startCurrentRoutineWorkout() {
        clampCurrentRoutineDay()
        selectedWorkoutDay = routineDays.first(where: { $0.day == currentDay }) ?? routineDays.first
    }
}

private struct RoutineWorkoutWindow: View {
    let day: RoutineWorkoutDay
    let totalRoutineDays: Int
    let onReturnHome: () -> Void
    @Binding var currentRoutineDay: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showWorkout = false
    @State private var exToday: String
    private let workoutPlan: workout_plans
    private let totalCalories: Int

    init(
        day: RoutineWorkoutDay,
        totalRoutineDays: Int,
        currentRoutineDay: Binding<Int>,
        onReturnHome: @escaping () -> Void
    ) {
        self.day = day
        self.totalRoutineDays = totalRoutineDays
        self.onReturnHome = onReturnHome
        self._currentRoutineDay = currentRoutineDay
        let plan = day.workoutPlan
        self.workoutPlan = plan
        self.totalCalories = plan.exercises.reduce(0) { $0 + $1.calories_burned }
        self._exToday = State(initialValue: day.muscle_group)
    }

    var body: some View {
        ZStack {
            AppBackgroundView()
            workoutPreview
        }
        .fullScreenCover(isPresented: $showWorkout) {
            StaringWorkWindow(
                todaysWork: workoutPlan,
                exToday: $exToday,
                cals: totalCalories,
                onWorkoutFinished: advanceRoutineDay,
                routineDay: day.day,
                routineExerciseWeights: day.exercises.map { $0.weight },
                routineExerciseUnits: day.exercises.map { $0.unit },
                onRoutineHome: {
                    showWorkout = false
                    onReturnHome()
                    dismiss()
                }
            )
            .onChange(of: exToday) {
                if exToday.isEmpty {
                    showWorkout = false
                    dismiss()
                }
            }
        }
    }

    private var workoutPreview: some View {
        VStack(spacing: 18) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            VStack(spacing: 6) {
                Text("Day \(day.day)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)

                Text(day.muscle_group)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LinearGradient(
                        colors: [.white, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))

                Text("\(day.exercises.count) exercises - ~\(totalCalories) calories")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(day.exercises) { exercise in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "dumbbell.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .frame(width: 26, height: 26)
                                .background(Color.orange.opacity(0.14))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("\(exercise.sets) sets x \(exercise.reps) reps")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.58))
                            }

                            Spacer()

                            Text(weightText(for: exercise))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
            }

            Button {
                showWorkout = true
            } label: {
                Label("Begin Routine Workout", systemImage: "play.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }

    private func advanceRoutineDay() {
        currentRoutineDay = min(day.day + 1, max(totalRoutineDays, 1))
    }

    private func weightText(for exercise: RoutineExercise) -> String {
        let formattedWeight = exercise.weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(exercise.weight))
            : String(format: "%.1f", exercise.weight)
        return "\(formattedWeight) \(exercise.unit)"
    }
}

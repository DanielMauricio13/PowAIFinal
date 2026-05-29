//
//  FisrtWindow.swift
//  Gym-app-ioss
//

import SwiftUI

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
            guard viewModel.items.isEmpty else { return }
            buildRegularWorkout()
        }
        .alert("HIIT Error", isPresented: $showHIITError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(hiitError ?? "Something went wrong generating your HIIT workout.")
        }
        .sheet(isPresented: $showRoutineWindow) {
            RoutineView {
                showRoutineWindow = false
            }
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
                "numHours":      user.numHours ?? "1.5"   // numHours is String on User
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
                            calories_burned: ex.calories_burned
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
                    calories_burned: exercise.calories_burned
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
    var weight: Double
    var unit: String
}

@MainActor
private final class RoutineViewModel: ObservableObject {
    @Published var routine: RoutineUserResponse?
    @Published var isLoading = false
    @Published var isRequestingNewRoutine = false
    @Published var message: String?

    private let decoder = JSONDecoder()

    var routineDays: [RoutineWorkoutDay] {
        routine?.routineTraining.workout_plan.sorted { $0.day < $1.day } ?? []
    }

    var hasRoutine: Bool {
        !routineDays.isEmpty
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

    func requestNewRoutine() async {
        guard !isRequestingNewRoutine else { return }

        isRequestingNewRoutine = true
        message = nil
        defer { isRequestingNewRoutine = false }

        do {
            let body = try JSONSerialization.data(withJSONObject: [:])
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
            } else if http.statusCode == 401 {
                message = "Please sign in again before requesting a routine."
            } else {
                message = "Routine request failed. Status \(http.statusCode)."
            }
        } catch {
            message = error.localizedDescription
        }
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
                Task { await viewModel.requestNewRoutine() }
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
                    await viewModel.requestNewRoutine()
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
}

private struct RoutineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let routine: RoutineUserResponse
    @Binding var currentRoutineDay: Int
    let onReturnHome: () -> Void
    @State private var expandedDays: Set<Int> = []
    @State private var selectedWorkoutDay: RoutineWorkoutDay?

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

            if showWorkout {
                StaringWorkWindow(
                    todaysWork: workoutPlan,
                    exToday: $exToday,
                    cals: totalCalories,
                    onWorkoutFinished: advanceRoutineDay,
                    routineDay: day.day,
                    routineExerciseWeights: day.exercises.map { $0.weight },
                    routineExerciseUnits: day.exercises.map { $0.unit },
                    onRoutineHome: onReturnHome
                )
                .onChange(of: exToday) {
                    if exToday.isEmpty {
                        dismiss()
                    }
                }
            } else {
                workoutPreview
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

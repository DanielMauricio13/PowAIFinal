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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.25, green: 0.02, blue: 0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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
                "age":           user.age,
                "gender":        user.gender,
                "weight":        Double(user.weight),
                "weightUnit":    "kg",
                "height":        Double(user.height),
                "heightUnit":    "cm",
                "bodyStructure": user.bodyStructure,
                "goal":          user.goal,
                "whereWork":     "gym",
                "level":         level.lowercased(),
                "numDays":       user.numDays,
                "numHours":      user.numHours   // numHours is String on User
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
                email:           user.email ,
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
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if item.isExpanded {
                    Text(item.description)
                        .font(.subheadline)
                        .padding(.top, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    HStack {
                        Spacer()
                        Button { exToday = item.title } label: {
                            Text("Start")
                                .font(.title2)
                                .frame(width: 150, height: 40)
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
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
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
                            HStack {
                                Text("• \(ex.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer()
                                Text("\(ex.reps) × \(ex.sets)  ~\(ex.calories_burned)cal")
                                    .font(.caption)
                                    .foregroundColor(.orange.opacity(0.7))
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
                                .frame(width: 150, height: 40)
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

//
//  WorkOutWindow.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/30/24.
//
import SwiftUI
import GoogleGenerativeAI

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

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: AdaptiveLayout.isCompactPhone ? 136 : 150), spacing: 12)
        ]
    }

    private var titleSize: CGFloat { AdaptiveLayout.scaled(35, compact: 27) }
    var body: some View {
        ZStack{

          
            if begginButton {
                StaringWorkWindow(todaysWork: todaysWork,exToday: $exToday ,cals: cals)
            }else{
                
                VStack(spacing: AdaptiveLayout.scaled(8, compact: 6)) {
                    
                    HStack(alignment: .center) {
                        Text("Today is \(todaysWork?.muscle_group ?? "Failed to pull")")
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
                    }
                        
                    
                    
                    HStack(alignment:.bottom ) {
                        Text("\n  Your excersises today are:").font(.title2).fontDesign(.rounded).bold().foregroundStyle(LinearGradient(colors: [Color.red.opacity(0.7),Color.purple.opacity(0.7), Color.white.opacity(0.7)],startPoint: .topLeading,endPoint: .bottomTrailing))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 12)
                    }
                    ScrollView {
                                if let exercises = todaysWork?.exercises {
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(exercises.indices, id: \.self) { i in
                                            let exercise = exercises[i]
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(exercise.name)
                                                    .font(.headline)
                                                Text("\(exercise.reps) reps x \(exercise.sets) sets")
                                                    .font(.subheadline)
                                                Text("~ \(exercise.calories_burned) cal")
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
                    Text("Burn approx \(cals) calories 🔥 in this workout!")
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
            Text("Ask Gemini for a different routine for \(todaysWork?.muscle_group ?? "this muscle group").")
        }
        .alert("Couldn’t update workout", isPresented: $showAlternateError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alternateErrorMessage)
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
            alternateErrorMessage = "Missing today's workout details."
            showAlternateError = true
            return
        }
        guard !todaysWork.exercises.isEmpty else {
            alternateErrorMessage = "There are no exercises to base a new routine on."
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
                 "sets": ex.sets, "calories_burned": ex.calories_burned]
            }

            let body: [String: Any] = [
                "day":               todaysWork.day,
                "muscleGroup":       todaysWork.muscle_group,
                "numHours":          mainUser?.numHours ?? "1-2",
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
            alternateErrorMessage = "Error: \(error.localizedDescription)"
            showAlternateError = true
        }
    }
}


struct WorkOutWindow_Previews: PreviewProvider {
    static var previews: some View {
        WorkOutWindow(exToday: .constant("Preview Workout"))
    }
}

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

    let columns: [GridItem] = [
           GridItem(.fixed(160), spacing: 16),
           GridItem(.fixed(160), spacing: 16)
       ]
    var body: some View {
        ZStack{

          
            if begginButton {
                StaringWorkWindow(todaysWork: todaysWork,exToday: $exToday ,cals: cals)
            }else{
                
                VStack{
                    
                    HStack(alignment: .center) {
                        Text("Today is \(todaysWork?.muscle_group ?? "Failed to pull")")
                            .font(.system(size: 35, weight: .bold,design: .rounded))
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
                        
                    
                    
                    HStack(alignment:.bottom ){
                        Text("\n  Your excersises today are:").font(.title2).fontDesign(.rounded).bold().foregroundStyle(LinearGradient(colors: [Color.red.opacity(0.7),Color.purple.opacity(0.7), Color.white.opacity(0.7)],startPoint: .topLeading,endPoint: .bottomTrailing))
                        Spacer(minLength: 90)
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
                                            .frame(width: 160, height: 120)
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
                    Text("Burn approx \(cals) calories 🔥 in this workout!").font(.title3).bold().foregroundStyle(Color.orange).fontDesign(.rounded)
                    Spacer(minLength: 40)
                    HStack{
                        Spacer()
                        Button{
                            exToday = ""
                        }label: {
                            Text("Go Back").bold().font(.title2).foregroundStyle(Color.white).background(Rectangle().frame(width: 90,height: 40).foregroundStyle(Color.gray.opacity(0.6)).clipShape(.buttonBorder))
                        }
                        Spacer(minLength: 140)
                        Button{
                            begginButton = true
                        }label: {
                            Text("Begin").bold().font(.title2).foregroundStyle(Color.white).background(Rectangle().frame(width: 90,height: 40).foregroundStyle(Color.accentColor).clipShape(.buttonBorder))
                        }
                        Spacer()
                    }
                    Spacer(minLength: 20)
                }
            }
        }
        .onAppear{
            if exToday != "failed"{
                for i in 0..<(userFullWork?.userExcersises.workout_plan.count ?? 1) {
                    if userFullWork?.userExcersises.workout_plan[i].muscle_group == exToday {
                        todaysWork = (userFullWork?.userExcersises.workout_plan[i] ?? workout_plans(day: 0, muscle_group: "sas", exercises: []))
                    }
                }
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
        for i in 0..<(todaysWork?.exercises.count ?? 1){
            cals += todaysWork?.exercises[i].calories_burned ?? 0
            temp += " - \(todaysWork?.exercises[i].name ?? ""): \(todaysWork?.exercises[i].reps ?? "" ) reps, x \(todaysWork?.exercises[i].sets ?? 1) sets. Approx \(todaysWork?.exercises[i].calories_burned ?? 1) calories burned\n\n"
            
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

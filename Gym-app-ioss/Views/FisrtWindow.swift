//
//  FisrtWindow.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/13/24.
//

import SwiftUI

struct FisrtWindow: View {
    var mainUser: User?
    var userFullWork: fullTraining?
    @StateObject var viewModel: ListViewModel
    @State  var expandedIndexes = Set<Int>()
    @State var ExcersisesOpt : userExcersise?
    @State var temp = ""
    @State var HIITitem: ExcListItem?
    @StateObject var viewModel2: ListViewModel
    @Binding  var exToday: String
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color(red: 0.25, green: 0.02, blue: 0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack{
                Text("Happy \(currentDayOfWeek())!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                    .foregroundStyle(LinearGradient(colors: [.white, .orange], startPoint: .leading, endPoint: .trailing))
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
                        ForEach(viewModel.items) { item in
                            ExpandableBoxView(item: item, exToday: $exToday)
                                .onTapGesture {
                                    viewModel.toggleExpand(for: item)
                                }
                                .animation(.easeInOut, value: item.isExpanded)
                        }
                        Text("Short In Time? Do a HIIT!")
                            .font(.title3)
                            .fontWeight(.heavy)
                            .padding()
                            .foregroundStyle(LinearGradient(colors: [.orange,.red], startPoint: .leading, endPoint: .trailing))
                            .italic()
                            .shadow(color: .red, radius: 20,y: 1)
                            .underline()
                        ForEach(viewModel2.items) { item in
                            ExpandableBoxView(item: item, exToday: $exToday)
                                .onTapGesture {
                                    viewModel2.toggleExpand(for: item)
                                }
                                .animation(.easeInOut, value: item.isExpanded)
                        }

                    }
                    .padding()
                }
            }
        }.onAppear{
            var cal = 0
            for i in 0..<(userFullWork?.userExcersises.workout_plan.count  ?? 1){
                for j in 0..<(userFullWork?.userExcersises.workout_plan[i].exercises.count ?? 1)
                {
                    temp += "\n\(userFullWork?.userExcersises.workout_plan[i].exercises[j].name ?? "failed"): \(userFullWork?.userExcersises.workout_plan[i].exercises[j].sets ?? 1) sets, \(userFullWork?.userExcersises.workout_plan[i].exercises[j].reps ?? "failed") reps"
                    cal += userFullWork?.userExcersises.workout_plan[i].exercises[j].calories_burned ?? 0
                }
                viewModel.items.append(ExcListItem( title: userFullWork?.userExcersises.workout_plan[i].muscle_group ?? "failed",description: temp, totalCalories: cal, duration: 20, NumExcersises: userFullWork?.userExcersises.workout_plan[i].exercises.count ?? 2))
                temp = ""
                cal = 0
                
            }
            
            viewModel2.items.append(ExcListItem(title: "Begginer High-intensity interval training ", description: "Begginer", totalCalories: 500, duration: 30, NumExcersises: 6))
            viewModel2.items.append(ExcListItem(title: "Medium High-intensity interval training ", description: "Medium", totalCalories: 500, duration: 30, NumExcersises: 6))
            viewModel2.items.append(ExcListItem(title: "Expert High-intensity interval training ", description: "Expert", totalCalories: 500, duration: 30, NumExcersises: 6))
            
            
        }
        
        
        
    }
    
    func currentDayOfWeek() -> String {
        let date = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        
        // Convert the numerical representation of the day to a string
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        
        return weekdays[dayOfWeek - 1] // Adjusting for 1-based index in weekdays array
    }
    
    struct ExpandableBoxView: View {
        var item: ExcListItem
       @Binding  var exToday:String
        var body: some View {
            VStack(alignment: .leading) {
                HStack{
                    Text(item.title)
                        .font(.system(size: 20,weight: .semibold, design: .rounded))
                        .lineLimit(1) // Limit title to one line
                        .truncationMode(.tail) // Truncate if it’s too long
                        .frame(maxWidth: .infinity, alignment: .leading) // Ensure full width
                }
                if item.isExpanded {
                    Text(item.description)
                        .font(.subheadline)
                        .padding(.top, 5)
                        .frame(maxWidth: .infinity, alignment: .leading) // Align description to leading
                    
                    Spacer()
                    
                    HStack {
                        
                            Spacer() // Center the button
                        Button(action: {exToday = item.title}) {
                                Text("Start")
                                    .font(.title2)
                                    .frame(width: 150, height: 40) // Set a fixed width for the button
                                    .padding(8)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                            }
                            Spacer() // Center the button
                        
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
}

struct ExpandableBox: View {
  let content: Text
  var isExpanded: Bool
  let onToggle: () -> Void

  var body: some View {
    VStack {
      content
        .foregroundColor(.white)
        .padding()
        .background(RoundedRectangle(cornerRadius: 90)
          .foregroundColor(isExpanded ? .blue : .gray))
        .onTapGesture {
          onToggle()
        }
    }
  }
}


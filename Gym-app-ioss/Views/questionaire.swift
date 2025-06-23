//
//  questionaire.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/15/23.
//

import SwiftUI
import RiveRuntime
struct questionaire: View {
    @State private var questions: [Question] = [
        Question(text: "What is your body Type?", options: ["Ectomorph", "Mesomorph", "Endomorph"], imageName: "cat" ),
            Question(text: "What is your objective?", options: ["Increase mass", "Stay fit", "Lose weight"], imageName: "cat"),
            Question(text: "Genetic gender?", options: ["Male", "Female"], imageName: "cat"),
            Question(text: "How many days do you want to workout per week?" , options: ["1", "2", "3", "4", "5" ], imageName: "cat"),
        Question(text: "how many hours per day do you want to workout?", options: ["less than 1 hour", "1 hour to 2 hours", "more than 2 hours"], imageName: "cat"),
        Question(text: "Where will you workout at?" , options: ["Home", "Gym" ], imageName: "cat"),
        Question(text: "What is your wourkout experience", options: ["Beginner", "Intermediate", "Expert"], imageName: "cat")
        ]
    @State private var currentQuestionIndex = 0
    
    let firstName: String
    let lastName:String
    var age: Int = 0
    @State var gender: String = ""
    var weight: Int = 0
   @State var goal: String = ""
   @State var bodyStructure: String = "ss"
    var height: Int = 0
    var DailyCalories: Int  = 0
    var DailyProtein: Int  = 0
    var email:String
    var password: String
    @State var numDays = ""
    @State var workoutHours = ""
    @State var nextPage:Bool = false
    @State var numDaysw: String = ""
    @State var numHours: String = ""
    var body: some View {
        
        NavigationView {
            ZStack{
                LinearGradient(colors: [Color.red.opacity(0.7),Color.gray.opacity(0.9)],startPoint: .topLeading,endPoint: .bottomTrailing).ignoresSafeArea()
                RiveViewModel(fileName: "shapes").view().ignoresSafeArea().blur(radius: 30)
                VStack {
                  
                    
                    if currentQuestionIndex < questions.count {
                        Text("Building your plan!").font(.largeTitle).bold().foregroundColor(.white).padding(.bottom,100)
                        if currentQuestionIndex == 0 {
                            Image("Body-Set") // Replace with the actual name of your image
                                            .resizable() // Makes the image resizable
                                            .aspectRatio(contentMode: .fit) // Maintains the aspect ratio
                                            .frame(width: 280, height: 200) // Sets the frame size
                                            .clipShape(Rectangle()) // Optionally clips the image to a circle
                                            .overlay(
                                                Rectangle().stroke(Color.white, lineWidth: 1) // Adds a border to the image
                                            ).border(Color.black,width: 2)
                                            .shadow(radius: 40)
                        }
                        QuestionView(question: $questions[currentQuestionIndex], nextQuestion: nextQuestion)
                        
                    } else {
                        if let numDaysInt = Int(questions[3].selectedOption) {
                            finalData(firstName: firstName,
                                      lastName: lastName,
                                      gender: questions[2].selectedOption,
                                      goal: questions[1].selectedOption,
                                      bodyStructure: questions[0].selectedOption,
                                      email: email,
                                      password: password,
                                      numDays: numDaysInt,
                                      numHours: questions[4].selectedOption,
                                      whereWork: questions[5].selectedOption, level: questions[6].selectedOption)
                        } else {
                            
                        }
                        
                        
                    }
                }
            }
        }
    
    }
    func nextQuestion() {
            currentQuestionIndex += 1
        }
    
    
   
    
}

struct questionaire_Previews: PreviewProvider {
    static var previews: some View {
        questionaire(firstName: "daniel", lastName: "p", email: "oakdd", password: "kdkasdkla")
    }
}


struct Question: Hashable {
    var text: String
    var options: [String]
    var selectedOption: String = ""
    var imageName: String // Name of the image
}

struct QuestionView: View {
    @Binding var question: Question
    var nextQuestion: () -> Void
    
    var body: some View {
        
            
        ZStack {
            
            if(question.options.count <= 3){
                Text(question.text)
                    .font(.title)
                    .padding(.bottom,300).foregroundStyle(LinearGradient(colors: [.white.opacity(0.8),.purple], startPoint: .topLeading, endPoint: .bottomTrailing)).bold().fontDesign(.rounded)
                HStack{
                    ForEach(question.options, id: \.self) { option in
                        Button(action: {
                            question.selectedOption = option // Store the selected option
                            nextQuestion()
                        }) {
                            Text(option)
                                .font(.headline)
                                .padding()
                                .foregroundColor(.white)
                                .frame(width: 110, height: 90, alignment: .center)
                                .background(RoundedRectangle(cornerRadius: 50).frame(width: 110, height: 50, alignment: .center).foregroundStyle( LinearGradient(colors: [Color.orange.opacity(0.7),Color.red.opacity(0.7)],startPoint: .topLeading,endPoint: .bottomTrailing)))
                            
                        }
                        .padding(.bottom, 10)
                    }
                }
        }
            else {
              
                
                VStack(spacing: 1){
                    Text(question.text)
                        .font(.title)
                        .padding().foregroundStyle(LinearGradient(colors: [.white.opacity(0.8),.purple], startPoint: .topLeading, endPoint: .bottomTrailing)).bold().fontDesign(.rounded).frame(height: 150)
                    ForEach(question.options, id: \.self) { option in
                        Button(action: {
                            question.selectedOption = option // Store the selected option
                            nextQuestion()
                        }) {
                            Text(option)
                                .font(.headline)
                                .padding()
                                .foregroundColor(.white)
                                .frame(width: 110, height: 90, alignment: .center)
                                .background(RoundedRectangle(cornerRadius: 50).frame(width: 110, height: 50, alignment: .center).foregroundStyle( LinearGradient(colors: [Color.orange.opacity(0.7),Color.red.opacity(0.7)],startPoint: .topLeading,endPoint: .bottomTrailing)))
                            
                        }
                        .padding(.bottom, 10)
                    }
                }
            }
            }.navigationBarBackButtonHidden()
                .padding()
        
    }
}

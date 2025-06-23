//
//  Calories.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/13/24.
//

import SwiftUI

struct Calories: View {
    var mainUser: User?
     
    var body: some View {
        Text("Todays Nutrition").font(.largeTitle).bold() .italic()
            .shadow(color: .white, radius: 10).foregroundStyle(Color.white)
        ScrollView{
            
        VStack {
            
            HStack{
                Spacer()
                VStack(alignment: .center) {
                    CircularProgressBar(progress: HealthManager.shared.calories, goal: mainUser?.DailyCalories ?? 1)
                    Text("Your Calories goal: \(HealthManager.shared.calories) / \(mainUser?.DailyCalories ?? 1) 🔥").font(.title3).foregroundStyle(Color.white).shadow(color: .red, radius: 10)
                    Spacer()
                }.frame(width: 200,height: 300)
                Spacer()
                VStack(alignment: .center){
                    CircularProgressBar(progress: HealthManager.shared.protein, goal: mainUser?.DailyProtein ?? 1)
                    Text("Your Protein goal: \(HealthManager.shared.protein) / \(mainUser?.DailyProtein ?? 1) 🍗").font(.title3).foregroundStyle(Color.white).shadow(color: .red, radius: 10)
                    Spacer()
                }.frame(width: 200,height: 300)
                Spacer()
            }
            HStack{
                Spacer()
                VStack(alignment: .center) {
                    CircularProgressBar(progress: HealthManager.shared.carbs, goal: mainUser?.carbs ?? 1)
                    Text("Your Carbs goal: \(HealthManager.shared.carbs) / \(mainUser?.carbs ?? 1) 🥐").font(.title3).foregroundStyle(Color.white).shadow(color: .red, radius: 10)
                    Spacer()
                }.frame(width: 200,height: 300)
                Spacer()
                VStack(alignment: .center){
                    CircularProgressBar(progress: HealthManager.shared.sugars, goal: mainUser?.sugars ?? 1)
                    Text("Your Sugar goal: \(HealthManager.shared.sugars) / \(mainUser?.sugars ?? 1) 🍭").font(.title3).foregroundStyle(Color.white).shadow(color: .red, radius: 10)
                    Spacer()
                }.frame(width: 200,height: 300)
                Spacer()
            }
        }
        .padding()
    }
        
    }
        
    }


struct CircularProgressBar: View {
    var progress: Int
    var goal: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20.0)
                .frame(width: 150, height: 150) // Adjust the frame size
                .opacity(0.3)
                .foregroundColor(Color.black)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(Double(progress) / Double(goal), 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                .frame(width: 150, height: 150) // Adjust the frame size
                .foregroundColor(Color.red)
                .rotationEffect(Angle(degrees: 270.0))
                
            
            Text(String(format: "%d%%", min(progress * 100 / goal, 100)))
                .font(.title)
                .foregroundStyle(Color.white)
                .bold()
        }
        .padding(40)
    }
}





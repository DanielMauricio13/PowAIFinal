//
//  Calories.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/13/24.
//

//
//  Calories.swift
//  Gym-app-ioss
//

import SwiftUI

struct Calories: View {
    var mainUser: User?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                gymBackground
                // ── Main content ──────────────────────────────────────
                VStack {
                    Text("Todays Nutrition")
                        .font(.largeTitle).bold().italic()
                        .shadow(color: .white, radius: 10)
                        .foregroundStyle(Color.white)

                    ScrollView {
                        VStack {
                            HStack {
                                Spacer()
                                VStack(alignment: .center) {
                                    CircularProgressBar(progress: HealthManager.shared.calories,
                                                        goal: mainUser?.DailyCalories ?? 1)
                                    Text("Your Calories goal: \(HealthManager.shared.calories) / \(mainUser?.DailyCalories ?? 1) 🔥")
                                        .font(.title3).foregroundStyle(Color.white)
                                        .shadow(color: .red, radius: 10)
                                    Spacer()
                                }.frame(width: 200, height: 300)
                                Spacer()
                                VStack(alignment: .center) {
                                    CircularProgressBar(progress: HealthManager.shared.protein,
                                                        goal: mainUser?.DailyProtein ?? 1)
                                    Text("Your Protein goal: \(HealthManager.shared.protein) / \(mainUser?.DailyProtein ?? 1) 🍗")
                                        .font(.title3).foregroundStyle(Color.white)
                                        .shadow(color: .red, radius: 10)
                                    Spacer()
                                }.frame(width: 200, height: 300)
                                Spacer()
                            }

                            HStack {
                                Spacer()
                                VStack(alignment: .center) {
                                    CircularProgressBar(progress: HealthManager.shared.carbs,
                                                        goal: mainUser?.carbs ?? 1)
                                    Text("Your Carbs goal: \(HealthManager.shared.carbs) / \(mainUser?.carbs ?? 1) 🥐")
                                        .font(.title3).foregroundStyle(Color.white)
                                        .shadow(color: .red, radius: 10)
                                    Spacer()
                                }.frame(width: 200, height: 300)
                                Spacer()
                                VStack(alignment: .center) {
                                    CircularProgressBar(progress: HealthManager.shared.sugars,
                                                        goal: mainUser?.sugars ?? 1)
                                    Text("Your Sugar goal: \(HealthManager.shared.sugars) / \(mainUser?.sugars ?? 1) 🍭")
                                        .font(.title3).foregroundStyle(Color.white)
                                        .shadow(color: .red, radius: 10)
                                    Spacer()
                                }.frame(width: 200, height: 300)
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }

                // ── Tracker button — bottom-center overlay ──────────────
                NavigationLink {
                    NutritionTrackerView(
                        email: mainUser?.email ?? "",
                        user: mainUser ?? User(id: nil, firstName: "", lastName: "", membershipStatus: "trial")
                    )
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption.weight(.bold))
                        Text("Tracker")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(colors: [.red, .orange],
                                       startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .shadow(color: .red.opacity(0.4), radius: 6, x: 0, y: 3)
                }
                                .padding(.bottom, 20)
            }
        }
    }
    private var gymBackground: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1),
                     Color(red: 0.2, green: 0.03, blue: 0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}



struct CircularProgressBar: View {
    var progress: Int
    var goal: Int
    
    private var progressFraction: Double {
        guard goal > 0 else { return 0 }
        return min(Double(progress) / Double(goal), 1.0)
    }

    private var progressPercent: Int {
        guard goal > 0 else { return 0 }
        return min(progress * 100 / goal, 100)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20.0)
                .frame(width: 150, height: 150) // Adjust the frame size
                .opacity(0.3)
                .foregroundColor(Color.black)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(progressFraction))
                .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                .frame(width: 150, height: 150) // Adjust the frame size
                .foregroundColor(Color.red)
                .rotationEffect(Angle(degrees: 270.0))
                
            
            Text(String(format: "%d%%", progressPercent))
                .font(.title)
                .foregroundStyle(Color.white)
                .bold()
        }
        .padding(40)
    }
}



//
//  ExcerciseWindow.swift
//  Gym-app-ioss
//

import SwiftUI
import RiveRuntime

struct ExcerciseWindow: View {
    var mainUser: User?
    @State var whichWin: Int = 0
    @State var caloriesToday: Int = 0
    var userFullWork: fullTraining?
    @State var persistenceManager = PersistenceManager()
    @State var LogOut: Bool = false
    @State var exToday: String = ""
    @State var counts: Int?

    // ── HIIT — generated on demand, not from DB ───────────────────────────────
    @State var hiitWork: fullTraining? = nil

    var body: some View {
        if LogOut {
            LogInWindow()
        } else {
            NavigationView {
                ZStack {
                    // Background blobs
                    Circle()
                        .frame(width: 300)
                        .foregroundStyle(Color.blue.opacity(0.3))
                        .blur(radius: 10)
                        .offset(x: -100, y: 150)
                    Circle()
                        .frame(width: 300)
                        .foregroundStyle(Color.green.opacity(0.3))
                        .blur(radius: 10)
                        .offset(x: 150, y: -250)
                    Circle()
                        .frame(width: 300)
                        .foregroundStyle(LinearGradient(
                            colors: [Color.purple, .mint],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .blur(radius: 10)
                        .offset(x: 150, y: -270)
                    RiveViewModel(fileName: "shapes").view()
                        .ignoresSafeArea()
                        .blur(radius: 30)

                    VStack {
                        // ── Content area ──────────────────────────────────────
                        if exToday != "" && whichWin == 0 {
                            WorkOutWindow(
                                mainUser: mainUser,
                                userFullWork: activeWorkout,
                                exToday: $exToday
                            )
                        } else if whichWin == 0 {
                            FisrtWindow(
                                mainUser: mainUser,
                                userFullWork: userFullWork,
                                viewModel: ListViewModel(items: []),
                                viewModel2: ListViewModel(items: []),
                                exToday: $exToday,
                                hiitWork: $hiitWork
                            )
                        } else if whichWin == 1 {
                            NutritionView(
                                viewModel: ListViewModel(items: []),
                                viewModel2: ListViewModel(items: []),
                                persistenceManager: $persistenceManager,
                                email: mainUser?.email ?? ""
                            )
                        } else if whichWin == 2 {
                            Calories(mainUser: mainUser)
                        } else if whichWin == 3 {
                            // ── Weight Progress tab ───────────────────────────
                            WeightTrackerView(email: mainUser?.email ?? "")
                        } else if whichWin == 4 {
                            if let mainUser {
                                UserSettings(
                                    persistenceManager: $persistenceManager,
                                    LogOut: $LogOut,
                                    mainUser: mainUser
                                )
                            } else {
                                Text("User data unavailable. Please sign in again.")
                                    .foregroundStyle(.white)
                                    .padding()
                            }
                        }

                        Spacer()

                        // ── Tab bar ───────────────────────────────────────────
                        HStack {
                            Spacer()
                            tabButton(icon: "house",                     tab: 0, activeColor: .cyan)
                            Spacer()
                            tabButton(icon: "leaf",                      tab: 1, activeColor: .green)
                            Spacer()
                            tabButton(icon: "flame",                     tab: 2, activeColor: .orange)
                            Spacer()
                            tabButton(icon: "chart.line.uptrend.xyaxis", tab: 3, activeColor: .green)
                            Spacer()
                            tabButton(icon: "gear",                      tab: 4, activeColor: .red)  // ← was tab:3, fixed
                            Spacer()
                        }
                        .padding(.horizontal, AdaptiveLayout.isCompactPhone ? 10 : 16)
                        .padding(.vertical, 10)
                        .frame(height: AdaptiveLayout.scaled(70, compact: 64))
                        .background(RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
                        .edgesIgnoringSafeArea(.bottom)
                    }
                }
                .background(AppBackgroundView())
                .navigationBarHidden(true)
            }
            .onAppear {
                counts = userFullWork?.userExcersises.workout_plan.count
            }
        }
    }

    // ── Pick the right workout for WorkOutWindow ──────────────────────────────
    private var activeWorkout: fullTraining? {
        if let hiit = hiitWork,
           hiit.userExcersises.workout_plan.contains(where: { $0.muscle_group == exToday }) {
            return hiit
        }
        return userFullWork
    }

    // ── Tab button helper ─────────────────────────────────────────────────────
    @ViewBuilder
    private func tabButton(icon: String, tab: Int, activeColor: Color) -> some View {
        Button { whichWin = tab } label: {
            Image(systemName: icon)
                .frame(
                    width: AdaptiveLayout.scaled(52, compact: 44),
                    height: AdaptiveLayout.scaled(52, compact: 44)
                )
                .foregroundColor(whichWin == tab ? activeColor : .white)
                .background(Color.black)
                .cornerRadius(10)
        }
    }
}

#Preview {
    ExcerciseWindow()
}

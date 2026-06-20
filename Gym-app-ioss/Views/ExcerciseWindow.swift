//
//  ExcerciseWindow.swift
//  Gym-app-ioss
//

import SwiftUI
import RiveRuntime

struct ExcerciseWindow: View {
    var mainUser: User?
    var onUserUpdate: (User) -> Void = { _ in }
    var onWorkoutUpdate: (fullTraining) -> Void = { _ in }
    @State var whichWin: Int = 0
    @State var caloriesToday: Int = 0
    var userFullWork: fullTraining?
    @State var persistenceManager = PersistenceManager()
    @State var LogOut: Bool = false
    @State var exToday: String = ""
    @State var counts: Int?
    @State private var pendingAlarmID: String?

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
                                exToday: $exToday,
                                isHIITWorkout: isHIITActive
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
                                email: mainUser?.email ?? "",
                                mainUser: mainUser
                            )
                        } else if whichWin == 2 {
                            ProgressSummaryView(email: mainUser?.email ?? "", userFullWork: userFullWork)
                        } else if whichWin == 3 {
                            if let mainUser {
                                UserSettings(
                                    persistenceManager: $persistenceManager,
                                    LogOut: $LogOut,
                                    mainUser: mainUser,
                                    onUserUpdate: onUserUpdate,
                                    onWorkoutUpdate: onWorkoutUpdate
                                )
                            } else {
                                Text("User data unavailable. Please sign in again.")
                                    .foregroundStyle(.white)
                                    .padding()
                            }
                        } else if whichWin == 4 {
                            ProductivityView(pendingAlarmID: $pendingAlarmID)
                        }

                        Spacer()

                        // ── Tab bar ───────────────────────────────────────────
                        HStack {
                            Spacer()
                            tabButton(icon: "house",                     tab: 0, activeColor: .cyan)
                            Spacer()
                            tabButton(icon: "leaf",                      tab: 1, activeColor: .green)
                            Spacer()
                            tabButton(icon: "chart.line.uptrend.xyaxis", tab: 2, activeColor: .orange)
                            Spacer()
                            tabButton(icon: "alarm",                     tab: 4, activeColor: .mint)
                            Spacer()
                            tabButton(icon: "gear",                      tab: 3, activeColor: .red)
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
            .onReceive(NotificationCenter.default.publisher(for: .powAIAlarmNotificationTapped)) { notification in
                pendingAlarmID = notification.object as? String
                whichWin = 4
            }
        }
    }

    // ── Pick the right workout for WorkOutWindow ──────────────────────────────
    private var activeWorkout: fullTraining? {
        if isHIITActive, let hiit = hiitWork {
            return hiit
        }
        return userFullWork
    }

    private var isHIITActive: Bool {
        hiitWork?.userExcersises.workout_plan.contains(where: { $0.muscle_group == exToday }) == true
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

private enum ProgressSummaryMode: String, CaseIterable {
    case lifts
    case bodyWeight

    var title: LocalizedStringKey {
        switch self {
        case .lifts:
            return "Lifts"
        case .bodyWeight:
            return "Body weight"
        }
    }

    var icon: String {
        switch self {
        case .lifts:
            return "dumbbell.fill"
        case .bodyWeight:
            return "scalemass.fill"
        }
    }
}

private struct ProgressSummaryView: View {
    let email: String
    let userFullWork: fullTraining?
    @State private var selectedMode: ProgressSummaryMode = .lifts

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch selectedMode {
                case .lifts:
                    LiftSummaryView(userFullWork: userFullWork, topContentInset: 92)
                case .bodyWeight:
                    WeightTrackerView(email: email, topContentInset: 92)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: selectedMode)

            modePicker
                .padding(.horizontal, 24)
                .padding(.top, 18)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(ProgressSummaryMode.allCases, id: \.self) { mode in
                let isSelected = selectedMode == mode
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedMode = mode
                    }
                } label: {
                    Label(mode.title, systemImage: mode.icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.62))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            modeButtonBackground(isSelected: isSelected),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            .ultraThinMaterial.opacity(0.5),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private func modeButtonBackground(isSelected: Bool) -> AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
        }

        return AnyShapeStyle(LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom))
    }
}

#Preview {
    ExcerciseWindow()
}

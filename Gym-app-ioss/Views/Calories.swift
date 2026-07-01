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

    private let horizontalPadding: CGFloat = 18
    private let columnSpacing: CGFloat = 18

    private var nutritionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: columnSpacing),
            GridItem(.flexible(), spacing: columnSpacing)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                gymBackground
                // ── Main content ──────────────────────────────────────
                VStack(spacing: AdaptiveLayout.isCompactPhone ? 12 : 18) {
                    Text("Todays Nutrition")
                        .font(AdaptiveLayout.isCompactPhone ? .title : .largeTitle)
                        .bold()
                        .italic()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .shadow(color: .white, radius: 10)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal)

                    GeometryReader { proxy in
                        let metrics = nutritionMetrics(for: proxy.size)

                        ScrollView {
                            LazyVGrid(columns: nutritionColumns, spacing: metrics.gridSpacing) {
                                nutritionGoalCard(
                                    title: "Calories",
                                    value: HealthManager.shared.calories,
                                    goal: mainUser?.DailyCalories ?? 1,
                                    emoji: "🔥",
                                    metrics: metrics
                                )

                                nutritionGoalCard(
                                    title: "Protein",
                                    value: HealthManager.shared.protein,
                                    goal: mainUser?.DailyProtein ?? 1,
                                    emoji: "🍗",
                                    metrics: metrics
                                )

                                nutritionGoalCard(
                                    title: "Carbs",
                                    value: HealthManager.shared.carbs,
                                    goal: mainUser?.carbs ?? 1,
                                    emoji: "🥐",
                                    metrics: metrics
                                )

                                nutritionGoalCard(
                                    title: "Sugar",
                                    value: HealthManager.shared.sugars,
                                    goal: mainUser?.sugars ?? 1,
                                    emoji: "🍭",
                                    metrics: metrics
                                )
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 110)
                        }
                    }
                }

                // ── Tracker button — bottom-center overlay ──────────────
                NavigationLink {
                    NutritionTrackerView(
                        email: mainUser?.email ?? "",
                        user: mainUser ?? User(id: nil, firstName: "", lastName: "", membershipStatus: "free")
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
        AppBackgroundView()
    }

    private struct NutritionMetrics {
        let ringDiameter: CGFloat
        let ringStroke: CGFloat
        let gridSpacing: CGFloat
        let cardMinHeight: CGFloat
        let labelFont: Font
        let percentFont: Font
    }

    private func nutritionMetrics(for size: CGSize) -> NutritionMetrics {
        let columnWidth = (size.width - (horizontalPadding * 2) - columnSpacing) / 2
        let ringDiameter = min(max(columnWidth * 0.92, 120), 178)
        let ringStroke = min(max(ringDiameter * 0.14, 16), 24)
        let isRoomy = size.width >= 410 && size.height >= 720

        return NutritionMetrics(
            ringDiameter: ringDiameter,
            ringStroke: ringStroke,
            gridSpacing: isRoomy ? 34 : 24,
            cardMinHeight: ringDiameter + (isRoomy ? 118 : 104),
            labelFont: isRoomy ? .title3 : .system(size: 18, weight: .regular, design: .rounded),
            percentFont: isRoomy ? .largeTitle : .title
        )
    }

    private func nutritionGoalCard(title: String, value: Int, goal: Int, emoji: String, metrics: NutritionMetrics) -> some View {
        VStack(spacing: AdaptiveLayout.isCompactPhone ? 10 : 14) {
            CircularProgressBar(
                progress: value,
                goal: goal,
                diameter: metrics.ringDiameter,
                strokeWidth: metrics.ringStroke,
                percentFont: metrics.percentFont
            )

            Text("Your \(title) goal:\n\(value) / \(goal) \(emoji)")
                .font(metrics.labelFont)
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .red, radius: 10)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: metrics.cardMinHeight, alignment: .top)
    }
}



struct CircularProgressBar: View {
    var progress: Int
    var goal: Int
    var diameter: CGFloat = 130
    var strokeWidth: CGFloat = 20
    var percentFont: Font = .title
    
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
                .stroke(lineWidth: strokeWidth)
                .frame(width: diameter, height: diameter)
                .opacity(0.3)
                .foregroundColor(Color.black)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(progressFraction))
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                .frame(width: diameter, height: diameter)
                .foregroundColor(Color.red)
                .rotationEffect(Angle(degrees: 270.0))
                
            
            Text(String(format: "%d%%", progressPercent))
                .font(percentFont)
                .foregroundStyle(Color.white)
                .bold()
        }
        .padding(.vertical, AdaptiveLayout.isCompactPhone ? 10 : 16)
    }
}

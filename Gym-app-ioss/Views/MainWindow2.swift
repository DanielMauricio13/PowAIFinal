//
//  MainWindow2.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 9/29/23.
//

import SwiftUI

struct MainWindow2: View {
    var mainUser: User?
    var userFullWork: fullTraining?

    @State private var buttonPressed: Bool = false

    var body: some View {
        if buttonPressed {
            ExcerciseWindow(mainUser: mainUser, userFullWork: userFullWork)
        } else {
            ZStack {
                gymBackground

                VStack(alignment: .leading, spacing: 24) {
                    welcomeHeader
                    quickSummaryCard
                    primaryAction

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
        }
    }

    private var gymBackground: some View {
        AppBackgroundView()
        .overlay(
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 260)
                .blur(radius: 18)
                .offset(x: 140, y: -260)
        )
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Welcome back")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Text(mainUser?.firstName ?? "Athlete")
                .font(.system(size: AdaptiveLayout.scaled(42, compact: 34), weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("Focused sessions. Clear progress. Let's train.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.top, 12)
    }

    private var quickSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today")
                .font(.title3.weight(.bold))
                .foregroundColor(.white)

            Label("Strength plan ready", systemImage: "checkmark.circle.fill")
                .foregroundColor(.white.opacity(0.95))

            Label("Warm-up before first set", systemImage: "flame.fill")
                .foregroundColor(.white.opacity(0.95))

            Label("Track every rep for better gains", systemImage: "chart.line.uptrend.xyaxis")
                .foregroundColor(.white.opacity(0.95))
        }
        .font(.subheadline.weight(.semibold))
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.35), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var primaryAction: some View {
        Button {
            buttonPressed = true
        } label: {
            HStack(spacing: 12) {
                Text("Start Workout")
                    .font(.headline.weight(.bold))

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 6)
        }
        .accessibilityHint("Starts your planned training session")
    }
}

#Preview {
    MainWindow2()
}

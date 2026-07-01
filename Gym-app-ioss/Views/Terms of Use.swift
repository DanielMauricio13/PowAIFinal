//
//  Terms_of_Use.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 6/18/25.
//

import SwiftUI

struct Terms_of_Use: View {

    // MARK: - Data Model
    struct TermsSection: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let sections: [TermsSection] = [
        .init(
            icon: "info.circle.fill",
            title: "General Use",
            body: "PowAI provides AI-assisted fitness, nutrition, workout, and activity-tracking features for general informational and wellness purposes only."
        ),
        .init(
            icon: "stethoscope",
            title: "Not Medical Advice",
            body: "PowAI does not provide medical advice, diagnosis, treatment, or professional nutrition, fitness, or healthcare services. Consult a qualified healthcare professional before making significant changes to your diet, exercise, supplements, or health habits."
        ),
        .init(
            icon: "sparkles",
            title: "AI-Generated Content",
            body: "AI-generated workouts, macro estimates, food analysis, and nutrition suggestions may be inaccurate, incomplete, or not appropriate for your personal health condition. Macro and calorie results are estimates only — verify nutrition information independently."
        ),
        .init(
            icon: "lock.shield.fill",
            title: "Privacy & Data",
            body: "PowAI may collect account info, fitness profile details, nutrition logs, food images, barcode scans, and activity data to provide app features. This app data may be processed by PowAI's backend and third-party AI services when you request AI-powered features. Apple Health heart-rate data is read only on your device during active workouts and is not stored on PowAI servers, sent to third-party AI services, sold to data brokers, or used for advertising."
        ),
        .init(
            icon: "cpu.fill",
            title: "Third-Party AI Services",
            body: "Some features use third-party AI services to process user-provided content such as food photos or fitness inputs in order to generate estimates and recommendations."
        ),
        .init(
            icon: "exclamationmark.triangle.fill",
            title: "Safety Warning",
            body: "If you experience pain, dizziness, shortness of breath, allergic reactions, or any other concerning symptoms, stop using the relevant workout or nutrition recommendation immediately and seek appropriate medical help."
        ),
        .init(
            icon: "hand.raised.fill",
            title: "Acceptable Use",
            body: "By continuing, you agree not to misuse the app, attempt unauthorized access, upload harmful content, or use PowAI as a replacement for professional medical care."
        ),
    ]

    var body: some View {
        ZStack {
            // MARK: - Background
            AppBackgroundView()

            Circle()
                .frame(width: 300)
                .foregroundStyle(Color.blue.opacity(0.3))
                .blur(radius: 10)
                .offset(x: -100, y: -300)

            Circle()
                .frame(width: 300)
                .foregroundStyle(Color.white.opacity(0.3))
                .blur(radius: 10)
                .offset(x: 150, y: 400)

            // MARK: - Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.top, 24)

                        Text("Terms of Use")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)

                        Text("Last updated June 2025")
                            .font(.caption)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.bottom, 28)

                    // Intro card
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                        Text("By using PowAI, you agree to the terms described below.")
                            .font(.subheadline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    // Section cards
                    VStack(spacing: 14) {
                        ForEach(sections) { section in
                            SectionCard(section: section)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Footer note
                    Text("These terms may be updated periodically. Continued use of PowAI constitutes acceptance of any revised terms.")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 28)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section Card Subview
private struct SectionCard: View {
    let section: Terms_of_Use.TermsSection
    @State private var expanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row — always visible, tappable
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: section.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                        .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

                    Text(section.title)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expandable body
            if expanded {
                Divider()
                    .background(.white.opacity(0.15))
                    .padding(.horizontal, 16)

                Text(section.body)
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        Terms_of_Use()
    }
}

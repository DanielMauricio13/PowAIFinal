//
//  questionaire.swift
//  Gym-app-ioss
//
//  Redesigned: better layout, no overflow, card-style options
//

import SwiftUI
import RiveRuntime

// MARK: - Data Model

struct Question: Hashable {
    var text: String
    var options: [String]
    var selectedOption: String = ""
    var imageName: String
}

// MARK: - Main View

struct questionaire: View {

    @State private var questions: [Question] = [
        Question(text: "Genetic gender?",
                 options: ["Male", "Female"],
                 imageName: "cat"),
        Question(text: "What is your body type?",
                 options: ["Ectomorph", "Mesomorph", "Endomorph"],
                 imageName: "Body-Set"),
        Question(text: "What is your objective?",
                 options: ["Increase mass", "Stay fit", "Lose weight"],
                 imageName: "cat"),
        Question(text: "Days per week to workout?",
                 options: ["1", "2", "3", "4", "5", "6", "7"],
                 imageName: "cat"),
        Question(text: "Hours per day to workout?",
                 options: ["< 1 hour", "1 – 1:30 hrs", "1:30 – 2 hrs", "> 2 hours"],
                 imageName: "cat"),
        Question(text: "Where will you workout?",
                 options: ["Home", "Gym"],
                 imageName: "cat"),
        Question(text: "Workout experience level?",
                 options: ["Beginner", "Intermediate", "Advanced"],
                 imageName: "cat"),
    ]

    @State private var currentQuestionIndex = 0
    @State private var animateIn = false
    @State private var showFinalData = false

    // Passed-in user info
    let firstName: String
    let lastName: String
    var age: Int = 0
    var weight: Int = 0
    var height: Int = 0
    var email: String
    var password: String

    private var progress: Double {
        Double(currentQuestionIndex) / Double(questions.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppBackgroundView()

                RiveViewModel(fileName: "shapes").view()
                    .ignoresSafeArea()
                    .blur(radius: 30)

                // Quiz screen
                VStack(spacing: 0) {
                    headerBar
                    Spacer(minLength: 0)
                    questionCard
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentQuestionIndex)
            }
            .navigationDestination(isPresented: $showFinalData) {
                finalDataView
                    .navigationBarBackButtonHidden(true)
            }
            .navigationBarBackButtonHidden(true)
        }
        .navigationBarBackButtonHidden(true)
    }

    private var finalDataView: some View {
        finalData(
            firstName: firstName,
            lastName: lastName,
            gender: selectedOption(at: 0, fallback: "Male"),
            goal: selectedOption(at: 2, fallback: "Stay fit"),
            bodyStructure: selectedOption(at: 1, fallback: "Mesomorph"),
            email: email,
            password: password,
            numDays: selectedNumDays,
            numHours: selectedOption(at: 4, fallback: "1 – 1:30 hrs"),
            whereWork: selectedOption(at: 5, fallback: "Gym"),
            level: selectedOption(at: 6, fallback: "Intermediate")
        )
    }

    private var selectedNumDays: Int {
        Int(selectedOption(at: 3, fallback: "4")) ?? 4
    }

    private func selectedOption(at index: Int, fallback: String) -> String {
        guard questions.indices.contains(index),
              !questions[index].selectedOption.isEmpty else {
            return fallback
        }
        return questions[index].selectedOption
    }

    // MARK: - Header

    private var headerBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Back button (non-functional on first question)
                Button {
                    if currentQuestionIndex > 0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentQuestionIndex -= 1
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(currentQuestionIndex > 0 ? 1 : 0.3))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .disabled(currentQuestionIndex == 0)

                Spacer()

                Text("Building your plan")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                // Step counter
                Text("\(currentQuestionIndex + 1) / \(questions.count)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 5)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: geo.size.width * progress, height: 5)
                        .animation(.easeInOut(duration: 0.4), value: currentQuestionIndex)
                }
            }
            .frame(height: 5)
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Body Type Info

    private let bodyTypeDescriptions: [(name: String, emoji: String, desc: String)] = [
        ("Ectomorph",  "🦴", "Lean & long. Fast metabolism, struggles to gain mass."),
        ("Mesomorph",  "💪", "Athletic & muscular. Responds quickly to training."),
        ("Endomorph",  "🔥", "Broader build. Gains mass easily, tends to store fat."),
    ]

    private var bodyTypeImageName: String {
        questions[0].selectedOption == "Male" ? "Body-Set" : "Female-Body-Set"
    }

    // MARK: - Question Card

    private var questionCard: some View {
        VStack(spacing: 20) {

            // Body-type question: image + description cards
            if currentQuestionIndex == 1 {
                Image(bodyTypeImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )

                // Per-type description pills
                VStack(spacing: 8) {
                    ForEach(bodyTypeDescriptions, id: \.name) { item in
                        HStack(spacing: 12) {
                            Text(item.emoji)
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(item.desc)
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                        )
                    }
                }
            }

            // Question text
            Text(questions[currentQuestionIndex].text)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)

            // Options list — always scrollable so nothing clips
            ScrollView(showsIndicators: false) {
                optionsGrid(for: questions[currentQuestionIndex])
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Options Grid

    @ViewBuilder
    private func optionsGrid(for question: Question) -> some View {
        let options = question.options
        // Days (7 items) use a 4-column number grid; everything else 1-column cards
        if options.count == 7 {
            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()),
                GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 12) {
                ForEach(options, id: \.self) { option in
                    optionButton(option: option, compact: true)
                }
            }
        } else {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    optionButton(option: option, compact: false)
                }
            }
        }
    }

    // MARK: - Option Button

    @ViewBuilder
    private func optionButton(option: String, compact: Bool) -> some View {
        Button {
            guard questions.indices.contains(currentQuestionIndex) else { return }
            questions[currentQuestionIndex].selectedOption = option

            if currentQuestionIndex == questions.count - 1 {
                showFinalData = true
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentQuestionIndex += 1
                }
            }
        } label: {
            if compact {
                // Number pill for day-picker
                Text(option)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            } else {
                // Full-width card row
                HStack {
                    Text(option)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Press Effect

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct questionaire_Previews: PreviewProvider {
    static var previews: some View {
        questionaire(firstName: "Daniel", lastName: "P", email: "test@email.com", password: "secret")
    }
}

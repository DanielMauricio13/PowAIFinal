//
//  createUserWindow.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/15/23.
//

import SwiftUI
import RiveRuntime

struct createUserWindow: View {
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State private var nextPart: Bool = false
    @State var email: String = ""
    @State private var wrongEmail = 0
    @State private var wrongPassword = 0
    @State var isDataSaved: Bool = false
    @State private var nameEmpty = 0
    @State private var lastNameEmpty = 0
    @State private var passwordTooShort = false   // NEW
    @State private var invalidEmailFormat = false  // NEW
    let button = RiveViewModel(fileName: "button")

    // MARK: - Helpers

    /// Basic RFC-5322-style regex — catches obvious typos like missing @, no TLD, spaces, etc.
    func isValidEmailFormat(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    var body: some View {
        if isDataSaved {
            questionaire(firstName: firstName, lastName: lastName, email: email, password: password)
        } else {
            NavigationView {
                ZStack {
                    Rectangle().fill(.black).ignoresSafeArea()
                    LinearGradient(colors: [Color.red.opacity(0.8), Color.cyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                    Circle().frame(width: 300).foregroundStyle(Color.blue.opacity(0.3)).blur(radius: 10).offset(x: -100, y: -150).animation(.snappy, value: 10)
                    Circle().frame(width: 300).foregroundStyle(Color.purple.opacity(0.3)).blur(radius: 10).offset(x: 150, y: 250)
                    RoundedRectangle(cornerRadius: 30, style: .continuous).frame(width: 500, height: 500).foregroundStyle(LinearGradient(colors: [Color.purple, .blue], startPoint: .top, endPoint: .bottom)).offset(x: 300, y: -200).blur(radius: 30).rotationEffect(.degrees(170))
                    RiveViewModel(fileName: "shapes").view().ignoresSafeArea().blur(radius: 30)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).frame(width: 350, height: 700)
                        VStack(spacing: 0) {
                            Spacer()
                            Text("Create Account")
                                .foregroundStyle(LinearGradient(colors: [.accentColor, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .font(.system(size: 35, weight: .bold))
                                .padding(.bottom, 20)

                            // First Name
                            TextField("First Name", text: $firstName)
                                .inputStyle(highlight: nameEmpty == 1)
                                .padding(.bottom, 2)
                            if nameEmpty == 1 {
                                ValidationLabel("Name cannot be empty")
                            }

                            // Last Name
                            TextField("Last Name", text: $lastName)
                                .inputStyle(highlight: lastNameEmpty == 1)
                                .padding(.top, 8).padding(.bottom, 2)
                            if lastNameEmpty == 1 {
                                ValidationLabel("Last name cannot be empty")
                            }

                            // Email
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .inputStyle(highlight: wrongEmail == 1 || invalidEmailFormat)
                                .padding(.top, 8).padding(.bottom, 2)
                            if invalidEmailFormat {
                                ValidationLabel("Enter a valid email address")
                            } else if wrongEmail == 1 {
                                ValidationLabel("Email already registered")
                            }

                            // Password
                            SecureField("Password (min. 8 characters)", text: $password)
                                .inputStyle(highlight: wrongPassword == 1 || passwordTooShort)
                                .padding(.top, 8).padding(.bottom, 2)
                            if passwordTooShort {
                                ValidationLabel("Password must be at least 8 characters")
                            }

                            // Confirm Password
                            SecureField("Confirm Password", text: $confirmPassword)
                                .inputStyle(highlight: wrongPassword == 1)
                                .padding(.top, 8).padding(.bottom, 2)
                            if wrongPassword == 1 {
                                ValidationLabel("Passwords do not match")
                            }

                            // Password strength indicator
                            if !password.isEmpty {
                                PasswordStrengthBar(password: password)
                                    .padding(.top, 6)
                            }

                            button.view()
                                .frame(width: 380, height: 48)
                                .overlay(
                                    Label("Create account", systemImage: "arrow.forward")
                                        .foregroundStyle(Color.black)
                                        .fontDesign(.rounded)
                                        .offset(x: 4, y: 4)
                                )
                                .padding(.top, 16)
                                .onTapGesture {
                                    button.play(animationName: "active")
                                    Task {
                                        self.email = email.uppercased()
                                        try await checkEmail(self.email)
                                    }
                                }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }

    // MARK: - Validation + Network

    func checkEmail(_ email: String) async throws {
        // Reset derived flags each attempt
        nameEmpty        = firstName.isEmpty ? 1 : 0
        lastNameEmpty    = lastName.isEmpty  ? 1 : 0
        invalidEmailFormat = false
        passwordTooShort   = false
        wrongPassword      = 0
        wrongEmail         = 0
        

        // 1. Name checks
        guard !firstName.isEmpty, !lastName.isEmpty else { return }

        // 2. Email format check — bail early before hitting the network
        guard isValidEmailFormat(email) else {
            invalidEmailFormat = true
            return
        }

        // 3. Password length
        guard password.count >= 8 else {
            passwordTooShort = true
            return
        }

        // 4. Password match
        guard password == confirmPassword else {
            wrongPassword = 1
            return
        }

        // 5. Network: check if email already registered
        guard let url = URL(string: "\(Constants.baseURL)\(EndPoints.users)checkEmail?email=\(email)") else {
            print("Bad URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { _, response, _ in
            if let http = response as? HTTPURLResponse {
                DispatchQueue.main.async {
                    switch http.statusCode {
                    case 200:
                        wrongEmail = 1   // already taken
                    default:
                        wrongEmail = 0
                        nextView()
                    }
                }
            }
        }
        task.resume()
    }

    func nextView() {
        if !firstName.isEmpty && !lastName.isEmpty {
            isDataSaved = true
        }
    }
}

// MARK: - Reusable subviews

private struct ValidationLabel: View {
    let message: String
    init(_ message: String) { self.message = message }
    var body: some View {
        Text(message)
            .font(.caption).bold()
            .foregroundStyle(Color.red)
            .fontDesign(.rounded)
            .frame(width: 300, alignment: .leading) // was maxWidth: .infinity
            .padding(.leading, 4)
    }
}

/// Thin bar that grades password strength: red → orange → green
private struct PasswordStrengthBar: View {
    let password: String

    private var strength: Int {
        var score = 0
        if password.count >= 8  { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        return score  // 0-5
    }

    private var label: String {
        switch strength {
        case 0...1: return "Weak"
        case 2...3: return "Fair"
        default:    return "Strong"
        }
    }

    private var color: Color {
        switch strength {
        case 0...1: return .red
        case 2...3: return .orange
        default:    return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.15)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * (CGFloat(strength) / 5.0), height: 6)
                        .animation(.spring(response: 0.4), value: strength)
                }
            }
            .frame(height: 6)
            Text(label)
                .font(.caption2).fontDesign(.rounded)
                .foregroundStyle(color)
        }
        .frame(width: 300)
    }
}

// MARK: - TextField style helper

private extension View {
    func inputStyle(highlight: Bool) -> some View {
        self
            .padding()
            .frame(width: 300, height: 50)
            .background(Color.black.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(highlight ? Color.red : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(.white)
            .font(.headline)
    }
}

struct createUserWindow_Previews: PreviewProvider {
    static var previews: some View {
        createUserWindow()
    }
}

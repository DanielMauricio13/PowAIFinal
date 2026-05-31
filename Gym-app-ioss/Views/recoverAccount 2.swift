//
//  recoverAccount 2.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/24/26.
//


import SwiftUI
import RiveRuntime

struct recoverAccount: View {

    // MARK: - State
    @Environment(\.dismiss) private var dismiss

    enum Step { case email, code, newPassword, success }
    @State private var step: Step = .email

    // Step 1
    @State private var email = ""
    @State private var emailError = ""
    @State private var isSending = false

    // Step 2
    @State private var codeDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedDigit: Int?
    @State private var codeError = ""
    @State private var isVerifying = false
    @State private var resendCooldown = 0
    @State private var resendTimer: Timer? = nil
    @State private var shakeTrigger = false

    // Step 3
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPw = false
    @State private var showConfirm = false
    @State private var passwordError = ""
    @State private var isResetting = false

    init(initialEmail: String = "") {
        _email = State(initialValue: initialEmail.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Computed
    private var enteredCode: String { codeDigits.joined() }
    private var recoveryEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
    private var passwordStrength: Int {
        var s = 0
        if newPassword.count >= 8 { s += 1 }
        if newPassword.range(of: "[A-Z]", options: .regularExpression) != nil { s += 1 }
        if newPassword.range(of: "[0-9]", options: .regularExpression) != nil { s += 1 }
        if newPassword.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { s += 1 }
        return s
    }
    private var strengthLabel: String {
        ["", "Weak", "Fair", "Strong", "Very strong"][min(passwordStrength, 4)]
    }
    private var strengthColor: Color {
        [.clear, .red, .orange, .green, .green][min(passwordStrength, 4)]
    }
    private var cardWidth: CGFloat { AdaptiveLayout.clampedWidth(350, horizontalPadding: 28) }
    private var contentWidth: CGFloat { AdaptiveLayout.clampedWidth(300, horizontalPadding: 52) }
    private var logoSize: CGFloat { AdaptiveLayout.scaled(38, compact: 32) }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background — matches LogInWindow exactly
            AppBackgroundView()

            Circle()
                .frame(width: 300)
                .foregroundStyle(Color.red.opacity(0.28))
                .blur(radius: 10)
                .offset(x: -100, y: -150)

            Circle()
                .frame(width: 300)
                .foregroundStyle(Color.orange.opacity(0.25))
                .blur(radius: 10)
                .offset(x: 150, y: 250)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .frame(
                    width: AdaptiveLayout.clampedWidth(500, horizontalPadding: -60),
                    height: AdaptiveLayout.clampedWidth(500, horizontalPadding: -60)
                )
                .foregroundStyle(
                    LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
                )
                .offset(x: 300, y: -200)
                .blur(radius: 30)
                .rotationEffect(.degrees(170))

            RiveViewModel(fileName: "shapes").view()
                .ignoresSafeArea()
                .blur(radius: 30)

            // Card
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .frame(width: cardWidth, height: cardHeight)

            VStack(spacing: 0) {
                // Logo
                Text("Pow AI")
                    .font(.system(size: logoSize, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .padding(.bottom, 2)

                // Step indicator dots
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .frame(width: stepIndex >= i ? 18 : 8, height: 4)
                            .foregroundStyle(
                                stepIndex > i
                                    ? LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                                    : stepIndex == i
                                        ? LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                            )
                            .animation(.spring(response: 0.3), value: stepIndex)
                    }
                }
                .padding(.bottom, 20)

                // Step content
                Group {
                    switch step {
                    case .email:        emailStep
                    case .code:         codeStep
                    case .newPassword:  newPasswordStep
                    case .success:      successStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.38, dampingFraction: 0.82), value: step)
            }
            .frame(width: contentWidth)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if step != .success {
                    Button {
                        if step == .email { dismiss() } else { goBack() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }

    // MARK: - Card height per step
    private var stepIndex: Int {
        switch step { case .email: 0; case .code: 1; case .newPassword: 2; case .success: 2 }
    }
    private var cardHeight: CGFloat {
        switch step {
        case .email:       AdaptiveLayout.scaled(340, compact: 330)
        case .code:        AdaptiveLayout.scaled(380, compact: 370)
        case .newPassword: AdaptiveLayout.scaled(420, compact: 408)
        case .success:     AdaptiveLayout.scaled(300, compact: 290)
        }
    }

    // MARK: - Step 1: Email
    private var emailStep: some View {
        VStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("Forgot password?")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                Text("We'll send a 6-digit code to your email.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            powTextField(placeholder: "Email address", text: $email, isSecure: false, isError: !emailError.isEmpty)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !emailError.isEmpty {
                Text(emailError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            powButton(label: "Send recovery code", isLoading: isSending) {
                Task { await handleSendCode() }
            }
        }
    }

    // MARK: - Step 2: Code
    private var codeStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("Check your inbox")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                Text("Sent to \(recoveryEmail)")
                    .font(.footnote)
                    .foregroundColor(.orange.opacity(0.85))
            }

            // Six digit boxes
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    digitBox(index: i)
                }
            }
            .modifier(ShakeEffect(trigger: shakeTrigger))

            if !codeError.isEmpty {
                Text(codeError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            powButton(label: "Verify code", isLoading: isVerifying) {
                Task { await handleVerifyCode() }
            }

            // Resend row
            HStack {
                Button {
                    Task { await handleResend() }
                } label: {
                    Text("Resend code")
                        .font(.caption)
                        .underline()
                        .foregroundColor(resendCooldown > 0 ? .white.opacity(0.3) : .white.opacity(0.7))
                }
                .disabled(resendCooldown > 0)

                Spacer()

                if resendCooldown > 0 {
                    Text("in \(resendCooldown)s")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }

    @ViewBuilder
    private func digitBox(index i: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            focusedDigit == i
                                ? LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.white.opacity(0.15), .white.opacity(0.15)], startPoint: .top, endPoint: .bottom),
                            lineWidth: focusedDigit == i ? 1.5 : 0.5
                        )
                )
                .frame(width: AdaptiveLayout.scaled(40, compact: 34), height: 48)

            TextField("", text: $codeDigits[i])
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: AdaptiveLayout.scaled(40, compact: 34), height: 48)
                .focused($focusedDigit, equals: i)
                .onChange(of: codeDigits[i]) { _, newVal in
                    let filtered = newVal.filter { $0.isNumber }
                    if filtered.count > 1 {
                        // handle paste
                        let digits = Array(filtered.prefix(6))
                        for j in 0..<min(digits.count, 6) {
                            codeDigits[j] = String(digits[j])
                        }
                        focusedDigit = min(digits.count, 5)
                    } else {
                        codeDigits[i] = String(filtered.prefix(1))
                        if !filtered.isEmpty && i < 5 { focusedDigit = i + 1 }
                    }
                    codeError = ""
                }
        }
    }

    // MARK: - Step 3: New password
    private var newPasswordStep: some View {
        VStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("Set new password")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                Text("Choose something strong.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
            }

            // New password field
            ZStack(alignment: .trailing) {
                powTextField(placeholder: "New password", text: $newPassword, isSecure: !showNewPw, isError: false)
                Button { showNewPw.toggle() } label: {
                    Image(systemName: showNewPw ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.trailing, 14)
                }
            }

            // Strength bar
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .frame(height: 3)
                            .foregroundColor(i < passwordStrength ? strengthColor : .white.opacity(0.15))
                            .animation(.easeInOut(duration: 0.2), value: passwordStrength)
                    }
                }
                if !newPassword.isEmpty {
                    Text(strengthLabel)
                        .font(.caption2)
                        .foregroundColor(strengthColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            // Confirm password field
            ZStack(alignment: .trailing) {
                powTextField(placeholder: "Confirm password", text: $confirmPassword, isSecure: !showConfirm, isError: !passwordError.isEmpty)
                Button { showConfirm.toggle() } label: {
                    Image(systemName: showConfirm ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.trailing, 14)
                }
            }

            if !passwordError.isEmpty {
                Text(passwordError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            powButton(label: "Reset password", isLoading: isResetting) {
                Task { await handleReset() }
            }
        }
    }

    // MARK: - Step 4: Success
    private var successStep: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.green.opacity(0.3), .green.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom))
            }
            VStack(spacing: 4) {
                Text("Password updated!")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                Text("You can now sign in with your new credentials.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            powButton(label: "Back to login", isLoading: false) {
                dismiss()
            }
        }
    }

    // MARK: - Reusable sub-views
    @ViewBuilder
    private func powTextField(placeholder: String, text: Binding<String>, isSecure: Bool, isError: Bool) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .foregroundColor(.white)
        .font(.headline)
        .padding()
        .frame(width: contentWidth, height: 50)
        .background(Color.black.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isError ? Color.red : Color.clear, lineWidth: 1)
        )
        .accentColor(.white)
    }

    @ViewBuilder
    private func powButton(label: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(label)
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            .frame(width: contentWidth, height: 50)
            .background(
                LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(10)
            .opacity(isLoading ? 0.7 : 1)
        }
        .disabled(isLoading)
    }

    // MARK: - Navigation helper
    private func goBack() {
        withAnimation {
            switch step {
            case .code:        step = .email
            case .newPassword: step = .code
            default:           break
            }
        }
    }

    // MARK: - API calls
    private func handleSendCode() async {
        emailError = ""
        let normalizedEmail = recoveryEmail
        guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            emailError = "Please enter a valid email address."
            return
        }
        email = normalizedEmail
        isSending = true
        defer { isSending = false }

        guard let url = URL(string: "\(Constants.baseURL)users/password-recovery") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["email": normalizedEmail])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            await MainActor.run {
                switch http.statusCode {
                case 200:
                    withAnimation { step = .code }
                    startResendTimer()
                case 404:
                    emailError = "No account found with this email."
                default:
                    emailError = "Something went wrong. Please try again."
                }
            }
        } catch {
            await MainActor.run { emailError = "Network error. Check your connection." }
        }
    }

    private func handleVerifyCode() async {
        codeError = ""
        guard enteredCode.count == 6 else {
            codeError = "Please enter all 6 digits."
            triggerShake()
            return
        }
        isVerifying = true
        defer { isVerifying = false }

        guard let url = URL(string: "\(Constants.baseURL)users/password-recovery/validate") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["email": recoveryEmail, "code": enteredCode])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            await MainActor.run {
                switch http.statusCode {
                case 200:
                    withAnimation { step = .newPassword }
                case 401:
                    codeError = "Invalid or expired code."
                    triggerShake()
                    codeDigits = Array(repeating: "", count: 6)
                    focusedDigit = 0
                default:
                    codeError = "Something went wrong. Please try again."
                }
            }
        } catch {
            await MainActor.run { codeError = "Network error. Check your connection." }
        }
    }

    private func handleResend() async {
        codeError = ""
        codeDigits = Array(repeating: "", count: 6)
        await handleSendCode()
        startResendTimer()
    }

    private func handleReset() async {
        passwordError = ""
        guard newPassword.count >= 8 else {
            passwordError = "Password must be at least 8 characters."
            return
        }
        guard newPassword == confirmPassword else {
            passwordError = "Passwords do not match."
            return
        }
        isResetting = true
        defer { isResetting = false }

        guard let url = URL(string: "\(Constants.baseURL)users/password-recovery/reset") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "email": recoveryEmail,
            "code": enteredCode,
            "newPassword": newPassword
        ])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            await MainActor.run {
                switch http.statusCode {
                case 200:
                    withAnimation { step = .success }
                case 401:
                    passwordError = "Session expired. Please start over."
                default:
                    passwordError = "Something went wrong. Please try again."
                }
            }
        } catch {
            await MainActor.run { passwordError = "Network error. Check your connection." }
        }
    }

    // MARK: - Helpers
    private func triggerShake() {
        shakeTrigger.toggle()
    }

    private func startResendTimer() {
        resendCooldown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                t.invalidate()
            }
        }
    }
}

// MARK: - Shake modifier
struct ShakeEffect: GeometryEffect {
    var trigger: Bool
    var animatableData: CGFloat = 0

    init(trigger: Bool) {
        self.trigger = trigger
        self.animatableData = trigger ? 1 : 0
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * 4) * 6
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

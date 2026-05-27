//
//  UpdateProfileViews.swift
//  Gym-app-ioss
//
//  Full update-profile flow:
//    UserSettings ──► UpdateProfileMenuView
//                          ├── UpdateEmailView
//                          └── UpdateFullProfileView ──► SaveRoutineConfirmView (alert)
//

import SwiftUI

// MARK: - Menu

struct UpdateProfileMenuView: View {
    var mainUser: User
    @Binding var isPresented: Bool

    @State private var destination: UpdateDestination? = nil

    enum UpdateDestination: Identifiable {
        case email, fullProfile
        var id: Self { self }
    }

    var body: some View {
        ZStack {
            gymBg
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.orange)
                    Text("Update Profile")
                        .font(.largeTitle.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                    Text("What would you like to change?")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 20)

                // Options
                VStack(spacing: 16) {
                    menuCard(
                        icon: "envelope.fill",
                        title: "Update Email",
                        subtitle: "Change your account email address",
                        accent: Color.orange
                    ) { destination = .email }

                    menuCard(
                        icon: "slider.horizontal.3",
                        title: "Update Full Profile",
                        subtitle: "Edit your personal info & fitness goals",
                        accent: Color(red: 1, green: 0.45, blue: 0.1)
                    ) { destination = .fullProfile }
                }

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .sheet(item: $destination) { dest in
            switch dest {
            case .email:
                UpdateEmailView(mainUser: mainUser, isPresented: Binding(
                    get: { destination != nil },
                    set: { if !$0 { destination = nil; isPresented = false } }
                ))
            case .fullProfile:
                UpdateFullProfileView(mainUser: mainUser, isPresented: Binding(
                    get: { destination != nil },
                    set: { if !$0 { destination = nil; isPresented = false } }
                ))
            }
        }
    }

    private func menuCard(icon: String, title: String, subtitle: String,
                          accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accent.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.footnote)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(accent.opacity(0.2), lineWidth: 1))
            )
        }
    }

    private var gymBg: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1),
                     Color(red: 0.2, green: 0.03, blue: 0.03)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Update Email

struct UpdateEmailView: View {
    var mainUser: User
    @Binding var isPresented: Bool

    @State private var newEmail: String = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            gymBg
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.orange)
                        Text("Update Email")
                            .font(.largeTitle.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 30)

                    // Current email display
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Current Email", systemImage: "lock.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(1)

                        Text(mainUser.email ?? "—")
                            .font(.body.monospaced())
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1))
                            )
                    }

                    // New email field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("New Email", systemImage: "envelope.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Color.orange.opacity(0.9))
                            .textCase(.uppercase)
                            .tracking(1)

                        TextField("", text: $newEmail, prompt:
                            Text("Enter new email address")
                                .foregroundStyle(.white.opacity(0.3))
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.4), lineWidth: 1))
                        )
                    }

                    // Error / Success
                    if let err = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(Color.red)
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(Color.red.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if showSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.green)
                            Text("Email updated successfully!")
                                .font(.footnote)
                                .foregroundStyle(Color.green.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Save button
                    Button {
                        Task { await submitEmailUpdate() }
                    } label: {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Email")
                                    .font(.headline.bold())
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(colors: [Color.orange, Color(red: 0.85, green: 0.3, blue: 0.1)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.orange.opacity(0.35), radius: 10, x: 0, y: 6)
                        .opacity(newEmail.isEmpty || isLoading ? 0.5 : 1.0)
                    }
                    .disabled(newEmail.isEmpty || isLoading)

                    Button { isPresented = false } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func submitEmailUpdate() async {
        errorMessage = nil
        showSuccess = false

        guard newEmail.contains("@"), newEmail.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return
        }

        guard let url = URL(string: "\(Constants.baseURL)users/email") else {
            errorMessage = "Could not build request URL."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            guard let token = AuthSession.getToken(), !token.isEmpty else {
                errorMessage = "Your session expired. Please sign in again."
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let body = ["email": newEmail.uppercased()]
            request.httpBody = try JSONEncoder().encode(body)

            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                errorMessage = "Server error. Please try again."
                return
            }
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                isPresented = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var gymBg: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1),
                     Color(red: 0.2, green: 0.03, blue: 0.03)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Double rounding helper

private extension Double {
    /// Rounds `self` to the nearest multiple of `nearest`.
    /// e.g. 72.3.rounded(toNearest: 0.5) → 72.5
    func rounded(toNearest nearest: Double) -> Double {
        (self / nearest).rounded() * nearest
    }
}


struct UpdateFullProfileView: View {
    var mainUser: User
    @Binding var isPresented: Bool

    // Profile fields — pre-filled from mainUser
    @State private var firstName: String
    @State private var lastName: String
    @State private var age: Int
    @State private var gender: String
    @State private var weight: Double
    @State private var weightUnit: String
    @State private var goal: String
    @State private var bodyStructure: String
    @State private var height: Double
    @State private var heightFt: Int
    @State private var heightIn: Int
    @State private var heightUnit: String
    @State private var numDays: Int
    @State private var numHours: String
    @State private var whereWork: String
    @State private var level: String

    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showRoutineConfirm = false

    // Picker options
    private let genders   = ["Male", "Female", "Other"]
    private let goals     = ["Lose weight", "Gain muscle", "Maintain weight", "Improve endurance"]
    private let bodies    = ["Ectomorph", "Mesomorph", "Endomorph"]
    private let locations = ["Home", "Gym", "Outdoors"]
    private let levels    = ["Beginner", "Intermediate", "Advanced"]
    private let hUnits    = ["cm", "ft"]
    private let wUnits    = ["kg", "lbs"]

    // MARK: - Unit conversion helpers

    /// Canonical storage value — always kg, regardless of the picker's displayed unit.
    private var weightInKg: Double {
        weightUnit == "lbs" ? weight / 2.20462 : weight
    }

    /// Canonical storage value — always cm, regardless of the picker's displayed unit.
    private var heightInCm: Double {
        heightUnit == "ft" ? Double(heightFt * 12 + heightIn) * 2.54 : height
    }

    /// Picker step values for the weight wheel, keyed by unit.
    private var weightPickerStride: (from: Double, through: Double, by: Double) {
        weightUnit == "kg"
            ? (from: 30,  through: 250, by: 0.5)
            : (from: 66,  through: 550, by: 1.0)
    }

    /// Called whenever the user flips the weight unit toggle.
    /// Converts `weight` in-place so the wheel snaps to the equivalent value.
    private func convertWeight(from old: String, to new: String) {
        guard old != new else { return }
        weight = old == "kg"
            ? (weight * 2.20462).rounded(toNearest: 1.0)   // kg → lbs
            : (weight / 2.20462).rounded(toNearest: 0.5)   // lbs → kg
    }

    /// Called whenever the user flips the height unit toggle.
    /// Converts between `height` (cm) and `heightFt`/`heightIn` (imperial) in-place.
    private func convertHeight(from old: String, to new: String) {
        guard old != new else { return }
        if old == "cm" {
            // cm → ft + in
            let totalInches = Int((height / 2.54).rounded())
            heightFt = max(3, min(8, totalInches / 12))
            heightIn = totalInches % 12
        } else {
            // ft + in → cm
            height = (Double(heightFt * 12 + heightIn) * 2.54).rounded()
        }
    }

    init(mainUser: User, isPresented: Binding<Bool>) {
        self.mainUser = mainUser
        self._isPresented = isPresented
        _firstName     = State(initialValue: mainUser.firstName )
        _lastName      = State(initialValue: mainUser.lastName )
        _age           = State(initialValue: mainUser.age ?? 25)
        _gender        = State(initialValue: mainUser.gender ?? "Male")
        _weight        = State(initialValue: Double(mainUser.weight ?? 70))
        _weightUnit    = State(initialValue: "kg")
        _goal          = State(initialValue: mainUser.goal ?? "Lose weight")
        _bodyStructure = State(initialValue: mainUser.bodyStructure ?? "Average")
        _height        = State(initialValue: Double(mainUser.height ?? 170))
        _heightFt      = State(initialValue: mainUser.heightFt ?? 5)
        _heightIn      = State(initialValue: mainUser.heightInc ?? 9)
        _heightUnit    = State(initialValue: "cm")
        _numDays       = State(initialValue: mainUser.numDays ?? 3)
        _numHours      = State(initialValue: String(mainUser.numHours ?? "1"))
        _whereWork     = State(initialValue: "Gym")
        _level         = State(initialValue: "Intermediate")
    }

    var body: some View {
        ZStack {
            gymBg
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 6) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.orange)
                        Text("Edit Profile")
                            .font(.largeTitle.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                        Text("Tap any field to edit")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.top, 30)

                    // ── Personal Info ──
                    sectionHeader("Personal Info", icon: "person.fill")

                    HStack(spacing: 12) {
                        profileField(label: "First Name", icon: "textformat") {
                            TextField("", text: $firstName, prompt: Text("First").foregroundStyle(.white.opacity(0.3)))
                                .foregroundStyle(.white)
                        }
                        profileField(label: "Last Name", icon: "textformat") {
                            TextField("", text: $lastName, prompt: Text("Last").foregroundStyle(.white.opacity(0.3)))
                                .foregroundStyle(.white)
                        }
                    }

                    HStack(spacing: 12) {
                        profileField(label: "Age", icon: "calendar") {
                            Picker("", selection: $age) {
                                ForEach(14...100, id: \.self) { Text("\($0) yrs").foregroundStyle(.white).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 80)
                            .clipped()
                        }
                        profileField(label: "Gender", icon: "person.2.fill") {
                            Picker("", selection: $gender) {
                                ForEach(genders, id: \.self) { Text($0).foregroundStyle(.white).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 80)
                            .clipped()
                        }
                    }

                    // ── Body Metrics ──
                    sectionHeader("Body Metrics", icon: "scalemass.fill")

                    HStack(spacing: 12) {
                        profileField(label: "Weight", icon: "scalemass") {
                            HStack {
                                let s = weightPickerStride
                                Picker("", selection: $weight) {
                                    ForEach(
                                        Array(stride(from: s.from, through: s.through, by: s.by)),
                                        id: \.self
                                    ) {
                                        Text(String(format: weightUnit == "kg" ? "%.1f" : "%.0f", $0))
                                            .foregroundStyle(.white)
                                            .tag($0)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 80)
                                .clipped()
                                Picker("", selection: $weightUnit) {
                                    ForEach(wUnits, id: \.self) { Text($0).foregroundStyle(.white).tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 50, height: 80)
                                .clipped()
                            }
                        }
                        .onChange(of: weightUnit) { old, new in convertWeight(from: old, to: new) }
                        profileField(label: "Body Type", icon: "person.crop.rectangle") {
                            Picker("", selection: $bodyStructure) {
                                ForEach(bodies, id: \.self) { Text($0).foregroundStyle(.white).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 80)
                            .clipped()
                        }
                    }

                    profileField(label: "Height", icon: "ruler.fill") {
                        HStack(spacing: 12) {
                            Picker("Unit", selection: $heightUnit) {
                                ForEach(hUnits, id: \.self) { Text($0).foregroundStyle(.white).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 100)
                            .onChange(of: heightUnit) { old, new in convertHeight(from: old, to: new) }

                            if heightUnit == "cm" {
                                Picker("", selection: $height) {
                                    ForEach(Array(stride(from: 100.0, through: 250.0, by: 1.0)), id: \.self) {
                                        Text(String(format: "%.0f cm", $0)).foregroundStyle(.white).tag($0)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 80)
                                .clipped()
                            } else {
                                HStack {
                                    Picker("ft", selection: $heightFt) {
                                        ForEach(3...8, id: \.self) { Text("\($0) ft").foregroundStyle(.white).tag($0) }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 80)
                                    .clipped()
                                    Picker("in", selection: $heightIn) {
                                        ForEach(0...11, id: \.self) { Text("\($0) in").foregroundStyle(.white).tag($0) }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 80)
                                    .clipped()
                                }
                            }
                        }
                    }

                    // ── Fitness Plan ──
                    sectionHeader("Fitness Plan", icon: "flame.fill")

                    profileField(label: "Goal", icon: "target") {
                        Picker("", selection: $goal) {
                            ForEach(goals, id: \.self) { Text($0).foregroundStyle(.white).tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 80)
                        .clipped()
                    }

                    HStack(spacing: 12) {
                        profileField(label: "Where you train", icon: "building.2.fill") {
                            Picker("", selection: $whereWork) {
                                ForEach(locations, id: \.self) { Text($0).foregroundStyle(.white).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 80)
                            .clipped()
                        }
                        profileField(label: "Level", icon: "chart.bar.fill") {
                            Picker("", selection: $level) {
                                ForEach(levels, id: \.self) { Text($0).foregroundStyle(.white).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 80)
                            .clipped()
                        }
                    }

                    HStack(spacing: 12) {
                        profileField(label: "Days / week", icon: "calendar.badge.clock") {
                            Picker("", selection: $numDays) {
                                ForEach(1...7, id: \.self) { Text("\($0) days").foregroundStyle(.white).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 80)
                            .clipped()
                        }
                        profileField(label: "Hours / session", icon: "clock.fill") {
                            Picker("", selection: $numHours) {
                                ForEach([0.5, 1.0, 1.5, 2.0, 2.5, 3.0], id: \.self) {
                                    Text(String(format: "%.1f h", $0)).foregroundStyle(.white).tag($0)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 80)
                            .clipped()
                        }
                    }

                    // Error
                    if let err = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                            Text(err).font(.footnote).foregroundStyle(.red.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Save
                    Button {
                        showRoutineConfirm = true
                    } label: {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Changes")
                                    .font(.headline.bold())
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(colors: [Color.orange, Color(red: 0.85, green: 0.3, blue: 0.1)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.orange.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .disabled(isLoading)

                    Button { isPresented = false } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        // ── Routine Confirm Sheet ──
        .confirmationDialog(
            "Update Workout Routine?",
            isPresented: $showRoutineConfirm,
            titleVisibility: .visible
        ) {
            Button("Keep my current routine") {
                Task { await saveProfileOnly() }
            }
            Button("Update profile & get new routine") {
                Task { await saveProfileAndRegenerate() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you want to keep your current workout plan or generate a new one based on your updated profile?")
        }
    }

    // MARK: - Sub-views

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.orange)
                .font(.footnote)
            Text(title.uppercased())
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(Color.orange.opacity(0.85))
            Spacer()
            Rectangle()
                .fill(Color.orange.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.top, 4)
    }

    private func profileField<Content: View>(label: String, icon: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(Color.orange.opacity(0.7))
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.55))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            content()
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
        }
    }

    // MARK: - API calls

    private func buildPayload() -> [String: Any] {
        // Always send canonical SI values (kg / cm) so the backend and Gemini
        // prompt stay consistent regardless of which display unit the user picked.
        let canonicalWeightKg  = weightInKg
        let canonicalHeightCm  = heightInCm
        let totalInches        = Int((canonicalHeightCm / 2.54).rounded())

        return [
            "firstName":     firstName,
            "lastName":      lastName,
            "age":           age,
            "gender":        gender,
            "weight":        canonicalWeightKg.rounded(toNearest: 0.1),
            "weightUnit":    "kg",
            "goal":          goal,
            "bodyStructure": bodyStructure,
            "height":        canonicalHeightCm.rounded(),
            "heightUnit":    "cm",
            "heightFt":      totalInches / 12,
            "heightIn":      totalInches % 12,
            "numDays":       numDays,
            "numHours":      numHours,
            "whereWork":     whereWork,
            "level":         level
        ]
    }

    private func saveProfileOnly() async {
        errorMessage = nil
        guard mainUser.id != nil,
              let url = URL(string: "\(Constants.baseURL)users/profile") else {
            errorMessage = "Could not build request URL."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.applyBearerToken()
            request.httpBody = try JSONSerialization.data(withJSONObject: buildPayload())
            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                errorMessage = "Server error. Please try again."
                return
            }
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveProfileAndRegenerate() async {
      
        errorMessage = nil
        guard mainUser.id != nil,
              let url = URL(string: "\(Constants.baseURL)users/profile/regenerate-workout") else {
            errorMessage = "Could not build request URL."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.applyBearerToken()
            request.httpBody = try JSONSerialization.data(withJSONObject: buildPayload())
            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                errorMessage = "Server error. Please try again."
                return
            }
            
            isPresented = false
            
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
    }

    private var gymBg: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1),
                     Color(red: 0.2, green: 0.03, blue: 0.03)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
   
}

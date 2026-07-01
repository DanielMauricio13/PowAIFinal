//
//  UserSettings.swift
//  Gym-app-ioss
//

import SwiftUI
import UIKit

enum AppBackgroundMode: String, CaseIterable, Identifiable {
    case defaultTheme = "Default"
    case solid = "Solid"
    case gradient = "Gradient"

    var id: String { rawValue }
}

struct StoredAppColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    var color: Color {
        Color(red: red, green: green, blue: blue).opacity(opacity)
    }

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    init(color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0

        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &opacity) {
            self.init(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(opacity))
        } else {
            self.init(red: 0.2, green: 0.03, blue: 0.03)
        }
    }
}

final class AppAppearanceManager: ObservableObject {
    static let shared = AppAppearanceManager()

    private enum Keys {
        static let mode = "appBackgroundMode"
        static let primaryColor = "appBackgroundPrimaryColor"
        static let secondaryColor = "appBackgroundSecondaryColor"
    }

    static let defaultPrimary = StoredAppColor(red: 0.0, green: 0.0, blue: 0.0)
    static let defaultMiddle = StoredAppColor(red: 0.08, green: 0.08, blue: 0.1)
    static let defaultSecondary = StoredAppColor(red: 0.2, green: 0.03, blue: 0.03)

    @Published var mode: AppBackgroundMode {
        didSet { save() }
    }

    @Published var primaryColor: StoredAppColor {
        didSet { save() }
    }

    @Published var secondaryColor: StoredAppColor {
        didSet { save() }
    }

    var backgroundColors: [Color] {
        switch mode {
        case .defaultTheme:
            return [
                Self.defaultPrimary.color,
                Self.defaultMiddle.color,
                Self.defaultSecondary.color
            ]
        case .solid:
            return [primaryColor.color, primaryColor.color]
        case .gradient:
            return [primaryColor.color, secondaryColor.color]
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        let savedMode = defaults.string(forKey: Keys.mode).flatMap(AppBackgroundMode.init(rawValue:))
        mode = savedMode ?? .defaultTheme
        primaryColor = Self.decodeColor(forKey: Keys.primaryColor) ?? Self.defaultPrimary
        secondaryColor = Self.decodeColor(forKey: Keys.secondaryColor) ?? Self.defaultSecondary
    }

    func apply(mode: AppBackgroundMode, primary: Color, secondary: Color) {
        self.mode = mode
        primaryColor = StoredAppColor(color: primary)
        secondaryColor = StoredAppColor(color: secondary)
    }

    func resetToDefault() {
        mode = .defaultTheme
        primaryColor = Self.defaultPrimary
        secondaryColor = Self.defaultSecondary
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(mode.rawValue, forKey: Keys.mode)
        Self.encode(primaryColor, forKey: Keys.primaryColor)
        Self.encode(secondaryColor, forKey: Keys.secondaryColor)
    }

    private static func encode(_ color: StoredAppColor, forKey key: String) {
        if let data = try? JSONEncoder().encode(color) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func decodeColor(forKey key: String) -> StoredAppColor? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StoredAppColor.self, from: data)
    }
}

struct AppBackgroundView: View {
    @ObservedObject private var appearance = AppAppearanceManager.shared

    var body: some View {
        LinearGradient(
            colors: appearance.backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

enum AdaptiveLayout {
    private static var sceneBounds: CGRect {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds }
            .first ?? CGRect(x: 0, y: 0, width: 390, height: 844)
    }

    static var screenWidth: CGFloat {
        sceneBounds.width
    }

    static var screenHeight: CGFloat {
        sceneBounds.height
    }

    static var isCompactPhone: Bool {
        screenWidth <= 390 || screenHeight <= 700
    }

    static func clampedWidth(_ ideal: CGFloat, horizontalPadding: CGFloat = 32) -> CGFloat {
        min(ideal, max(0, screenWidth - horizontalPadding))
    }

    static func clampedHeight(_ ideal: CGFloat, verticalPadding: CGFloat = 80) -> CGFloat {
        min(ideal, max(0, screenHeight - verticalPadding))
    }

    static func scaled(_ regular: CGFloat, compact: CGFloat) -> CGFloat {
        isCompactPhone ? compact : regular
    }
}

struct UserSettings: View {
    @Binding var persistenceManager: PersistenceManager
    @Binding var LogOut: Bool
    @State var wantsDelete: Bool = false
    @State private var showUpdateProfile: Bool = false
    @State private var showAppAppearance: Bool = false
    @State private var showLanguageSettings: Bool = false
    var mainUser: User
    var onUserUpdate: (User) -> Void = { _ in }
    var onWorkoutUpdate: (fullTraining) -> Void = { _ in }
    @State var userID: UUID = UUID()

    var body: some View {
        ZStack {
            gymBackground

            VStack(spacing: 22) {
                header

                if wantsDelete {
                    deleteAccountCard
                } else {
                    settingsCard
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 30)
        }
        .onAppear {
            userID = mainUser.id ?? UUID()
        }
        .sheet(isPresented: $showUpdateProfile) {
            UpdateProfileMenuView(
                mainUser: mainUser,
                isPresented: $showUpdateProfile,
                onUserUpdate: onUserUpdate,
                onWorkoutUpdate: onWorkoutUpdate
            )
        }
        .sheet(isPresented: $showAppAppearance) {
            AppAppearanceSettingsView(isPresented: $showAppAppearance)
        }
        .sheet(isPresented: $showLanguageSettings) {
            LanguageSettingsView(isPresented: $showLanguageSettings)
        }
    }

    private var gymBackground: some View {
        AppBackgroundView()
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .foregroundStyle(Color.orange)
                .font(.title2)

            Text("User Settings")
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.white)
        }
        .padding(.top, 10)
    }

    private var settingsCard: some View {
        VStack(spacing: 24) {
            Text("Control your profile and session")
                .foregroundStyle(Color.white.opacity(0.7))
                .font(.headline)

            // ── NEW: Update Profile ──
            actionButton(
                title: "Update Profile",
                systemImage: "pencil.circle.fill",
                background: LinearGradient(
                    colors: [Color(red: 0.15, green: 0.5, blue: 1.0),
                             Color(red: 0.05, green: 0.3, blue: 0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                showUpdateProfile = true
            }

            actionButton(
                title: "Change App",
                systemImage: "paintpalette.fill",
                background: LinearGradient(
                    colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                showAppAppearance = true
            }

            actionButton(
                title: "Language",
                systemImage: "globe",
                background: LinearGradient(
                    colors: [Color.green.opacity(0.9), Color.cyan.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                showLanguageSettings = true
            }

            supportLink

            actionButton(
                title: "Delete account",
                systemImage: "trash.fill",
                background: LinearGradient(
                    colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                wantsDelete = true
            }

            actionButton(
                title: "Log out",
                systemImage: "rectangle.portrait.and.arrow.right.fill",
                background: LinearGradient(
                    colors: [Color.orange, Color(red: 0.85, green: 0.3, blue: 0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                logout()
                LogOut = true
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var deleteAccountCard: some View {
        VStack(spacing: 22) {
            Text("Delete Account")
                .font(.title.bold())
                .foregroundStyle(Color.red)

            Text("This action cannot be undone. Are you sure you want to delete your account?")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.85))

            actionButton(
                title: "Confirm delete",
                systemImage: "exclamationmark.triangle.fill",
                background: LinearGradient(
                    colors: [Color.red, Color(red: 0.7, green: 0, blue: 0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                Task {
                    try await delete()
                    logout()
                    LogOut = true
                }
            }

            actionButton(
                title: "Cancel",
                systemImage: "arrow.uturn.backward.circle.fill",
                background: LinearGradient(
                    colors: [Color.gray.opacity(0.8), Color.black.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ) {
                wantsDelete = false
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
            )
        )
    }

    private var supportLink: some View {
        Link(destination: Constants.supportURL) {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.cyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Need help?")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.white)
                    Text("Visit powai.net for support")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.62))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.cyan.opacity(0.28), lineWidth: 1)
                    )
            )
        }
    }

    private func actionButton(title: String, systemImage: String,
                               background: LinearGradient,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(LocalizedStringKey(title))
                    .font(.headline.bold())
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 6)
        }
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject( forKey: "email")
        HealthManager.shared.calories = 0
        HealthManager.shared.protein = 0
        HealthManager.shared.carbs = 0
        HealthManager.shared.sugars = 0
        persistenceManager.clearItems()
    }

    func delete() async throws {
        guard let url = URL(string: "\(Constants.baseURL)users/me") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethods.DELETE.rawValue
        request.applyBearerToken()
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw HttpEroor.BadResponse
        }
    }
}

struct AppAppearanceSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var appearance = AppAppearanceManager.shared

    @State private var selectedMode: AppBackgroundMode = .defaultTheme
    @State private var primaryColor: Color = AppAppearanceManager.defaultPrimary.color
    @State private var secondaryColor: Color = AppAppearanceManager.defaultSecondary.color

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.orange)
                        Text("Change App")
                            .font(.largeTitle.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                        Text("Choose a background for the app")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 30)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Background")
                            .font(.caption.bold())
                            .tracking(1.5)
                            .foregroundStyle(Color.orange.opacity(0.85))

                        Picker("Background", selection: $selectedMode) {
                            ForEach(AppBackgroundMode.allCases) { mode in
                                Text(LocalizedStringKey(mode.rawValue)).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        ColorPicker("Primary color", selection: $primaryColor, supportsOpacity: false)
                            .foregroundStyle(.white)
                            .disabled(selectedMode == .defaultTheme)

                        if selectedMode == .gradient {
                            ColorPicker("Gradient color", selection: $secondaryColor, supportsOpacity: false)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )

                    previewCard

                    Button {
                        appearance.apply(
                            mode: selectedMode,
                            primary: primaryColor,
                            secondary: selectedMode == .solid ? primaryColor : secondaryColor
                        )
                        isPresented = false
                    } label: {
                        Label("Save Background", systemImage: "checkmark.circle.fill")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(colors: [Color.orange, Color(red: 0.85, green: 0.3, blue: 0.1)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        appearance.resetToDefault()
                        loadCurrentAppearance()
                    } label: {
                        Label("Reset Default", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button { isPresented = false } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear(perform: loadCurrentAppearance)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(Color.orange.opacity(0.85))

            RoundedRectangle(cornerRadius: 18)
                .fill(previewStyle)
                .frame(height: 150)
                .overlay(
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PowAI")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        Text(LocalizedStringKey(selectedMode.rawValue))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(18)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
        }
    }

    private var previewStyle: AnyShapeStyle {
        switch selectedMode {
        case .defaultTheme:
            return AnyShapeStyle(LinearGradient(
                colors: AppAppearanceManager.shared.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        case .solid:
            return AnyShapeStyle(primaryColor)
        case .gradient:
            return AnyShapeStyle(LinearGradient(
                colors: [primaryColor, secondaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
    }

    private func loadCurrentAppearance() {
        selectedMode = appearance.mode
        primaryColor = appearance.primaryColor.color
        secondaryColor = appearance.secondaryColor.color
    }
}

struct LanguageSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @State private var selectedLanguage: AppLanguage = AppLanguageManager.shared.selectedLanguage

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.green)
                    Text("Language")
                        .font(.largeTitle.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                    Text("Choose the language for the app")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)

                VStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            selectedLanguage = language
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedLanguage == language ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedLanguage == language ? Color.green : Color.white.opacity(0.45))
                                Text(language.titleKey)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(selectedLanguage == language ? 0.12 : 0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedLanguage == language ? Color.green.opacity(0.55) : Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }

                Spacer()

                Button {
                    languageManager.apply(selectedLanguage)
                    isPresented = false
                } label: {
                    Label("Save Language", systemImage: "checkmark.circle.fill")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(colors: [Color.green, Color.cyan],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { isPresented = false } label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .onAppear {
            selectedLanguage = languageManager.selectedLanguage
        }
    }
}

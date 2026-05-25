//
//  UserSettings.swift
//  Gym-app-ioss
//

import SwiftUI

struct UserSettings: View {
    @Binding var persistenceManager: PersistenceManager
    @Binding var LogOut: Bool
    @State var wantsDelete: Bool = false
    @State private var showUpdateProfile: Bool = false
    var mainUser: User
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
            UpdateProfileMenuView(mainUser: mainUser, isPresented: $showUpdateProfile)
        }
    }

    private var gymBackground: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1),
                     Color(red: 0.2, green: 0.03, blue: 0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
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

    private func actionButton(title: String, systemImage: String,
                               background: LinearGradient,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(title)
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
        HealthManager.shared.calories = 0
        HealthManager.shared.protein = 0
        HealthManager.shared.carbs = 0
        HealthManager.shared.sugars = 0
        persistenceManager.clearItems()
    }

    func delete() async throws {
        guard let url = URL(string: "\(Constants.baseURL)users/\(userID)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethods.DELETE.rawValue
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw HttpEroor.BadResponse
        }
    }
}

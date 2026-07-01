//
//  ContentView.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/15/23.
//

import SwiftUI
import RiveRuntime


struct LogInWindow: View {
    
    @EnvironmentObject var healthManager: HealthManager
    @State private var password = ""
    @State private var wrongUsername = 0
    @State private var wrongPassword = 0
    @State private var userFound: Bool = false
    @State private var isAuthenticated = Self.hasSavedSession()
    @State private var username = UserDefaults.standard.string(forKey: "username") ?? ""

    private var cardWidth: CGFloat { AdaptiveLayout.clampedWidth(350, horizontalPadding: 28) }
    private var fieldWidth: CGFloat { AdaptiveLayout.clampedWidth(300, horizontalPadding: 52) }
    private var cardHeight: CGFloat { AdaptiveLayout.scaled(350, compact: 330) }
    private var titleSize: CGFloat { AdaptiveLayout.scaled(48, compact: 40) }

    private static func hasSavedSession() -> Bool {
        UserDefaults.standard.bool(forKey: "isAuthenticated") &&
        AuthSession.getToken()?.isEmpty == false
    }

    private func clearSavedSessionForSignup() {
        AuthSession.clearToken()
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "email")
        isAuthenticated = false
        userFound = false
    }
    
    var body: some View {
        
        if userFound {
            
            MainWindow(email: username)
            
        } else if isAuthenticated {
            MainWindow(email: username)
        } else {
            NavigationView {
                ZStack {
                    AppBackgroundView()
//                   
//                    Circle().scale(1.7).foregroundColor(.white.opacity(0.4))
//                    Circle().scale(1.35).foregroundColor(.red)
//                    Circle().scale(1).foregroundColor(.black)
//                    Circle().scale(1).foregroundColor(.white.opacity(0.4))
//                    Circle().scale(1).foregroundColor(.black.opacity(0.7))
                    Circle().frame(width: 300).foregroundStyle(Color.red.opacity(0.28)).blur(radius: 10).offset(x: -100, y: -150).animation(.bouncy, value: 10)
                    Circle().frame(width: 300).foregroundStyle(Color.orange.opacity(0.25)).blur(radius: 10).offset(x: 150, y: 250)
                    RoundedRectangle(cornerRadius: 30,style: .continuous).frame(width: AdaptiveLayout.clampedWidth(500, horizontalPadding: -60),height: AdaptiveLayout.clampedWidth(500, horizontalPadding: -60)).foregroundStyle(LinearGradient(colors: [Color.red, .orange], startPoint: .top, endPoint: .bottom)).offset(x:300,y: -200).blur(radius: 30).rotationEffect(.degrees(170))
                    RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).frame(width: cardWidth, height: cardHeight)
                    RiveViewModel(fileName: "shapes").view().ignoresSafeArea().blur(radius: 30)
                    VStack {
                        Text("Pow AI").font(.system(size: titleSize,weight: .bold,design: .rounded)).foregroundStyle(LinearGradient(colors: [.orange,.red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("Train harder. Recover smarter.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, 12)
                        TextField("Email", text: $username).padding().frame(width: fieldWidth, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10).border(.red, width: CGFloat(wrongUsername)).foregroundColor(.white).font(.headline)
                        SecureField("Password", text: $password).foregroundStyle(Color.white).padding().frame(width: fieldWidth, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10).border(.red, width: CGFloat(wrongPassword)).accentColor(.white).foregroundColor(.white).font(.headline)
                        if wrongUsername == 1 {
                            Text("Wrong email or password!")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                        NavigationLink(destination: recoverAccount(initialEmail: username)) {
                            Text("Forgot password?")
                                .font(.footnote.weight(.semibold))
                                .underline()
                                .foregroundColor(.white.opacity(0.82))
                        }
                        .padding(.top, wrongUsername == 1 ? 2 : 8)
                        Button {
                            self.username = username.uppercased()
                            authenticateUser(username, password)
                        } label: {
                            Text("Log In").padding().foregroundColor(.white).frame(width: fieldWidth, height: 50).background(LinearGradient(colors: [.red,.orange], startPoint: .leading, endPoint: .trailing)).cornerRadius(10)
                        }
                        
                        NavigationLink(destination: createUserWindow()) {
                            Text("New? Create Account").foregroundColor(.white)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            clearSavedSessionForSignup()
                        })
                        .padding(.top).navigationBarBackButtonHidden()
                    }
                }.navigationBarBackButtonHidden()
            }
            .navigationBarBackButtonHidden()
            .onAppear {
                isAuthenticated = Self.hasSavedSession()
            }
            
        }
    }
    
    func authenticateUser(_ user: String, _ password: String) {
        
        guard let url = URL(string: "\(Constants.baseURL)login") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": user, "password": password])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("Login request failed: \(error)")
                return
            }

            guard let response = response as? HTTPURLResponse else { return }

            switch response.statusCode {
            case 200:
                let token = authToken(from: data)
                DispatchQueue.main.async {
                    if let token {
                        AuthSession.saveToken(token)
                        PushNotificationRegistrar.uploadStoredDeviceTokenIfPossible()
                    }
                    UserDefaults.standard.set(true, forKey: "isAuthenticated")
                    UserDefaults.standard.set(username, forKey: "username")
                    UserDefaults.standard.set(username, forKey: "email")
                    isAuthenticated = true
                    userFound = true
                    wrongPassword = 0
                    wrongUsername = 0
                }

            case 401, 404:
                print("Credentials do not match")
                DispatchQueue.main.async {
                    wrongPassword = 1
                    wrongUsername = 1
                }

            default:
                print("Unknown response status: \(response.statusCode)")
            }
        }
        task.resume()
    }

    private func authToken(from data: Data?) -> String? {
        guard let data else { return nil }
        if let response = try? JSONDecoder().decode([String: String].self, from: data),
           let token = response["token"] ?? response["jwt"],
           !token.isEmpty {
            return token
        }
        let token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return token?.isEmpty == false ? token : nil
    }
    
}
struct LogInWindow_Previews: PreviewProvider {
    static var previews: some View {
        LogInWindow()
    }
}

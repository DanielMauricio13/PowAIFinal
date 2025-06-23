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
    @State private var isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    @State private var username = UserDefaults.standard.string(forKey: "username") ?? ""
    
    var body: some View {
        
        if userFound {
            
            MainWindow(email: username)
            
        } else if isAuthenticated {
            MainWindow(email: username)
        } else {
            NavigationView {
                ZStack {
                    LinearGradient(colors: [Color.cyan.opacity(0.7),Color.purple.opacity(0.7)],startPoint: .topLeading,endPoint: .bottomTrailing).ignoresSafeArea()
//                   
//                    Circle().scale(1.7).foregroundColor(.white.opacity(0.4))
//                    Circle().scale(1.35).foregroundColor(.red)
//                    Circle().scale(1).foregroundColor(.black)
//                    Circle().scale(1).foregroundColor(.white.opacity(0.4))
//                    Circle().scale(1).foregroundColor(.black.opacity(0.7))
                    Circle().frame(width: 300).foregroundStyle(Color.blue.opacity(0.3)).blur(radius: 10).offset(x: -100, y: -150).animation(.bouncy, value: 10)
                    Circle().frame(width: 300).foregroundStyle(Color.purple.opacity(0.3)).blur(radius: 10).offset(x: 150, y: 250)
                    RoundedRectangle(cornerRadius: 30,style: .continuous).frame(width: 500,height: 500).foregroundStyle(LinearGradient(colors: [Color.purple, .mint], startPoint: .top, endPoint: .bottom)).offset(x:300,y: -200).blur(radius: 30).rotationEffect(.degrees(170))
                    RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).frame(width: 350, height:350)
                    RiveViewModel(fileName: "shapes").view().ignoresSafeArea().blur(radius: 30)
                    VStack {
                        Text("Pow AI").font(.system(size: 48,weight: .bold,design: .rounded)).foregroundStyle(LinearGradient(colors: [.accentColor,.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        TextField("Email", text: $username).padding().frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10).border(.red, width: CGFloat(wrongUsername)).foregroundColor(.white).font(.headline)
                        SecureField("Password", text: $password).foregroundStyle(Color.white).padding().frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10).border(.red, width: CGFloat(wrongPassword)).accentColor(.white).foregroundColor(.white).font(.headline)
                        if wrongUsername == 1 {
                            NavigationLink(destination: createUserWindow()) {
                                Text("Wrong email or password! Recover?").underline().foregroundColor(.red)
                            }.padding(.top)
                        }
                        Button {
                            self.username = username.uppercased()
                            authenticateUser(username, password)
                        } label: {
                            Text("Log In").padding().foregroundColor(.white).frame(width: 300, height: 50).background(Color.blue).cornerRadius(10)
                        }
                        
                        NavigationLink(destination: createUserWindow()) {
                            Text("New? Create Account").foregroundColor(.white)
                        }.padding(.top).navigationBarBackButtonHidden()
                    }
                }.navigationBarBackButtonHidden()
            }.navigationBarBackButtonHidden()
            
        }
    }
    
    func authenticateUser(_ user: String, _ password: String) {
        
        guard let url = URL(string: "\(Constants.baseURL)login?email=\(user)&password=\(password)") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // or "GET" if your endpoint expects GET method
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 200:
                    
                    
                    userFound = true
                                    isAuthenticated = true
                                    UserDefaults.standard.set(true, forKey: "isAuthenticated")
                                    UserDefaults.standard.set(username, forKey: "username")

                                    if let data = data, let token = String(data: data, encoding: .utf8) {
                                        // Store the token securely
                                        UserDefaults.standard.set(token, forKey: "jwtToken")
                                    }

                    
                case 401, 404:
                    print("Credentials do not match")
                    wrongPassword = 1
                    wrongUsername = 1
                default:
                    print("Unknown response status: \(response.statusCode)")
                }
            }
        }
        task.resume()
    }
    
}
struct LogInWindow_Previews: PreviewProvider {
    static var previews: some View {
        LogInWindow()
    }
}

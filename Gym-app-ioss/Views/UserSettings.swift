//
//  UserSettings.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/13/24.
//

import SwiftUI

struct UserSettings: View {
    @Binding  var persistenceManager: PersistenceManager
    @Binding var LogOut: Bool
    @State var wantsDelete:Bool = false
    var mainUser: User
    @State var userID: UUID = UUID()
    var body: some View {
        if wantsDelete{
            VStack{
                Text("Delete Account").fontDesign(.rounded).font(.largeTitle).foregroundStyle(Color.red)
                Spacer()
                Text("This action cannot be undone. Are you sure you want to delete your account?")
                Spacer()
                Button{
                    Task{
                       try await delete()
                        logout()
                        LogOut = true
                    }
                   
                }label: {
                    Text("Delete").font(.title3).foregroundStyle(Color.white).background(RoundedRectangle(cornerRadius: 90).foregroundStyle(Color.red).frame(width: 150, height: 50) ).padding(.bottom)
                }
                Spacer()
                
                
            }.onAppear{
                userID = mainUser.id ?? UUID()
            }
        }else{
            VStack{
                Text("User Settings").font(.largeTitle).foregroundStyle(Color.white).bold().fontDesign(.rounded)
                Spacer()
                Button{
                    wantsDelete = true
                }label: {
                    Text("Delete account").font(.title3).foregroundStyle(Color.white).background(RoundedRectangle(cornerRadius: 90).foregroundStyle(Color.red).frame(width: 150, height: 50) ).padding(.bottom)
                }
                Spacer()
                Button{
                    logout()
                    LogOut = true
                }label: {
                    Text("Log out").font(.title3).foregroundStyle(Color.white).background(RoundedRectangle(cornerRadius: 90).foregroundStyle(Color.red).frame(width: 150, height: 50) ).padding(.bottom)
                }
              
              
                
                Spacer()
                
            }
        }
    }
    func logout()->Void {
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "username")
        HealthManager.shared.calories = 0
        HealthManager.shared.protein = 0
        HealthManager.shared.carbs = 0
        HealthManager.shared.sugars = 0
        persistenceManager.clearItems()
    }
    func delete() async throws {
        
        guard let url = URL(string: "\(Constants.baseURL)users/\(userID)") else {
            return
        }
        print(url)
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethods.DELETE.rawValue
        print(request)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw HttpEroor.BadResponse
        }
    }
      
    
}


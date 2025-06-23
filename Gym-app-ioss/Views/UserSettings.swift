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
    var body: some View {
        if wantsDelete{
            VStack{
                Text("Delete Account").fontDesign(.rounded).font(.largeTitle).foregroundStyle(Color.red)
                Spacer()
                Text("This action cannot be undone. Are you sure you want to delete your account?")
                Spacer()
                Button{
                   
                }label: {
                    Text("Delete").font(.title3).foregroundStyle(Color.white).background(RoundedRectangle(cornerRadius: 90).foregroundStyle(Color.red).frame(width: 150, height: 50) ).padding(.bottom)
                }
                Spacer()
                
                
            }
        }else{
            VStack{
                Text("User Settings").font(.largeTitle).foregroundStyle(Color.white).bold().fontDesign(.rounded)
                Spacer()
                Button{
                    logout()
                    LogOut = true
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
    
      
    
}


//
//  MainWindow2.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 9/29/23.
//

import SwiftUI

struct MainWindow2: View {
 var mainUser:User?
    
    
    var userFullWork: fullTraining?
    @State var buttomPressed:Bool = false
    
    
    var body: some View {
        if buttomPressed {
            ExcerciseWindow(mainUser: mainUser,userFullWork: self.userFullWork)
        }
        else{ ZStack {
            LinearGradient(colors: [Color.black.opacity(0.7),Color.red.opacity(0.7)],startPoint: .topLeading,endPoint: .bottomTrailing).ignoresSafeArea()
                        
            VStack {
                
                Text("Welcome \(mainUser?.firstName ?? "User")")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Spacer().frame(height: 150)
                Button{
                    buttomPressed = true
                }
            label:{
                (Text("Begin")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                    .foregroundColor(.white)
                    .frame(width: 150, height: 70)
                    .background(Color.red)
                    .cornerRadius(10)
                )
            }
                Spacer().frame(height:60)
                
                
                
            }
        }
        }
           
    }
    

    
}

#Preview {
    MainWindow2()
}

//
//  ExcerciseWindow.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/8/24.
//

import SwiftUI

import RiveRuntime
struct ExcerciseWindow: View {
    
    var mainUser: User?
    @State var whichWin: Int = 0
    @State var caloriesToday: Int = 0
    var userFullWork: fullTraining?
    @State var persistenceManager = PersistenceManager()
    @State var LogOut: Bool = false
    @State var exToday: String = ""
    @State var counts: Int?
    var body: some View {
        if LogOut {
            LogInWindow()
        }
        
       
        else{
            NavigationView {
                ZStack{
                    Circle().frame(width: 300).foregroundStyle(Color.blue.opacity(0.3)).blur(radius: 10).offset(x: -100, y: 150).animation(.bouncy, value: 2)
                    Circle().frame(width: 300).foregroundStyle(Color.green.opacity(0.3)).blur(radius: 10).offset(x: 150, y: -250).animation(.bouncy, value: 10)
                    Circle().frame(width: 300).foregroundStyle(LinearGradient(colors: [Color.purple, .mint], startPoint: .top, endPoint: .bottom)).blur(radius: 10).offset(x: 150, y: -270).animation(.bouncy, value: 10)
                    RiveViewModel(fileName: "shapes").view().ignoresSafeArea().blur(radius: 30).ignoresSafeArea()
                    VStack {
                        
                        if (exToday != "" && whichWin == 0){
                            WorkOutWindow(mainUser: self.mainUser, userFullWork: self.userFullWork, exToday: $exToday)
                        }
                        else if( whichWin == 0 ){
                            FisrtWindow(mainUser: self.mainUser,userFullWork: self.userFullWork, viewModel: ListViewModel(items: []), viewModel2: ListViewModel(items: []), exToday: $exToday  )
                        }
                        else if(whichWin == 1){
                            NutritionView( viewModel: ListViewModel(items: []), viewModel2: ListViewModel(items: []), persistenceManager: $persistenceManager)
                        }
                        else if(whichWin == 2){
                            Calories(mainUser: mainUser)
                        }
                        else if (whichWin == 3){
                            UserSettings(persistenceManager: $persistenceManager, LogOut: $LogOut)
                        }
                        Spacer()
                        
                        // Sticky navigation bar
                        HStack {
                            Spacer()
                            Button(action: {whichWin = 0}) {
                                Image(systemName: "house")
                                    .padding()
                                    .foregroundColor(whichWin == 0 ? Color.cyan :Color.white)
                                    .background(Color.black)
                                    .cornerRadius(10)
                            }
                            
                            Spacer()
                            Button(action: {whichWin = 1}) {
                                Image(systemName: "leaf")
                                    .padding()
                                    .foregroundColor(whichWin == 1 ? Color .green :Color.white)
                                    .background(Color.black)
                                    .cornerRadius(10)
                            }
                            
                            Spacer()
                            Button(action: {whichWin = 2}) {
                                Image(systemName: "flame")
                                    .padding()
                                    .foregroundColor(whichWin == 2 ? Color .red :Color.white)
                                    .background(Color.black)
                                    .cornerRadius(10)
                            }
                            
                            Spacer()
                            
                            
                            
                            Button(action: {
                                whichWin = 3
                            }) {
                                Image(systemName: "gear")
                                    .padding()
                                    .foregroundColor(whichWin == 3 ? Color .orange :Color.white)
                                    .background(Color.black)
                                    .cornerRadius(10)
                            }
                            
                            
                            
                            Spacer()
                            
                        }
                        .padding()
                        .frame(height: 70) // Adjust the height of the navigation bar as needed
                        .background(RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
                        .edgesIgnoringSafeArea(.bottom) // Extend the navigation bar to the bottom
                    }
                }
                .background( LinearGradient(colors: [Color.cyan.opacity(0.7),Color.black.opacity(0.7)],startPoint: .topLeading,endPoint: .bottomTrailing).ignoresSafeArea()) // Background color for the main content
                
                .navigationBarHidden(true) // Hide the default navigation bar
            }.onAppear{
                counts = userFullWork?.userExcersises.workout_plan.count
            }
        }
            }
  

    
}
#Preview {
    ExcerciseWindow()
}

//
//  createUserWindow.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/15/23.
//

import SwiftUI
import RiveRuntime

struct createUserWindow: View {
    @State var firstName: String = ""
    @State var lastName:String = ""
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State private var nextPart: Bool = false
  @State  var email: String = ""
    @State private var wrongEmail = 0
    @State private var wrongPassword = 0
    @State var isDataSaved: Bool = false
    @State private var nameEmpty = 0
    @State private var lastNameEmpty = 0
    let button = RiveViewModel(fileName: "button")
    

    var body: some View {
        if isDataSaved{
            questionaire(firstName: firstName, lastName: lastName, email: email, password: password)
        }
        else {
            NavigationView{
                ZStack{
                    Rectangle().fill(.black).ignoresSafeArea()
                    LinearGradient(colors: [Color.red.opacity(0.8),Color.cyan.opacity(0.2)],startPoint: .topLeading,endPoint: .bottomTrailing).ignoresSafeArea()
                    Circle().frame(width: 300).foregroundStyle(Color.blue.opacity(0.3)).blur(radius: 10).offset(x: -100, y: -150).animation(.snappy, value: 10)
                    Circle().frame(width: 300).foregroundStyle(Color.purple.opacity(0.3)).blur(radius: 10).offset(x: 150, y: 250)
                    RoundedRectangle(cornerRadius: 30,style: .continuous).frame(width: 500,height: 500).foregroundStyle(LinearGradient(colors: [Color.purple, .blue], startPoint: .top, endPoint: .bottom)).offset(x:300,y: -200).blur(radius: 30).rotationEffect(.degrees(170))
                    RiveViewModel(fileName: "shapes").view().ignoresSafeArea().blur(radius: 30)
                    ZStack{
                        RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).frame(width: 350, height:650)
                        VStack{
                            Spacer()
                            Text("Create Account").foregroundStyle(LinearGradient(colors: [.accentColor,.purple], startPoint: .topLeading, endPoint: .bottomTrailing)).font(.system(size: 35, weight: .bold, design: .default))
                            TextField("First Name", text: $firstName).padding().frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10).border(.red, width: CGFloat(nameEmpty)).foregroundColor(.white).font(.headline).padding(.top)
                            if nameEmpty == 1{
                                Text("Name cannot be empty").bold().foregroundStyle(Color.red).fontDesign(.rounded)
                            }
                            
                            TextField("Last Name", text: $lastName).padding().frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10).border(.red, width: CGFloat(lastNameEmpty)).foregroundColor(.white).font(.headline)
                            if lastNameEmpty == 1{
                                Text("Name cannot be empty").bold().foregroundStyle(Color.red).fontDesign(.rounded)
                            }
                            
                            TextField("Email", text: $email).padding().frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10).border(.red, width: CGFloat(wrongEmail)).foregroundColor(.white).font(.headline) .padding()
                            if wrongEmail == 1 {
                                Text("Email already registered or is empty").foregroundStyle(Color.red).bold().fontDesign(.rounded)
                            }
                            SecureField("Password", text: $password).foregroundStyle(Color.white).padding().frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10).border(.red, width: CGFloat(wrongPassword)).accentColor(.white).foregroundColor(.white).font(.headline)
                            
                            SecureField("Confirm password", text: $confirmPassword).foregroundStyle(Color.white).padding().frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(10).border(.red, width: CGFloat(wrongPassword)).accentColor(.white).foregroundColor(.white).font(.headline)
                                if wrongPassword == 1 {
                                    Text("Passwords do not match").foregroundStyle(Color.red).fontDesign(.rounded).bold()
                                }
                           
                           
                            button.view().frame(width:  380, height: 48).overlay(Label("Create account", systemImage: "arrow.forward").foregroundStyle(Color.black).fontDesign(.rounded).offset(x:4, y:4)).onTapGesture {
                                button.play(animationName: "active")
                                Task{
                                    self.email = email.uppercased()
                                    try await checkEmail(self.email)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    func checkEmail(_ email: String) async throws -> Void {

       
        
        guard let url = URL(string: "\(Constants.baseURL)\(EndPoints.users)checkEmail?email=\(email)") else {
             print("error")
            return
        }
        print(url)
        if self.firstName == ""{
            self.nameEmpty = 1
        }
        if self.lastName == ""{
            self.lastNameEmpty = 1
        }
        
        if password != confirmPassword || password == "" {
            wrongPassword = 1
        }else{
            wrongPassword = 0
        }
        if email == "" {
            self.wrongEmail = 1
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 200:
                    wrongEmail = 1
                    print("found")
                case 401:
                    print("401")
                    wrongEmail = 0
                default:
                    print("unknown")
                    wrongEmail = 0
                }

            }
       
            
            if wrongEmail == 0 && wrongPassword == 0{
                nextView()
            }
        }
        
        task.resume()
        return
    }
    func nextView(){
        if firstName != "" && lastName != "" {
            isDataSaved = true
        }
    }
}

struct createUserWindow_Previews: PreviewProvider {
    static var previews: some View {
        createUserWindow()
    }
}

struct BasicInformationRecollection: View{
    var body: some View{
        Text("collect basic info")
    }
}

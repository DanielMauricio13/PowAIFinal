//
//  finalData.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/15/23.
//

import SwiftUI
import RiveRuntime
struct finalData: View {
    let firstName: String
    let lastName:String
    @State var age: Int = 0
    var gender: String
    @State var weight: Int = 0
    var goal: String
    var bodyStructure: String
    @State var height: Int = 0
    @State var DailyCalories:Int = 0
   @State var DailyProtein: Int = 0
    var email:String
    @State private var isNavigationActive: Bool = false
    let password: String
    @State var submit: Bool = false
    let numDays: Int
    let numHours: String
    @State var prompt: String?
    @State var excersise: userExcersise?
    @State var responseInString: String = "valve"
    @State private var selectedOption = "Kg"
    @State private var selectedOption2 = "cm"
    let options = ["Kg", "lb"]
    let optionsw = ["cm", "Ft + in"]
    @State var heightFt: Int = 0
    @State var heightIn: Int = 0
    @State var carbs :Int?
    @State var sugars: Int?
    @State var DalyCaloriesBurn: Int?
    var whereWork : String
    var level: String
    @State var pres: Bool  = false
    @State var isAgreed:Bool = true
    @State var water: Double?
    @State var isChecked:Bool = false
    @State private var showLoginAfterAccountCreated = false
    @State private var didRequestRegistration = false
    @State private var registrationError = ""
    @State private var showRegistrationError = false
    @State private var selectedWeightUnit = "Kg"
       @State private var selectedHeightUnit = "cm"
       let weightOptions = ["Kg", "lb"]
       let heightOptions = ["cm", "Ft + in"]

    @State var hasAgreed:Bool = true

    var body: some View {
        Group {
            if showLoginAfterAccountCreated {
                ZStack{
                    LogInWindow().navigationBarBackButtonHidden(true)
                }.navigationBarBackButtonHidden(true)
            }
            else if submit {
                accountCreatedView
            }
            else if pres == true{
                LoadingView()
            }
            else if isAgreed == false {
                ZStack{
                    AppBackgroundView()
                    Circle().frame(width: 300).foregroundStyle(Color.blue.opacity(0.3)).blur(radius: 10).offset(x: -10, y: -150)
                    Circle().frame(width: 300).foregroundStyle(Color.white.opacity(0.3)).blur(radius: 10).offset(x: 10, y: 250)
                    VStack{
                        HStack{


                            Button(action: {
                                isChecked.toggle()
                                    }) {
                                        HStack {
                                            Image(systemName: isChecked ? "checkmark.square" : "square")
                                                .foregroundColor(.blue)
                                            Text("I agree to the")
                                            NavigationLink(destination: Terms_of_Use()){
                                                Text("Terms & Privacy Notice").bold().underline()
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)

                        }

                        Text("I consent to PowAI processing my fitness profile, nutrition entries, food photos, activity data, and AI prompts through PowAI's backend and third-party AI services to provide app features.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button{
                            if isChecked{
                                startRegistration()
                            }
                        }label: {
                            Text("Create account ").foregroundColor(.white).font(.title).background(Rectangle().clipShape(.buttonBorder)).padding(.top)
                        }
                    }
                }
            }
            else{
                ZStack{
                    AppBackgroundView()
                    Circle().frame(width: 300).foregroundStyle(Color.blue.opacity(0.3)).blur(radius: 10).offset(x: -100, y: -150)
                    Circle().frame(width: 300).foregroundStyle(Color.white.opacity(0.3)).blur(radius: 10).offset(x: 150, y: 250)
                    RiveViewModel(fileName: "shapes").view().ignoresSafeArea().blur(radius: 30)
                VStack{
                    Text("Final data").font(.title).foregroundStyle(LinearGradient(colors: [.accentColor,.purple], startPoint: .topLeading, endPoint: .bottomTrailing)).bold().fontDesign(.rounded).shadow(color: .blue, radius: 10)
                    Spacer()
                    VStack{
                        Form {
                                    // AGE SECTION
                                    Section(header: Text("Age").foregroundColor(age == 0 ? .red : .accentColor)) {
                                        TextField("Age", text: Binding<String>(
                                            get: { age == 0 ? "" : String(age) },
                                            set: { age = Int($0) ?? 0 }
                                        ))
                                        .keyboardType(.numberPad)
                                        .listRowBackground(Color.gray)
                                    }

                                    // HEIGHT SECTION
                                    Section(header: Text("Height").foregroundColor(.red)) {
                                        HStack {
                                            if selectedHeightUnit == "cm" {
                                                TextField("Height (cm)", text: Binding<String>(
                                                    get: { height == 0 ? "" : String(height) },
                                                    set: { height = Int($0) ?? 0 }
                                                ))
                                                .keyboardType(.numberPad)
                                                .listRowBackground(Color.gray)
                                            } else {
                                                TextField("Ft", text: Binding<String>(
                                                    get: { heightFt == 0 ? "" : String(heightFt) },
                                                    set: { heightFt = Int($0) ?? 0 }
                                                ))
                                                .keyboardType(.numberPad)
                                                .listRowBackground(Color.gray)

                                                TextField("In", text: Binding<String>(
                                                    get: { heightIn == 0 ? "" : String(heightIn) },
                                                    set: { heightIn = Int($0) ?? 0 }
                                                ))
                                                .keyboardType(.numberPad)
                                                .listRowBackground(Color.gray)
                                            }

                                            Picker("", selection: $selectedHeightUnit) {
                                                ForEach(heightOptions, id: \.self) { option in
                                                    Text(option)
                                                }
                                            }
                                            .pickerStyle(MenuPickerStyle())
                                        }
                                        .onChange(of: selectedHeightUnit) {
                                            convertHeightUnit()
                                        }
                                    }

                                    // WEIGHT SECTION
                                    Section(header: Text("Weight").foregroundColor(.red)) {
                                        HStack {
                                            TextField("Weight", text: Binding<String>(
                                                get: { weight == 0 ? "" : String(weight) },
                                                set: { weight = Int($0) ?? 0 }
                                            ))
                                            .keyboardType(.numberPad)
                                            .listRowBackground(Color.gray)

                                            Picker("", selection: $selectedWeightUnit) {
                                                ForEach(weightOptions, id: \.self) { option in
                                                    Text(option)
                                                }
                                            }
                                            .pickerStyle(MenuPickerStyle())
                                        }
                                        .onChange(of: selectedWeightUnit) {
                                            convertWeightUnit()
                                        }
                                    }
                                }
                                .scrollContentBackground(.hidden)

                    //                    Button{
                    //                        Task{ try await submitData()}
                    //                    }label: {
                    //                        Text("Create account \(firstName)").foregroundColor(.white).font(.title)
                    //                    }
                    Button{
                        isAgreed = false
                    }label: {
                        Text("Create account").foregroundColor(.white).font(.title).fontDesign(.rounded).bold()
                    }

                    }
                }

            }
            }
        }
        .alert("Couldn’t Create Account", isPresented: $showRegistrationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(registrationError)
        }
    }

    private var accountCreatedView: some View {
        ZStack {
            AppBackgroundView()
            RiveViewModel(fileName: "shapes").view()
                .ignoresSafeArea()
                .blur(radius: 30)

            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("Account Created")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Your plan is ready. Sign in to start training.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 30)

                Button {
                    showLoginAfterAccountCreated = true
                } label: {
                    Text("Go to Login")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 34)
                .padding(.top, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func convertHeightUnit() {
        if selectedHeightUnit == "cm" {
            let feetInCm = Double(heightFt) * 30.48
            let inchesInCm = Double(heightIn) * 2.54
            height = Int(feetInCm + inchesInCm)
        } else {
            let heightValue = Double(height)
            heightFt = height / 30
            heightIn = Int(heightValue.truncatingRemainder(dividingBy: 30) / 2.54)
        }
    }

    private func convertWeightUnit() {
        let currentWeight = Double(weight)

        if selectedWeightUnit == "Kg" {
            let convertedWeight = currentWeight / 2.205
            weight = Int(convertedWeight)
        } else {
            let convertedWeight = currentWeight * 2.205
            weight = Int(convertedWeight)
        }
    }



    func register() async throws {
        guard didRequestRegistration else { return }

        let urlString = Constants.baseURL + "/ai/register"
//        let urlString = "http://127.0.0.1:8080/ai/register"
        guard let url = URL(string: urlString) else { throw HttpEroor.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "firstName":     firstName,
            "lastName":      lastName,
            "email":         email,
            "password":      password,
            "age":           age,
            "gender":        gender,
            "weight":        weight,
            "weightUnit":    selectedOption,
            "height":        height != 0 ? height : 0,
            "heightUnit":    selectedOption2,
            "heightFt":      heightFt,
            "heightIn":     heightIn,
            "membership_status": "free",
            "goal":          goal,
            "bodyStructure": bodyStructure,
            "whereWork":     whereWork,
            "level":         level,
            "numDays":       numDays,
            "numHours":      WorkoutSessionDuration.normalizedHours(from: numHours)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw HttpEroor.badURL
        }

        submit = true
    }

    private func startRegistration() {
        guard !pres else { return }

        didRequestRegistration = true
        pres = true

        Task {
            do {
                try await register()
            } catch {
                pres = false
                didRequestRegistration = false
                registrationError = error.localizedDescription
                showRegistrationError = true
            }
        }
    }



}

struct finalData_Previews: PreviewProvider {
    static var previews: some View {
        finalData(firstName: "da", lastName: "dad", gender: "dad", goal: "dasda", bodyStructure: "dasda", email: "adad", password: "dsada",numDays: 5, numHours: "2", whereWork: "Gym", level: "Begginer")
    }
}
struct LoadingView: View {
    var body: some View {
        ZStack{
            Rectangle().foregroundStyle(Color.black).ignoresSafeArea()
            VStack {
                Spacer()
                ProgressView("Creating your account\n this may take a minute...").foregroundStyle(Color.white)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5, anchor: .center)
                Spacer()
            }
        }

    }
}

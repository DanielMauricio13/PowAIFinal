//
//  MainWindow.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/15/23.
//

import SwiftUI
import KeychainAccess


struct MainWindow: View {
    let email: String
    @State private var mainUser: User?
      @State private var isLoading = true // Track loading state
    var exercises: [Exercise] = []
    @State var excer: [String: Any]?
    @State var whichDay:Int?
    @State var numDayssUs: Int? = 1
    @State var userFullWork: fullTraining?
    @State public var userFound: Bool = true
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if isLoading {
                    // Show loading indicator or message while waiting for data
                    Text("Loading...").foregroundColor(.white)
                } else {
//                    VStack{
//                        Text("Which day are you working?")
//                        for i in numDayssUs {
//                            Button{
//                                
//                            }label: {
//                                Text(
//                            }
//                        }
//                    }
                    if userFound {
                        MainWindow2(mainUser: mainUser, userFullWork: self.userFullWork)
                    }else{
                        
                        LogInWindow()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                fetchUserInfo { result in
                    switch result {
                    case .success(let user):
                        mainUser = user // Assign the loggedInUser to mainUser
//                        print("User info received:", user)
                        
                        // Data has been loaded, update loading state
                        isLoading = false
                    case .failure(let error):
                        // Handle any errors here
                        logout()
                        print("Error fetching user info:", error)
                        
                    }
                }
                fetchExerciseData { result in
                    switch result {
                    case .success(let user):
                        userFullWork = user // Assign the loggedInUser to mainUser
//                        print("user Excersises receiver:", user)
                        
                        // Data has been loaded, update loading state
                        isLoading = false
                    case .failure(let error):
                        // Handle any errors here
                        print("Error fetching excersises:", error)
                        
                        // Data loading failed, update loading state
                        isLoading = false
                    }
                }
                
            }
           
            
        }
    }

    

    func fetchUserInfo(completion: @escaping (Result<User, Error>) -> Void) {
        guard let apiUrl = URL(string: "\(Constants.baseURL)profile?email=\(self.email)") else {
            logout()
            completion(.failure(URLError(.badURL)))
            return
        }
       
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "GET"
        
        // Retrieve the JWT token from UserDefaults
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            // Add the Authorization header
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            logout()
            completion(.failure(NetworkError.noToken))
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                logout()
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NetworkError.invalidResponse))
                logout()
                return
            }
            
            guard let jsonData = data else {
                completion(.failure(NetworkError.noData))
                logout()
                return
            }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: jsonData)
                DispatchQueue.main.async {
                    completion(.success(user))
                }
            } catch {
                DispatchQueue.main.async {
                    logout()
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }


    
    
//    func fetchUserInfo(completion: @escaping (Result<User, Error>) -> Void) {
//        guard let apiUrl = URL(string: "\(Constants.baseURL)\(EndPoints.users)profile?email=\(self.email)") else {
//            completion(.failure(URLError.badURL as! Error))
//            return
//        }
//        
//        var request = URLRequest(url: apiUrl)
//        request.httpMethod = "GET"
//        
//        let session = URLSession.shared
//        let task = session.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                completion(.failure(NetworkError.invalidResponse))
//                return
//            }
//            
//            guard let jsonData = data else {
//                completion(.failure(NetworkError.noData))
//                return
//            }
////            if let jsonString = String(data: jsonData, encoding: .utf8) {
//////                        print("Received JSON data:\n\(jsonString)")
////                    }
//            
//            do {
//                let user = try JSONDecoder().decode(User.self, from: jsonData)
//                DispatchQueue.main.async {
//                    completion(.success(user))
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    completion(.failure(error))
//                }
//            }
//        }
//        task.resume()
//    }

    func fetchExerciseData(completion: @escaping (Result<fullTraining, Error>) -> Void) {
            // Replace this URL with your Vapor server endpoint
        let url = URL(string: "\(Constants.baseURL)\(EndPoints.training)userExcersises?email=\(email)")!
            
            // Create an HTTP GET request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // Create a URLSession task to perform the request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // Check for network errors
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Check for a valid HTTP response
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                // Ensure there is data
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let user = try JSONDecoder().decode(fullTraining.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(user))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            
            // Start the URLSession task
            task.resume()
        }

    // Define a custom error type for network errors
    enum NetworkError: Error {
        case invalidResponse
        case noData
        case noToken
    }
    enum APIError: Error {
        case networkError(Error)
        case invalidResponse
        case noData
        case decodingError(Error)
    }
    struct Exercise: Decodable {
        var day: String
        var title: String
        var items: [ExerciseItem]
    }

    struct ExerciseItem: Decodable {
        var title: String
        var sets: String
        var repetitions: String
    }

    func logout()->Void {
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "username")
        HealthManager.shared.calories = 0
        HealthManager.shared.protein = 0
        userFound = false
      //  persistenceManager.clearItems()
    }
}



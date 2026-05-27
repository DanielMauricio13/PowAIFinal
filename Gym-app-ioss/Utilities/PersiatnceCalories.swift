//
//  PersiatnceCalories.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/25/24.
//

import Foundation
import Combine


extension UserDefaults {
    private enum Keys {
        static let protein = "protein"
        static let caloriesToday = "caloriesToday"
        static let carbs = "carbs"
        static let sugars = "sugars"
        static let lastResetDate = "lastResetDate"
    }

    var protein: Int {
        get {
            return integer(forKey: Keys.protein)
        }
        set {
            set(newValue, forKey: Keys.protein)
        }
    }

    var calories: Int {
        get {
            return integer(forKey: Keys.caloriesToday)
        }
        set {
            set(newValue, forKey: Keys.caloriesToday)
        }
    }
    var carbs: Int {
        get {
            return integer(forKey: Keys.carbs)
        }
        set {
            set(newValue, forKey: Keys.carbs)
        }
    }
    var sugars: Int {
        get {
            return integer(forKey: Keys.carbs)
        }
        set {
            set(newValue, forKey: Keys.carbs)
        }
    }

    var lastResetDate: Date? {
        get {
            return object(forKey: Keys.lastResetDate) as? Date
        }
        set {
            set(newValue, forKey: Keys.lastResetDate)
        }
    }
}


import Foundation
import Combine

import Foundation
import SwiftUI

@MainActor
class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @Published var protein: Int {
        didSet {
            UserDefaults.standard.protein = self.protein
        }
    }

    @Published var calories: Int {
        didSet {
            UserDefaults.standard.calories = self.calories
        }
    }

    @Published var carbs: Int {
        didSet {
            UserDefaults.standard.carbs = self.carbs
        }
    }

    @Published var sugars: Int {
        didSet {
            UserDefaults.standard.sugars = self.sugars
        }
    }

    private init() {
        self.protein = UserDefaults.standard.protein
        self.calories = UserDefaults.standard.calories
        self.carbs = UserDefaults.standard.carbs
        self.sugars = UserDefaults.standard.sugars

        if let lastResetDate = UserDefaults.standard.lastResetDate,
           !Calendar.current.isDateInToday(lastResetDate) {

            Task {
               try await saveDailyNutritionToDB()
                resetHealthData()
            }

        } else if UserDefaults.standard.lastResetDate == nil {
            UserDefaults.standard.lastResetDate = Date()
        }

        scheduleMidnightReset()
    }

    private func scheduleMidnightReset() {
        let now = Date()
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let todayMidnight = calendar.date(from: components),
              let nextMidnight = calendar.date(byAdding: .day, value: 1, to: todayMidnight) else {
            return
        }

        let timeInterval = nextMidnight.timeIntervalSince(now)
        print("Scheduling health data reset in \(timeInterval) seconds")

        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            Task { @MainActor in
                print("Saving daily nutrition before reset")

                
               try await self.saveDailyNutritionToDB()

                print("Resetting health data")
                self.resetHealthData()
            }
        }
    }

    private func saveDailyNutritionToDB() async throws{
        // Capture values BEFORE reset
        let currentProtein = self.protein
        let currentCalories = self.calories
        let currentCarbs = self.carbs
        let currentSugars = self.sugars

        // Replace this with wherever you store the logged-in user's email
        guard let email = UserDefaults.standard.string(forKey: "email") else {
            print("No user email found. Skipping daily nutrition save.")
            return
        }

        guard let url = URL(string: "\(Constants.baseURL)daily-nutrition/newEntry") else {
            print("Invalid daily nutrition URL")
            return
        }

        struct DailyNutritionPayload: Codable {
            let email: String
            let date: Date
            let protein: Double
            let carbs: Double
            let calories: Double
            let sugars: Double
        }
         func isoString(_ date: Date) -> String {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]   // no fractional seconds — Vapor rejects .000Z
            return f.string(from: date)
        }
    

        
            var req = URLRequest(url: url); 
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.applyBearerToken()
            
            let body: [String: Any] = ["email": email, "date": isoString(Calendar.current.startOfDay(for: Date())), "protein": currentProtein,"carbs" : currentCarbs
            , "calories": currentCalories, "sugars": currentSugars]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
                #if DEBUG
                print("addWeight body:", String(data: req.httpBody!, encoding: .utf8) ?? "")
                #endif

                let (respData, response) = try await URLSession.shared.data(for: req)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0

                #if DEBUG
                    print("addWeight status:", status,
                            "| body:", String(data: respData, encoding: .utf8) ?? "")
                #endif

                guard (200..<300).contains(status) else {
                        let reason = (try? JSONDecoder().decode([String: String].self, from: respData))?["reason"]
                            ?? "HTTP \(status)"
                            throw NSError(domain: "WeightService", code: status,
                  userInfo: [NSLocalizedDescriptionKey: reason])
}
          

       
    }

    private func resetHealthData() {
        self.protein = 0
        self.calories = 0
        self.carbs = 0
        self.sugars = 0

        UserDefaults.standard.lastResetDate = Date()

        scheduleMidnightReset()
    }
}

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

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    
    @Published var protein: Int {
        didSet {
            DispatchQueue.main.async {
                UserDefaults.standard.protein = self.protein
            }
        }
    }
    
    @Published var calories: Int {
        didSet {
            DispatchQueue.main.async {
                UserDefaults.standard.calories = self.calories
            }
        }
    }
    @Published var carbs: Int {
        didSet {
            DispatchQueue.main.async {
                UserDefaults.standard.carbs = self.carbs
            }
        }
    }
    @Published var sugars: Int {
        didSet {
            DispatchQueue.main.async {
                UserDefaults.standard.sugars = self.sugars
            }
        }
    }

    private init() {
        self.protein = UserDefaults.standard.protein
        self.calories = UserDefaults.standard.calories
        self.carbs = UserDefaults.standard.carbs
        self.sugars = UserDefaults.standard.sugars
        
        // Check if the last reset date was today; if not, reset values
        if let lastResetDate = UserDefaults.standard.lastResetDate,
           !Calendar.current.isDateInToday(lastResetDate) {
            self.protein = 0
            self.calories = 0
            self.carbs = 0
            self.sugars = 0
        }
        
        // Set the last reset date to today
        UserDefaults.standard.lastResetDate = Date()
        
        // Schedule the reset at midnight
        scheduleMidnightReset()
    }

    private func scheduleMidnightReset() {
        let now = Date()
        let calendar = Calendar.current

        // Calculate the next midnight
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!) else {
            return
        }

        // Schedule the reset
        let timeInterval = nextMidnight.timeIntervalSince(now)
        print("Scheduling health data reset in \(timeInterval) seconds")

        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            print("Resetting health data")
            DispatchQueue.main.async {
                self.resetHealthData()
            }
        }
    }

    private func resetHealthData() {
        self.protein = 0
        self.calories = 0
        self.carbs = 0
        self.sugars = 0
        DispatchQueue.main.async {
            UserDefaults.standard.lastResetDate = Date()
        }
        
        // Reschedule the reset for the next midnight
        scheduleMidnightReset()
    }
}

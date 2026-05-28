//
//  PersiatnceCalories.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/25/24.
//

import Foundation
import Combine
import SwiftUI

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
            return integer(forKey: Keys.sugars)
        }
        set {
            set(newValue, forKey: Keys.sugars)
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

@MainActor
class HealthManager: ObservableObject {
    static let shared = HealthManager()
    private var midnightResetTimer: Timer?

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
            let dateToSave = Calendar.current.startOfDay(for: lastResetDate)
            Task {
                await persistAndReset(for: dateToSave)
            }

        } else if UserDefaults.standard.lastResetDate == nil {
            UserDefaults.standard.lastResetDate = Date()
        }

        scheduleMidnightReset()
    }

    private func scheduleMidnightReset() {
        midnightResetTimer?.invalidate()

        let now = Date()
        let calendar = Calendar.current
        let dateToSave = calendar.startOfDay(for: now)

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

        midnightResetTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            Task { @MainActor in
                await self.persistAndReset(for: dateToSave)
            }
        }
    }

    private func persistAndReset(for date: Date) async {
        do {
            print("Saving daily nutrition before reset")
            try await saveDailyNutritionToDB(for: date)

            print("Resetting health data")
            resetHealthData()
        } catch {
            print("Daily nutrition save failed. Keeping current health data for retry: \(error.localizedDescription)")
            scheduleSaveRetry(for: date)
        }
    }

    private func scheduleSaveRetry(for date: Date) {
        midnightResetTimer?.invalidate()
        midnightResetTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { _ in
            Task { @MainActor in
                await self.persistAndReset(for: date)
            }
        }
    }

    private func saveDailyNutritionToDB(for date: Date) async throws {
        // Capture values BEFORE reset
        let currentProtein = self.protein
        let currentCalories = self.calories
        let currentCarbs = self.carbs
        let currentSugars = self.sugars

        guard let url = URL(string: "\(Constants.baseURL)daily-nutrition/newEntry") else {
            print("Invalid daily nutrition URL")
            return
        }

        func isoString(_ date: Date) -> String {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]   // no fractional seconds — Vapor rejects .000Z
            return f.string(from: date)
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.applyBearerToken()

        let body: [String: Any] = [
            "email": UserDefaults.standard.string(forKey: "email") ?? "",
            "date": isoString(Calendar.current.startOfDay(for: date)),
            "protein": currentProtein,
            "carbs": currentCarbs,
            "calories": currentCalories,
            "sugars": currentSugars
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        #if DEBUG
        print("dailyNutrition body:", String(data: req.httpBody!, encoding: .utf8) ?? "")
        #endif

        let (respData, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        #if DEBUG
        print("dailyNutrition status:", status,
              "| body:", String(data: respData, encoding: .utf8) ?? "")
        #endif

        guard (200..<300).contains(status) else {
            let reason = (try? JSONDecoder().decode([String: String].self, from: respData))?["reason"]
                ?? "HTTP \(status)"
            throw NSError(domain: "NutritionService", code: status,
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

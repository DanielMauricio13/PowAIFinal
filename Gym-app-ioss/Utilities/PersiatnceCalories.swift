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

    private struct DailyNutritionSnapshot {
        let protein: Int
        let calories: Int
        let carbs: Int
        let sugars: Int

        var hasAnyNutrition: Bool {
            protein > 0 || calories > 0 || carbs > 0 || sugars > 0
        }
    }

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

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 23
        components.minute = 59
        components.second = 30

        guard let todayCloseout = calendar.date(from: components) else {
            return
        }

        let nextCloseout = todayCloseout > now
            ? todayCloseout
            : (calendar.date(byAdding: .day, value: 1, to: todayCloseout) ?? todayCloseout)

        let dateToSave = calendar.startOfDay(for: nextCloseout)
        let timeInterval = nextCloseout.timeIntervalSince(now)
        print("Scheduling health data reset in \(timeInterval) seconds")

        midnightResetTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            Task { @MainActor in
                await self.persistAndReset(for: dateToSave)
            }
        }
    }

    private func persistAndReset(for date: Date) async {
        let snapshot = DailyNutritionSnapshot(
            protein: protein,
            calories: calories,
            carbs: carbs,
            sugars: sugars
        )

        do {
            print("Saving daily nutrition before reset")
            if snapshot.hasAnyNutrition {
                try await saveDailyNutritionToDB(for: date, snapshot: snapshot)
            } else {
                print("Skipping daily nutrition save because all macro values are zero")
            }

            print("Resetting health data")
            resetHealthData()
        } catch {
            print("Daily nutrition save failed. Keeping current health data for retry: \(error.localizedDescription)")
            scheduleSaveRetry(for: date, snapshot: snapshot)
        }
    }

    private func scheduleSaveRetry(for date: Date, snapshot: DailyNutritionSnapshot) {
        midnightResetTimer?.invalidate()
        midnightResetTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { _ in
            Task { @MainActor in
                do {
                    try await self.saveDailyNutritionToDB(for: date, snapshot: snapshot)
                    self.resetHealthData()
                } catch {
                    print("Daily nutrition retry failed: \(error.localizedDescription)")
                    self.scheduleSaveRetry(for: date, snapshot: snapshot)
                }
            }
        }
    }

    private func saveDailyNutritionToDB(for date: Date, snapshot: DailyNutritionSnapshot) async throws {
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
            "protein": snapshot.protein,
            "carbs": snapshot.carbs,
            "calories": snapshot.calories,
            "sugars": snapshot.sugars
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

//
//  User.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/16/23.
//

import Foundation


struct User: Identifiable, Codable {
    let id: UUID?
    let firstName: String
    let lastName: String
    var age: Int?
    var gender: String?
    var weight: Int?
    var goal: String?
    var bodyStructure: String?
    var height: Int?
    var DailyCalories: Int?
    var DailyProtein: Int?
    var email: String?
    var password: String?
    var heightFt: Int?
    var heightInc: Int?
    var numHours: String?
    var numDays: Int?
    var sugars: Int?
    var carbs: Int?
    var burnCalories: Int?
    var water: Double?
    var membershipStatus: String
    var membershipPlan: String?
    var membershipStartedAt: Date?
    var membershipExpiresAt: Date?
    var membershipPlatform: String?
    var appleProductID: String?
    var appleOriginalTransactionID: String?
    var appleLatestTransactionID: String?

    enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, age, gender, weight, goal, bodyStructure, height
        case DailyCalories, DailyProtein, email, password, heightFt, heightInc
        case numHours, numDays, sugars, carbs, burnCalories, water
        case membershipStatus
        case membershipPlan
        case membershipStartedAt
        case membershipExpiresAt
        case membershipPlatform
        case appleProductID
        case appleOriginalTransactionID
        case appleLatestTransactionID
    }
}

enum WorkoutSessionDuration {
    static let profilePickerValues = ["0.5", "1", "1.5", "2", "2.5", "3"]

    static func normalizedHours(from rawValue: String?) -> String {
        guard let rawValue else { return "1" }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "1" }

        if let numericValue = Double(trimmed) {
            return formattedHours(numericValue)
        }

        let lowercased = trimmed.lowercased()
        if lowercased.contains("<") {
            return "0.5"
        }
        if lowercased.contains(">") {
            return "2.5"
        }
        if lowercased.contains("1:30") && lowercased.contains("2") {
            return "1.75"
        }
        if lowercased.contains("1") && lowercased.contains("1:30") {
            return "1.25"
        }
        if lowercased.contains("1-2") || lowercased.contains("1 – 2") || lowercased.contains("1 to 2") {
            return "1.5"
        }

        return trimmed
    }

    static func pickerValue(from rawValue: String?) -> String {
        let normalized = normalizedHours(from: rawValue)
        guard let hours = Double(normalized) else { return "1" }

        return profilePickerValues.min { lhs, rhs in
            abs((Double(lhs) ?? 1) - hours) < abs((Double(rhs) ?? 1) - hours)
        } ?? "1"
    }

    static func displayText(for value: String) -> String {
        let normalized = normalizedHours(from: value)
        guard let hours = Double(normalized) else { return value }
        return String(format: "%.1f h", hours)
    }

    private static func formattedHours(_ hours: Double) -> String {
        if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(hours))
        }
        if (hours * 10).truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.1f", hours)
        }
        return String(format: "%.2f", hours)
    }
}


struct userNutrition: Codable{
    var protein: Int
    var calories: Int
    var sugars: Int
    var carbs: Int
    var burnCalories: Int
    var water: Double
}
struct aiResponse: Codable {
    var userExcersise: userExcersise
    var nutrition: userNutrition
}


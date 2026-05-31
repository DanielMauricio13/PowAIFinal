//
//  LogedInUser.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 9/3/23.
//

import Foundation

struct logedInUser: Identifiable {
        let id: UUID?
        let firstName: String
        let lastName:String
         var age: String
         var gender: String
        var weight: String
         var goal: String
        var bodyStructure: String
        var height: String
        var DailyCalories: String
        var DailyProtein: String
        var email:String
        var password:String
        var excersisess: String
        var numHours: String
        var numDays: String
        var excersises:[workout_plans]
    
}

struct SetEntry: Codable {
    var setNumber: Int
    var reps: Int
    var weight: Double
    var completed: Bool
    var date: Date

    init(setNumber: Int, reps: Int, weight: Double, completed: Bool, date: Date = Date()) {
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.completed = completed
        self.date = date
    }

    enum CodingKeys: String, CodingKey {
        case setNumber
        case reps
        case weight
        case completed
        case date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        setNumber = try container.decode(Int.self, forKey: .setNumber)
        reps = try container.decode(Int.self, forKey: .reps)
        weight = try container.decode(Double.self, forKey: .weight)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false

        if let decodedDate = try? container.decode(Date.self, forKey: .date) {
            date = decodedDate
        } else if let dateString = try? container.decode(String.self, forKey: .date) {
            date = SetEntry.parseDate(dateString) ?? Date()
        } else if let timestamp = try? container.decode(Double.self, forKey: .date) {
            date = Date(timeIntervalSince1970: timestamp)
        } else {
            date = Date()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(setNumber, forKey: .setNumber)
        try container.encode(reps, forKey: .reps)
        try container.encode(weight, forKey: .weight)
        try container.encode(completed, forKey: .completed)
        try container.encode(SetEntry.isoDateString(from: date), forKey: .date)
    }

    static func isoDateString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private static func parseDate(_ value: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

struct Excersise: Codable {
    var name: String
    var reps: String
    var sets: Int
    var calories_burned: Int
    var descriptionEng: String? = nil
    var descriptionEsp: String? = nil
    var loggedSets: [SetEntry] = []

    init(
        name: String,
        reps: String,
        sets: Int,
        calories_burned: Int,
        descriptionEng: String? = nil,
        descriptionEsp: String? = nil,
        loggedSets: [SetEntry] = []
    ) {
        self.name = name
        self.reps = reps
        self.sets = sets
        self.calories_burned = calories_burned
        self.descriptionEng = descriptionEng
        self.descriptionEsp = descriptionEsp
        self.loggedSets = loggedSets
    }

    enum CodingKeys: String, CodingKey {
        case name
        case reps
        case sets
        case calories_burned
        case descriptionEng
        case descriptionEsp
        case loggedSets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        reps = try container.decode(String.self, forKey: .reps)
        sets = try container.decode(Int.self, forKey: .sets)
        calories_burned = try container.decode(Int.self, forKey: .calories_burned)
        descriptionEng = try container.decodeIfPresent(String.self, forKey: .descriptionEng)
        descriptionEsp = try container.decodeIfPresent(String.self, forKey: .descriptionEsp)
        loggedSets = try container.decodeIfPresent([SetEntry].self, forKey: .loggedSets) ?? []
    }
}
struct workout_plans: Codable {
    
    var day: Int
    var muscle_group: String
    var exercises: [Excersise]
}
struct userExcersise: Codable{
  
    var workout_plan:[workout_plans]
    init() {                          // ← this must be here
            self.workout_plan = []
        }
}

struct fullTraining: Codable {
    let  id: UUID?
    var email: String
    var userExcersises: userExcersise
}




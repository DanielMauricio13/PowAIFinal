//
//  WorkoutDTO.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/23/26.
//


// iOS — AIModels.swift
import Foundation

// Mirrors the backend WorkoutDTO — used to decode /ai/requestHIIT response
struct WorkoutDTO: Codable {
    var workout_plan: [WorkoutDayDTO]
}

struct WorkoutDayDTO: Codable {
    var day: Int
    var muscle_group: String
    var exercises: [ExcersiseDTO]
}

struct ExcersiseDTO: Codable {
    var name: String
    var reps: String
    var sets: Int
    var calories_burned: Int
    var descriptionEng: String? = nil
    var descriptionEsp: String? = nil
    var loggedSets: [SetEntry]? = nil
}

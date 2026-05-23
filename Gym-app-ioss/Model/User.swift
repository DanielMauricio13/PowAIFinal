//
//  User.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/16/23.
//

import Foundation


struct User: Identifiable, Codable{
    let id: UUID?
    let firstName: String
    let lastName:String
     var age: Int
     var gender: String
    var weight: Int
     var goal: String
    var bodyStructure: String
    var height: Int
    var DailyCalories: Int
    var DailyProtein: Int
    var email:String
    var password:String
    var heightFt: Int
    var heightInc: Int
    var numHours: String
    var numDays: Int
    var sugars: Int
    var carbs: Int
    var burnCalories: Int
    var water: Double
  

    
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



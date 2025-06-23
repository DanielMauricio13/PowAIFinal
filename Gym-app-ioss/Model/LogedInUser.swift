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

struct Excersise: Codable {
    var name: String
    var reps: String
    var sets: Int
    var calories_burned: Int
}
struct workout_plans: Codable {
    
    var day: Int
    var muscle_group: String
    var exercises: [Excersise]
}
struct userExcersise: Codable{
  
    var workout_plan:[workout_plans]
}

struct fullTraining: Codable {
    let  id: UUID?
    var email: String
    var userExcersises: userExcersise
}







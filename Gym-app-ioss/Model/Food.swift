//
//  Food.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/8/24.
//

import Foundation

struct Food:Codable, Identifiable {
    var id: UUID?
    let Name:String
    let Calories: Int
    let Sugars: Int
    let Carbohydrates:Int
    let Protein: Int
    
    
    
    init(id: UUID? = nil, Name: String, Calories: Int, Sugars: Int, Carbohydrates: Int, Protein: Int) {
        self.id = id
        self.Name = Name
        self.Calories = Calories
        self.Sugars = Sugars
        self.Carbohydrates = Carbohydrates
        self.Protein = Protein
        
    }
}

struct meal:Codable, Identifiable {
    var id: UUID?
    var meal: [Food]
}
struct savedFood:Codable, Identifiable {
    var id: UUID?
    let Name:String
    let Calories: Int
    let Sugars: Int
    let Carbohydrates:Int
    let Protein: Int
    let email:String
    
    
    
    init(id: UUID? = nil, Name: String, Calories: Int, Sugars: Int, Carbohydrates: Int, Protein: Int, email:String) {
        self.id = id
        self.Name = Name
        self.Calories = Calories
        self.Sugars = Sugars
        self.Carbohydrates = Carbohydrates
        self.Protein = Protein
        self.email = email
    }
}

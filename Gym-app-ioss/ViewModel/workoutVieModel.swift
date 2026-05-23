//
//  workoutVieModel.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/22/24.
//
import SwiftUI

struct ExcListItem: Identifiable {
        var id = UUID()
        var title: String
        var description: String
        var totalCalories: Int
        var duration: Int
        var NumExcersises: Int
        var isExpanded: Bool = false
        var isSaved: Bool = false
}






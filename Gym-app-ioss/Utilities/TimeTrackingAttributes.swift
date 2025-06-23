//
//  TimeTrackingAttributes.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 6/13/24.
//

import Foundation
import ActivityKit

struct TimeTrackingAttributes: ActivityAttributes{
    public typealias TimeTrackingStatus = ContentState
    
    public struct ContentState: Codable, Hashable{
        var startTime:Date
        var set: Int
    }
    var Initial: Date
    
}

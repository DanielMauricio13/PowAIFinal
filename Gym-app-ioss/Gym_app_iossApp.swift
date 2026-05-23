//
//  Gym_app_iossApp.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/15/23.
//

import SwiftUI

@main
struct Gym_app_iossApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var healthManager = HealthManager.shared

    var body: some Scene {
        WindowGroup {
            LogInWindow().environmentObject(healthManager)
        }
    }
}



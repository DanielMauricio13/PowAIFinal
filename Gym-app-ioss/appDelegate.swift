//
//  appDelegate.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 6/17/24.
//

import UIKit
import BackgroundTasks
import UserNotifications
import ActivityKit
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
   var activity: Activity<TimeTrackingAttributes>?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.timer", using: nil) { task in
            self.handleBackgroundTask(task: task as! BGProcessingTask)
        }
        
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()

//        NotificationCenter.default.addObserver(
//                   self,
//                   selector: #selector(appWillTerminate),
//                   name: UIApplication.willTerminateNotification,
//                   object: nil
//               )
        return true
    }
//    func applicationWillTerminate(_ application: UIApplication) {
//            print("AppDelegate: applicationWillTerminate - App is about to terminate.")
//            LiveActivityManager.shared.endLiveActivity(set: 0)
//        }
       
//       @objc func appWillTerminate() {
//           LiveActivityManager.shared.endLiveActivity(set: 0)
//       }

   
    private func handleBackgroundTask(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

//        Task {
//            await BackgroundTaskManager.shared.updateLiveActivity(timeRemaining: 60)
//            task.setTaskCompleted(success: true)
//        }

        scheduleBackgroundTask()
    }

    private func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: "com.yourapp.timer")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to submit background task: \(error)")
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request notification permission: \(error)")
            }
        }
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound])
    }
}


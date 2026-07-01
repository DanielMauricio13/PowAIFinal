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
    private static let timerBackgroundTaskIdentifier = "io.Mauro.Gym-app-ios.timer"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.timerBackgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task: task as! BGProcessingTask)
        }
        
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        PushNotificationRegistrar.uploadStoredDeviceTokenIfPossible()
        Task { @MainActor in
            HealthKitManager.shared.resumeBackgroundMonitoringIfNeeded()
        }

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
        let request = BGProcessingTaskRequest(identifier: Self.timerBackgroundTaskIdentifier)
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
            if granted {
                PushNotificationRegistrar.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationRegistrar.saveDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let alarmID = notification.request.content.userInfo["alarmID"] as? String {
            NotificationCenter.default.post(name: .powAIAlarmNotificationTapped, object: alarmID)
        }
        completionHandler([.list, .banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let alarmID = response.notification.request.content.userInfo["alarmID"] as? String {
            NotificationCenter.default.post(name: .powAIAlarmNotificationTapped, object: alarmID)
        }
        completionHandler()
    }
}

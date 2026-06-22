import Foundation
import UIKit

enum PushNotificationRegistrar {
    private static let deviceTokenKey = "apnsDeviceToken"

    static var apnsEnvironment: String {
        #if DEBUG
        return "sandbox"
        #else
        return "production"
        #endif
    }

    static func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    static func saveDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: deviceTokenKey)
        uploadStoredDeviceTokenIfPossible()
    }

    static func uploadStoredDeviceTokenIfPossible() {
        guard let token = UserDefaults.standard.string(forKey: deviceTokenKey),
              !token.isEmpty,
              AuthSession.getToken()?.isEmpty == false,
              let url = URL(string: Constants.baseURL + "users/device-token") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.applyBearerToken()
        request.httpBody = try? JSONEncoder().encode([
            "token": token,
            "environment": apnsEnvironment
        ])

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error {
                print("Failed to upload APNs token: \(error)")
                return
            }
            if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
                print("APNs token upload failed with status \(status)")
            }
        }.resume()
    }
}

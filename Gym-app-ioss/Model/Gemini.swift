//
//  Gemini.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/13/24.
//

import Foundation

import GoogleGenerativeAI


enum APIKey {
  /// Fetch the API key from `GenerativeAI-Info.plist`
  /// This is just *one* way how you can retrieve the API key for your app.
  static var `default`: String {
    guard let filePath = Bundle.main.path(forResource: "GenerativeAi-Info", ofType: "plist")
    else {
      return ""
    }
    let plist = NSDictionary(contentsOfFile: filePath)
    guard let value = plist?.object(forKey: "Api-Key") as? String else {
      return ""
    }
    if value.starts(with: "_") || value.isEmpty {
      return ""
    }
    return value
  }
}

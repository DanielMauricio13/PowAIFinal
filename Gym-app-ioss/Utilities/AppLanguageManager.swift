//
//  AppLanguageManager.swift
//  Gym-app-ioss
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case spanish

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .system:
            return "System"
        case .english:
            return "English"
        case .spanish:
            return "Spanish"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .spanish:
            return Locale(identifier: "es")
        }
    }
}

final class AppLanguageManager: ObservableObject {
    static let shared = AppLanguageManager()

    private enum Keys {
        static let appLanguage = "appLanguage"
    }

    @Published private(set) var selectedLanguage: AppLanguage

    private init() {
        let savedValue = UserDefaults.standard.string(forKey: Keys.appLanguage)
        selectedLanguage = savedValue.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    var locale: Locale {
        selectedLanguage.locale
    }

    var languageCode: String? {
        switch selectedLanguage {
        case .system:
            return nil
        case .english:
            return "en"
        case .spanish:
            return "es"
        }
    }

    var prefersSpanish: Bool {
        let identifier: String
        switch selectedLanguage {
        case .system:
            identifier = Locale.autoupdatingCurrent.identifier
        default:
            identifier = selectedLanguage.locale.identifier
        }

        return identifier.lowercased().hasPrefix("es")
    }

    func localizedString(forKey key: String) -> String {
        guard let languageCode,
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }

        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    func apply(_ language: AppLanguage) {
        selectedLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: Keys.appLanguage)
    }
}

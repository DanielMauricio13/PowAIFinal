//
//  PersistanceFood.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/24/24.
//

import Foundation

class PersistenceManager {
    private let userDefaults = UserDefaults.standard
    private let itemsKey = "items"
    private let dateKey = "saveDate"
    private let favoritesKey = "favoriteFoods"

    func saveItems(items: [Food]) {
        let encoder = JSONEncoder()
        if let encodedItems = try? encoder.encode(items) {
            userDefaults.set(encodedItems, forKey: itemsKey)
            userDefaults.set(Date(), forKey: dateKey)
        }
    }

    func loadItems() -> [Food] {
        guard let savedDate = userDefaults.object(forKey: dateKey) as? Date else { return [] }
        
        
        
        // Get the current date
        let currentDate = Date()
        
        // Extract the date components (year, month, day) from the saved date and current date
        let calendar = Calendar.current
        let savedDateComponents = calendar.dateComponents([.year, .month, .day], from: savedDate)
        let currentDateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
        
        // Check if the saved date and the current date are different
        if savedDateComponents != currentDateComponents {
            clearItems()
            return []
        }
        
        if let savedItems = userDefaults.data(forKey: itemsKey) {
            let decoder = JSONDecoder()
            if let loadedItems = try? decoder.decode([Food].self, from: savedItems) {
                return loadedItems
            }
        }
        return []
    }
    func clearItem(byName name: String) {
            if let savedItems = userDefaults.data(forKey: itemsKey) {
                let decoder = JSONDecoder()
                if var loadedItems = try? decoder.decode([Food].self, from: savedItems) {
                    if let index = loadedItems.firstIndex(where: { $0.Name == name }) {
                        let temp: Food = loadedItems.remove(at: index)
                        HealthManager.shared.calories -= temp.Calories
                        HealthManager.shared.protein -= temp.Protein
                        HealthManager.shared.sugars -= temp.Sugars
                        HealthManager.shared.carbs -= temp.Carbohydrates
                        saveItems(items: loadedItems)
                        
                    }
                }
        }

    }

    func clearItems() {
        userDefaults.removeObject(forKey: itemsKey)
        userDefaults.removeObject(forKey: dateKey)
    }

    // MARK: - Favorites Handling

    func saveFavorites(items: [Food]) {
        let encoder = JSONEncoder()
        if let encodedItems = try? encoder.encode(items) {
            userDefaults.set(encodedItems, forKey: favoritesKey)
        }
    }

    func loadFavorites() -> [Food] {
        if let savedItems = userDefaults.data(forKey: favoritesKey) {
            let decoder = JSONDecoder()
            if let loadedItems = try? decoder.decode([Food].self, from: savedItems) {
                return loadedItems
            }
        }
        return []
    }

    func addFavorite(food: Food) {
        var favorites = loadFavorites()
        if !favorites.contains(where: { $0.Name == food.Name }) {
            favorites.append(food)
            saveFavorites(items: favorites)
        }
    }

    func removeFavorite(byName name: String) {
        var favorites = loadFavorites()
        if let index = favorites.firstIndex(where: { $0.Name == name }) {
            favorites.remove(at: index)
            saveFavorites(items: favorites)
        }
    }

    func getItem(byName name: String) -> Food? {
        return loadItems().first(where: { $0.Name == name })
    }

    func sendFavorites(email: String) async {
        let favorites = loadFavorites()
        guard let url = URL(string: "\(Constants.baseURL)\(EndPoints.foods)") else {
            return
        }
        for food in favorites {
            let payload = savedFood(id: nil, Name: food.Name, Calories: food.Calories, Sugars: food.Sugars, Carbohydrates: food.Carbohydrates, Protein: food.Protein, email: email)
            do {
                try await HttpClient.shared.sendData(to: url, object: payload, httpMethod: HttpMethods.POST.rawValue)
            } catch {
                print("Failed to send favorite: \(error)")
            }
        }
    }
}

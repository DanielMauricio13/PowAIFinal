import Foundation

struct OpenFoodFactsResponse: Codable {
    let product: ProductInfo?
}

struct ProductInfo: Codable {
    let product_name: String?
    let nutriments: Nutriments?
}

struct Nutriments: Codable {
    let energyKcalServing: Double?
    let energyKcal100g: Double?
    let proteinsServing: Double?
    let proteins100g: Double?
    let carbohydratesServing: Double?
    let carbohydrates100g: Double?
    let sugarsServing: Double?
    let sugars100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcalServing = "energy-kcal_serving"
        case energyKcal100g = "energy-kcal_100g"
        case proteinsServing = "proteins_serving"
        case proteins100g = "proteins_100g"
        case carbohydratesServing = "carbohydrates_serving"
        case carbohydrates100g = "carbohydrates_100g"
        case sugarsServing = "sugars_serving"
        case sugars100g = "sugars_100g"
    }
}

enum BarcodeServiceError: Error {
    case invalidResponse
    case productNotFound
}

class BarcodeService {
    static func fetchFood(for barcode: String) async throws -> Food {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json"
        guard let url = URL(string: urlString) else { throw BarcodeServiceError.invalidResponse }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw BarcodeServiceError.invalidResponse }
        let decoder = JSONDecoder()
        let result = try decoder.decode(OpenFoodFactsResponse.self, from: data)
        guard let product = result.product else { throw BarcodeServiceError.productNotFound }
        let name = product.product_name ?? "Unknown"
        let nutriments = product.nutriments
        let calories = Int(nutriments?.energyKcalServing ?? nutriments?.energyKcal100g ?? 0)
        let protein = Int(nutriments?.proteinsServing ?? nutriments?.proteins100g ?? 0)
        let carbs = Int(nutriments?.carbohydratesServing ?? nutriments?.carbohydrates100g ?? 0)
        let sugars = Int(nutriments?.sugarsServing ?? nutriments?.sugars100g ?? 0)
        return Food(Name: name, Calories: calories, Sugars: sugars, Carbohydrates: carbs, Protein: protein)
    }
}

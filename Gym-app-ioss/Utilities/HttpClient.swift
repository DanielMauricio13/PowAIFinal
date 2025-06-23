//
//  HttpClient.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 8/16/23.
//

import Foundation


enum HttpMethods: String{
    case POST, GET , DELETE, PUT
}
enum MIMEType: String{
    case JSON = "application/json"
}
enum HttpHeaders: String {
    case contentType = "Content-Type"
}

enum HttpEroor: Error{
    case badURL, BadResponse, errorDecodingData, invalidURL
}

class HttpClient{
    private init(){}
    
    static let shared = HttpClient()
    
    func fetch <T: Codable>(url:URL) async throws ->[T] {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else{
            throw HttpEroor.BadResponse
        }
        
        guard let object = try? JSONDecoder().decode([T].self, from: data) else {
            throw HttpEroor.errorDecodingData
        }
        return object
    }
    func sendData<T: Codable>(to url: URL, object : T, httpMethod: String) async throws {
        var request = URLRequest(url: url)
        
        request.httpMethod = httpMethod
        request.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HttpHeaders.contentType.rawValue)
        
        request.httpBody = try? JSONEncoder().encode(object)
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else{
            throw HttpEroor.BadResponse
        }
        
    }
    
    func sendData2<T: Encodable>(to url: URL, object: T?, httpMethod: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let object = object {
            request.httpBody = try JSONEncoder().encode(object)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return data
    }
    func delete(at id:UUID, url: URL) async throws{
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethods.DELETE.rawValue
        let (_,response) = try await URLSession.shared.data(for: request)
        
        guard(response as? HTTPURLResponse)?.statusCode == 200 else{
            throw HttpEroor.BadResponse
        }
    }
}

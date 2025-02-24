//
//  NetworkUtils.swift
//  PokeDex
//
//  Created by NTTData on 27/08/23.
//

import Foundation
import OSLog

class NetworkUtils {
    static let shared = NetworkUtils()

    func fetch<T: Codable>(from url: URL) async throws -> T {
        var request = URLRequest(url: url)
        Logger.api.debug("Fetch: calling - \(url)") // loggin call message
        request.timeoutInterval = Constants.pokeApiTimeoutInterval

        let (data, response) = try await URLSession.shared.data(for: request)
        if let dataString = String(data: data, encoding: .utf8) {
                   Logger.api.info("\(dataString)") // Service response
               }

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        Logger.api.debug("/user: calling Success - \(httpResponse.statusCode)")
        let decodedData = try JSONDecoder().decode(T.self, from: data)
        return decodedData
    }
}

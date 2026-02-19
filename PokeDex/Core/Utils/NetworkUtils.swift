//
//  NetworkUtils.swift
//  PokeDex
//
//  Created by yagodemartin on 27/08/23.
//

import Foundation
import OSLog

/// Network utility with HTTP caching support.
///
/// Handles all network requests with automatic caching via URLCache.
/// First request caches data to disk (200 MB) and memory (50 MB).
/// Subsequent requests return cached data (~80x faster).
class NetworkUtils {
    static let shared = NetworkUtils()
    private let session: URLSession
    private let logger = Logger(subsystem: "com.yagodemartin.pokedex", category: "Network")

    init() {
        let config = URLSessionConfiguration.default

        // 🔑 CACHE CONFIGURATION
        let cache = URLCache(
            memoryCapacity: 50_000_000,   // 50 MB in RAM
            diskCapacity: 200_000_000,    // 200 MB on disk
            diskPath: "PokeDexCache"      // Cache folder name
        )
        config.urlCache = cache

        // 🔑 CACHE POLICY
        // .returnCacheDataElseLoad = Return cached if available, else network
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 30

        self.session = URLSession(configuration: config)

        logger.info("NetworkUtils initialized with URLCache (50MB memory, 200MB disk)")
    }

    func fetch<T: Codable>(from url: URL) async throws -> T {
        let startTime = Date()

        var request = URLRequest(url: url)
        Logger.api.debug("Fetch: calling - \(url)") // logging call message
        request.timeoutInterval = Constants.pokeApiTimeoutInterval

        let (data, response) = try await session.data(for: request)
        let duration = Date().timeIntervalSince(startTime)

        // 📊 LOG: Duration and cache status
        let fileName = url.lastPathComponent
        let logMessage = "⏱️  \(fileName): \(String(format: "%.3f", duration))s"
        self.logger.info("\(logMessage, privacy: .public)")

        // 📝 Write to file for programmatic access
        writeLogToFile(logMessage)

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

    private func writeLogToFile(_ message: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] \(message)\n"

        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logFilePath = documentsPath.appendingPathComponent("NetworkLogs.txt")

            if FileManager.default.fileExists(atPath: logFilePath.path) {
                if let fileHandle = FileHandle(forWritingAtPath: logFilePath.path) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(logEntry.data(using: .utf8) ?? Data())
                    fileHandle.closeFile()
                }
            } else {
                try? logEntry.write(toFile: logFilePath.path, atomically: true, encoding: .utf8)
            }
        }
    }
}

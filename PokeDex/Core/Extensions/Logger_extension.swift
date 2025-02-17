//
//  Logger_extension.swift
//  PokeDex
//
//  Created by yamartin on 14/2/25.
//

import OSLog

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like a view that appeared.
    static let viewCycle = Logger(subsystem: subsystem, category: "viewcycle")

    /// All logs related to tracking and analytics.
    static let api = Logger(subsystem: subsystem, category: "API")
}

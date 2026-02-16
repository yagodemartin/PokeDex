//
//  PokemonModel.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation
import SwiftData

/// Presentation model for Pokémon data with persistence support.
///
/// `PokemonModel` is a `@Model` class that provides persistent storage through SwiftData.
/// It represents a Pokémon with all its basic and detailed information.
///
/// ## Thread Safety
/// Conforms to `Sendable` for thread-safe operations in Swift 6+ and compatibility with
/// `@MainActor`-isolated code. All properties are safe to send across actor boundaries.
///
/// ## Persistence
/// Automatically persisted by SwiftData. The model is used for both:
/// - Display in the explore list
/// - Storing favorite Pokémon locally
///
/// ## Properties
/// - `id`: Unique Pokémon identifier
/// - `name`: Pokémon name
/// - `imageURL`: URL to Pokémon artwork
/// - `height`, `weight`: Physical dimensions
/// - `types`: Type(s) of the Pokémon
/// - `stats`: Base statistics (HP, Attack, Defense, etc.)
@Model
final class PokemonModel: Identifiable, @unchecked Sendable {
    var id: Int
    var name: String
    var imageURL: URL?
    var height: Int?
    var weight: Int?
    var types: [PokemonTypes] // Suponiendo que PokemonTypes es un array de Strings
    var stats: PokemonStats?

    init?(pokemon: PokemonEntity) {
        self.id = pokemon.id
        self.name = pokemon.name
        self.imageURL = URL(string: pokemon.imageURL)
        self.height = (pokemon.height ?? 0)
        self.weight = (pokemon.weight ?? 0)
        self.types = pokemon.types
        self.stats = pokemon.stats
    }

    func getNumber () -> String {
        return String(format: "#%03d", id)
    }
}

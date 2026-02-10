//
//  PokemonEntity.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

/// A domain entity representing a Pokémon with its core attributes.
///
/// `PokemonEntity` is a pure domain model that represents a Pokémon in the system.
/// It's independent of how the data is fetched or persisted, making it the single
/// source of truth for Pokémon data across all layers of the application.
///
/// ## Overview
/// This entity contains:
/// - Basic identification (ID, name)
/// - Visual representation (image URL)
/// - Physical attributes (height, weight)
/// - Type information (elemental types)
/// - Combat statistics (HP, Attack, Defense, etc.)
///
/// ## Initialization
/// The entity can be created from two types of API responses:
/// - `PokemonResponseModel`: Basic list response (ID and name only)
/// - `PokemonDetailReponseModel`: Detailed response (all attributes)
///
/// ## Usage
/// ```swift
/// // From list response
/// let pokemon = PokemonEntity(pokemonResponse: listItem)
///
/// // From detail response
/// let pokemonWithDetails = PokemonEntity(
///     pokemonDetailResponse: detailResponse
/// )
/// ```
struct PokemonEntity {
    /// The unique identifier for the Pokémon (1-1025+).
    let id: Int

    /// The name of the Pokémon (e.g., "Charizard").
    let name: String

    /// The URL string to the official Pokémon artwork image.
    /// Typically from GitHub's official Pokémon sprites repository.
    var imageURL: String

    /// The height of the Pokémon in decimeters (optional).
    /// For example, 17 means 1.7 meters.
    var height: Int?

    /// The weight of the Pokémon in hectograms (optional).
    /// For example, 90 means 9.0 kg.
    var weight: Int?

    /// The elemental types of the Pokémon (Fire, Water, Grass, etc.).
    /// A Pokémon can have up to two types.
    var types: [PokemonTypes] = []

    /// The combat statistics of the Pokémon (optional).
    /// Includes HP, Attack, Defense, Special Attack, Special Defense, and Speed.
    var stats: PokemonStats?

    init?(pokemonResponse: PokemonResponseModel) {
        guard let urlComponents = URLComponents(string: pokemonResponse.url),
              let idString = urlComponents.path.split(separator: "/").last,
              let id = Int(idString) else {
            return nil
        }

        self.id = id
        self.name = pokemonResponse.name
        self.imageURL = Constants.APIEndpoint.getPokemonImage(id: id).url?.absoluteString ?? ""
    }

    init?(pokemonDetailResponse: PokemonDetailReponseModel) {
        self.id = pokemonDetailResponse.id
        self.name = pokemonDetailResponse.name
        self.imageURL = Constants.APIEndpoint.getPokemonImage(id: id).url?.absoluteString ?? ""
        self.height = pokemonDetailResponse.height
        self.weight = pokemonDetailResponse.weight

        self.types = pokemonDetailResponse.types.compactMap({ typeElement in
           return PokemonTypes(rawValue: typeElement.type.name)
        })
        self.stats = PokemonStats(from: pokemonDetailResponse.stats)
    }
}

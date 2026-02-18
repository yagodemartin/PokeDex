//
//  FavoritePokemonDTO.swift
//  PokeDex
//
//  Created by yamartin on 18/2/26.
//

import Foundation
import SwiftData

/// Data Transfer Object for storing Pokémon favorites in SwiftData.
///
/// Complete DTO that stores all Pokémon data independently from PokemonModel.
/// This prevents assertion failures when PokemonModel is modified or deleted.
/// All fields are copied from PokemonModel to create a persistent snapshot.
@Model
final class FavoritePokemonDTO {
    var pokemonID: Int
    var name: String
    var imageURL: URL?
    var height: Int?
    var weight: Int?
    var types: [PokemonTypes]
    var stats: PokemonStats?

    init(
        pokemonID: Int,
        name: String,
        imageURL: URL? = nil,
        height: Int? = nil,
        weight: Int? = nil,
        types: [PokemonTypes] = [],
        stats: PokemonStats? = nil
    ) {
        self.pokemonID = pokemonID
        self.name = name
        self.imageURL = imageURL
        self.height = height
        self.weight = weight
        self.types = types
        self.stats = stats
    }
}

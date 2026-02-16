//
//  PokemonTypes.swift
//  PokeDex
//
//  Created by yamartin on 17/

import Foundation
import SwiftUI

/// Enum representing Pokémon types with associated colors and icons.
///
/// Covers all 18 Pokémon types plus an unknown type for error cases.
/// Each type has an associated color and icon image for UI display.
enum PokemonTypes: String, Codable, Sendable {
    case normal
    case fire
    case fighting
    case water
    case flying
    case grass
    case poison
    case electric
    case ground
    case psychic
    case rock
    case ice
    case bug
    case dragon
    case ghost
    case dark
    case steel
    case fairy
    case unknown

    // MARK: - Static Mappings

    /// Mapping of Pokémon types to their color name identifiers.
    ///
    /// Used to reduce cyclomatic complexity from O(n) switch statements
    /// to O(1) dictionary lookups. Maps type to Asset Catalog color names.
    private static let colorNameMap: [PokemonTypes: String] = [
        .normal: "normal",
        .fire: "fire",
        .fighting: "fighting",
        .water: "water",
        .flying: "flying",
        .grass: "grass",
        .poison: "poison",
        .electric: "electric",
        .ground: "ground",
        .psychic: "psychic",
        .rock: "rock",
        .ice: "ice",
        .bug: "bug",
        .dragon: "dragon",
        .ghost: "ghost",
        .dark: "dark",
        .steel: "steel",
        .fairy: "fairy",
        .unknown: "unkwnown"
    ]

    /// Mapping of Pokémon types to their icon image names.
    ///
    /// Used to reduce cyclomatic complexity from O(n) switch statements
    /// to O(1) dictionary lookups. Each type has an associated icon.
    private static let imageMap: [PokemonTypes: String] = [
        .normal: "normal",
        .fire: "fire",
        .fighting: "fighting",
        .water: "water",
        .flying: "flying",
        .grass: "grass",
        .poison: "poison",
        .electric: "electric",
        .ground: "ground",
        .psychic: "psychic",
        .rock: "rock",
        .ice: "ice",
        .bug: "bug",
        .dragon: "dragon",
        .ghost: "ghost",
        .dark: "dark",
        .steel: "steel",
        .fairy: "fairy",
        .unknown: "fire"
    ]

    // MARK: - Public Methods

    /// Returns the UI color associated with this Pokémon type.
    ///
    /// Uses dictionary lookup for O(1) performance instead of
    /// switch statement with O(n) cyclomatic complexity.
    ///
    /// - Returns: Color value for this type
    func getColor() -> Color {
        let colorName = Self.colorNameMap[self] ?? "normal"
        return Color(colorName)
    }

    /// Returns the icon image for this Pokémon type.
    ///
    /// Uses dictionary lookup for O(1) performance instead of
    /// switch statement with O(n) cyclomatic complexity.
    ///
    /// - Returns: Image for this type
    func getImage() -> Image {
        let imageName = Self.imageMap[self] ?? "normal"
        return Image(imageName)
    }
}

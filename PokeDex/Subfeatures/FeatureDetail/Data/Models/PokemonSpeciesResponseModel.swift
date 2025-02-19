//
//  PokemonSpecies.swift
//  PokeDex
//
//  Created by yamartin on 18/2/25.
//


import Foundation

struct PokemonSpeciesResponseModel: Codable {
    let id: Int
    let name: String
    let order: Int
    let genderRate: Int
    let captureRate: Int
    let baseHappiness: Int
    let isBaby: Bool
    let isLegendary: Bool
    let isMythical: Bool
    let hatchCounter: Int
    let hasGenderDifferences: Bool
    let formsSwitchable: Bool
    let growthRate: NamedAPIResource
    let pokedexNumbers: [PokedexNumber]
    let eggGroups: [NamedAPIResource]
    let color: NamedAPIResource
    let shape: NamedAPIResource
    let evolvesFromSpecies: NamedAPIResource?
    let evolutionChain: APIResource
    let habitat: NamedAPIResource?
    let generation: NamedAPIResource
    let names: [Name]
    let flavorTextEntries: [FlavorText]
    let formDescriptions: [Description]
    let genera: [Genus]
    let varieties: [Variety]

    enum CodingKeys: String, CodingKey {
        case id, name, order
        case genderRate = "gender_rate"
        case captureRate = "capture_rate"
        case baseHappiness = "base_happiness"
        case isBaby = "is_baby"
        case isLegendary = "is_legendary"
        case isMythical = "is_mythical"
        case hatchCounter = "hatch_counter"
        case hasGenderDifferences = "has_gender_differences"
        case formsSwitchable = "forms_switchable"
        case growthRate = "growth_rate"
        case pokedexNumbers = "pokedex_numbers"
        case eggGroups = "egg_groups"
        case color, shape
        case evolvesFromSpecies = "evolves_from_species"
        case evolutionChain = "evolution_chain"
        case habitat, generation, names
        case flavorTextEntries = "flavor_text_entries"
        case formDescriptions = "form_descriptions"
        case genera, varieties
    }
}

struct NamedAPIResource: Codable {
    let name: String
    let url: String
}

struct APIResource: Codable {
    let url: String
}

struct PokedexNumber: Codable {
    let entryNumber: Int
    let pokedex: NamedAPIResource

    enum CodingKeys: String, CodingKey {
        case entryNumber = "entry_number"
        case pokedex
    }
}

struct Name: Codable {
    let name: String
    let language: NamedAPIResource
}

struct FlavorText: Codable {
    let flavorText: String
    let language: NamedAPIResource
    let version: NamedAPIResource

    enum CodingKeys: String, CodingKey {
        case flavorText = "flavor_text"
        case language, version
    }
}

struct Description: Codable {
    let description: String
    let language: NamedAPIResource
}

struct Genus: Codable {
    let genus: String
    let language: NamedAPIResource
}

struct Variety: Codable {
    let isDefault: Bool
    let pokemon: NamedAPIResource

    enum CodingKeys: String, CodingKey {
        case isDefault = "is_default"
        case pokemon
    }
}

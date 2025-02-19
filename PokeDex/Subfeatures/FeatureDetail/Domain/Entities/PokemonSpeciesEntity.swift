//
//  PokemonSpeciesEntity.swift
//  PokeDex
//
//  Created by yamartin on 18/2/25.
//
import Foundation


struct PokemonSpeciesEntity {
    
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
    let habitat: NamedAPIResource?
    let shape: NamedAPIResource?
    let color: NamedAPIResource
    let evolvesFromSpecies: NamedAPIResource?
    let evolutionChain: APIResource
    let flavorTextEntries: [FlavorText]
    let genera: [Genus]
    let names: [Name]
    
    init?(from model: PokemonSpeciesResponseModel) {
        self.id = model.id
        self.name = model.name
        self.order = model.order
        self.genderRate = model.genderRate
        self.captureRate = model.captureRate
        self.baseHappiness = model.baseHappiness
        self.isBaby = model.isBaby
        self.isLegendary = model.isLegendary
        self.isMythical = model.isMythical
        self.hatchCounter = model.hatchCounter
        self.hasGenderDifferences = model.hasGenderDifferences
        self.formsSwitchable = model.formsSwitchable
        self.growthRate = model.growthRate
        self.habitat = model.habitat
        self.shape = model.shape
        self.color = model.color
        self.evolvesFromSpecies = model.evolvesFromSpecies
        self.evolutionChain = model.evolutionChain
        self.flavorTextEntries = model.flavorTextEntries
        self.genera = model.genera
        self.names = model.names
    }
}


struct FlavorTextEntry: Codable{
    
    let flavorText: String
    let language: NamedAPIResource
    let version: NamedAPIResource
}

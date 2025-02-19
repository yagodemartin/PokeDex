//
//  PokemonModel.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

struct PokemonModel: Identifiable {
    let id: Int
    let name: String
    var imageURL: URL?
    var height: Int?
    var weight: Int?
    var types: [PokemonTypes] = []
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

//
//  PokemonModel.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

struct PokemonModel: Hashable {
    let id: Int
    let name: String
    var imageURL: URL?
    var height: Int?
    var weight: Int?

    init?(pokemon: PokemonEntity) {
        self.id = pokemon.id
        self.name = pokemon.name
        self.imageURL = URL(string: pokemon.imageURL)
        self.height = pokemon.height
        self.weight = pokemon.weight
    }
}

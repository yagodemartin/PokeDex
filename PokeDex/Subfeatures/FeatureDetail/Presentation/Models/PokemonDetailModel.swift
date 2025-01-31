//
//  PokemonDetailModel.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

struct PokemonDetailModel {
    let pokemon: PokemonModel
    let height: Int
    let weight: Int

    init?(pokemonDetail: PokemonDetailEntity) {
        guard let pokemon = PokemonModel(pokemon: pokemonDetail.pokemon) else {
            return nil
        }

        self.pokemon = pokemon
        self.height = pokemonDetail.height
        self.weight = pokemonDetail.weight
    }
}

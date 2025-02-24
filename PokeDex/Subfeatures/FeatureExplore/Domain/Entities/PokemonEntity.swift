//
//  PokemonEntity.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

struct PokemonEntity {
    let id: Int
    let name: String
    var imageURL: String
    var height: Int?
    var weight: Int?
    var types: [PokemonTypes] = []
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

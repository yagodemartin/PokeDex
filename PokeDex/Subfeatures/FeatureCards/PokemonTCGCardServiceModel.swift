//
//  PokemonTCGCardServiceModel.swift
//  PokeDex
//
//  Created by yamartin on 19/3/25.
//

import Foundation

struct PokemonTCGCardServiceModel: Codable {
    let id: String
    let name: String
    let set: CardSet
    let images: Images

    struct CardSet: Codable {
        let name: String
    }

    struct Images: Codable {
        let small: String
    }
}

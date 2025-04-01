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
    let set: Set
    let images: Images
    
    struct Set: Codable {
        let name: String
    }
    
    struct Images: Codable {
        let small: String
    }
}

//
//  PokemonResponseModel.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

struct PokemonResponseModel: Decodable, Encodable {
    let name: String
    let url: String
}

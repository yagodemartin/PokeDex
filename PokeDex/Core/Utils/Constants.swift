//
//  Constants.swift
//  PokeDex
//
//  Created by NTTData on 27/08/23.
//

import Foundation

struct Constants {
    static let pokeApiURL: String = "https://pokeapi.co/api/v2/"
    static let pokeApiArtworkURL: String = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/%d.png"
    static let pokeApiTimeoutInterval: Double = 15.0

    static let pokeApiPokemonListlimit: Int = 5000
    
    enum APIEndpoint {
        case getPokemonList(limit: Int)
        case getPokemonImage(id: Int)
        case getPokemonDetails(id: Int)
        case getPokemonElements(id: Int)
        var url: URL? {
            switch self {
            case .getPokemonList(let limit):
                return URL(string: "\(pokeApiURL)pokemon?limit=\(limit)")
            case .getPokemonImage(let id):
                return URL(string: String(format: pokeApiArtworkURL, id))
            case .getPokemonDetails(let id):
                return URL(string: "\(pokeApiURL)pokemon/\(id)/")
            case .getPokemonElements(let id):
                return URL(string: "\(pokeApiURL)pokemon/\(id)/")
            }
        }
    }
}

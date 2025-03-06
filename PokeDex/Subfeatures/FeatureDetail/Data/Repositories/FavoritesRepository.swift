//
//  FavoritesRepository.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

import Foundation

@MainActor
class FavoritesRepository: FavoritesRepositoryProtocol {
    static let shared = FavoritesRepository()

    private init() {} // Implementación de singleton

    func addPokemonToFavorites(pokemon: PokemonModel) {
        FavouritesDataSource.shared.addPokemonToFavorites(pokemon: pokemon)
    }

    func removePokemonFromFavorites(pokemon: PokemonModel) {
        FavouritesDataSource.shared.removePokemonFromFavorites(pokemon: pokemon)
    }

    func fetchAllFavoritePokemons() -> [PokemonModel] {
        FavouritesDataSource.shared.fetchPokemons()
    }

    func isPokemonFavorite(pokemon: PokemonModel) -> Bool {
        return FavouritesDataSource.shared.isPokemonFavorite(pokemon: pokemon)
    }
}

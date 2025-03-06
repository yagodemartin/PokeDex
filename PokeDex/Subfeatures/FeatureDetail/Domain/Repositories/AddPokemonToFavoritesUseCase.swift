//
//  AddPokemonToFavoritesUseCase.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//


class AddPokemonToFavoritesUseCase {
    let repository: FavoritesRepositoryProtocol

    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    /// Executes the use case to add a Pokémon to the favorites list.
    /// - Parameter pokemon: The PokemonModel object to be added to favorites.
    func execute(pokemon: PokemonModel) async throws {
        try await repository.addPokemonToFavorites(pokemon: pokemon)
    }
}
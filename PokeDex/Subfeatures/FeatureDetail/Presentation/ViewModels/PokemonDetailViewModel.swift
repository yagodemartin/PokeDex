//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import Foundation
import SwiftData

/// ViewModel for displaying detailed Pokémon information.
///
/// `PokemonDetailViewModel` manages the presentation logic for the Pokémon detail screen.
/// It handles loading Pokémon details, species information, and favorite status management.
///
/// ## Responsibilities
/// - Fetch detailed Pokémon information from the API
/// - Fetch Pokémon species and flavor text information
/// - Manage favorite/unfavorite operations with error handling
/// - Manage view states and error dialogs
///
/// ## Data Flow
/// The view model uses multiple use cases to access data through the repository pattern,
/// ensuring clean separation of concerns and proper error propagation.
@MainActor
class PokemonDetailViewModel: BaseViewModel, ObservableObject {
    var dto: PokemonDetailAssemblyDTO?

    init(dto: PokemonDetailAssemblyDTO?) {
        self.dto = dto
    }

    let getPokemonDetailUseCase = GetPokemonDetailUseCase(repository: DetailRepository())
    let getPokemonDetailSpecieUseCase = GetPokemonDetailSpecieUseCase(repository: DetailRepository())

    /// Use case for adding Pokémon to favorites with error handling
    let addFavoriteUseCase = AddPokemonToFavoritesUseCase(repository: FavoritesRepository.shared)
    /// Use case for removing Pokémon from favorites with error handling
    let removeFavoriteUseCase = RemovePokemonFromFavoritesUseCase(repository: FavoritesRepository.shared)

    @Published var pokemonDetail: PokemonModel?
    @Published var pokemonDetailSpecie: PokemonSpecieModel?

    override func onAppear() {
        self.loadDetail()
        self.loadSpecie()
    }

    /// Loads detailed Pokémon information from the API.
    ///
    /// Fetches the Pokémon details using the use case and updates the view model state.
    /// On success, sets state to `.okey`.
    /// On failure, sets state to `.error` and displays an error dialog.
    ///
    /// - Note: This method is called during the view lifecycle (onAppear).
    func loadDetail() {
        guard let idPokemon = dto?.idPokemon else {
            return
        }

        Task {
            do {
                guard let pokemonDetailEntity: PokemonEntity = try await getPokemonDetailUseCase.execute(id: idPokemon) else {
                    return
                }

                self.pokemonDetail = PokemonModel(pokemon: pokemonDetailEntity)
            } catch {
                self.state = .error
                self.showWarningError = true
                self.logError("Failed to load pokemon detail: \(error)")
            }
        }
    }

    /// Loads Pokémon species information including flavor text from the API.
    ///
    /// Fetches species-specific data using the use case and updates the view model state.
    /// On success, sets state to `.okey`.
    /// On failure, sets state to `.error` and displays an error dialog.
    ///
    /// - Note: This method is called during the view lifecycle (onAppear).
    func loadSpecie() {
        guard let idPokemon = dto?.idPokemon else {
            return
        }

        Task {
            do {
                guard let pokemonSpeciesEntity: PokemonSpeciesEntity = try await getPokemonDetailSpecieUseCase.execute(id: idPokemon) else {
                    return
                }

                self.pokemonDetailSpecie = PokemonSpecieModel(pokemon: pokemonSpeciesEntity)
            } catch {
                self.state = .error
                self.showWarningError = true
                self.logError("Failed to load pokemon specie: \(error)")
            }
        }
    }

    /// Handles the like/favorite button press with async error handling.
    ///
    /// This method manages adding or removing a Pokémon from favorites through the appropriate use case.
    /// It provides proper error handling and user feedback:
    /// - Shows loading state
    /// - Updates state to `.okey` on success
    /// - Sets state to `.error` and displays error dialog on failure
    /// - Logs all errors for debugging
    ///
    /// Passes Pokémon ID instead of model instance for thread-safety with @MainActor.
    ///
    /// - Parameter liked: Boolean indicating whether the Pokémon should be added (`true`) or removed (`false`) from favorites.
    func likeButtonPressed(liked: Bool) {
        guard let pokemonToSave = self.pokemonDetail else {
            return
        }
        Task {
            do {
                if liked {
                    try await addFavoriteUseCase.execute(pokemonID: pokemonToSave.id)
                } else {
                    try await removeFavoriteUseCase.execute(pokemonID: pokemonToSave.id)
                }
                self.state = .okey
            } catch {
                self.state = .error
                self.showWarningError = true
                self.logError("Failed to update favorite: \(error)")
            }
        }
    }
}

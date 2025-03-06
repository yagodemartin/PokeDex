//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import Foundation

@MainActor
class FeatureFavoritesViewModel: BaseViewModel, ObservableObject {
    var dto: FeatureFavoritesDTO?
    @Published var favorites = [PokemonModel]()

    init(dto: FeatureFavoritesDTO) {
        super.init()
        // Inicializar con datos del DTO
    }

    let getFavoritesUseCase = FetchAllFavoritePokemonsUseCase(repository: FavoritesRepository.shared)

    override func onAppear() {
        loadFavorites()
    }

    func loadFavorites() {
        Task {
            do {
                favorites = try await getFavoritesUseCase.execute()
                print(favorites.count)
            } catch {
                print("Error: \(error)")
            }
        }
    }

    @MainActor func errorViewAction(action: CustomErrorAction) {
            switch action {
            case .retry:
                self.loadFavorites()

            case .exit:
                showWarningError = false
            }
        }
}

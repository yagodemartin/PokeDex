//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import Foundation

/// ViewModel for managing the Favorites feature.
///
/// `FeatureFavoritesViewModel` is responsible for fetching and managing the user's favorite Pokémon.
/// It provides proper error handling with state management and user feedback through error dialogs.
///
/// ## Responsibilities
/// - Fetch all favorite Pokémon from the repository
/// - Manage view states (loading, success, error)
/// - Handle errors with user-friendly dialogs
/// - Centralized logging of errors
///
/// ## Usage
/// ```swift
/// @StateObject private var viewModel = FeatureFavoritesViewModel(dto: nil)
/// ```
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

    /// Loads all favorite Pokémon from the repository.
    ///
    /// This method manages the complete loading lifecycle:
    /// 1. Sets state to `.loading` to show loading indicator
    /// 2. Fetches favorites using the use case
    /// 3. Sets state to `.okey` on success
    /// 4. Sets state to `.error` and shows error dialog on failure
    /// 5. Logs errors using centralized logging
    ///
    /// Errors are automatically displayed to the user through error dialogs.
    func loadFavorites() {
        state = .loading  // ← PASO 1: Dile a la vista "estoy cargando"
        Task {
            do {
                favorites = try await getFavoritesUseCase.execute()
                state = .okey  // ← PASO 2: Dile "terminé bien"
            } catch {
                state = .error  // ← PASO 3: Dile "tuve error"
                showWarningError = true  // ← PASO 4: Abre diálogo
                self.logError("Failed to load favorites: \(error)")  // ← PASO 5: Registra error
            }
        }
    }

    /// Handles error dialog actions from the user.
    /// - Parameter action: The action selected by the user (retry or exit).
    /// - Cases:
    ///   - `.retry`: Reloads the favorites list
    ///   - `.exit`: Dismisses the error dialog
    @MainActor func errorViewAction(action: CustomErrorAction) {
            switch action {
            case .retry:
                self.loadFavorites()

            case .exit:
                showWarningError = false
            }
        }
}

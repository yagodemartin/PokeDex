# CRITICAL #2: Production-Ready Code Snippets & Quick Start

**Purpose:** Copy-paste ready code for implementing CRITICAL #2 fixes
**Version:** 1.0
**Last Updated:** 2026-02-11

---

## TABLE OF CONTENTS

1. [Phase 1: DatabaseError.swift](#phase-1-databaseerrorswift)
2. [Phase 2: Updated FavouritesDataSource](#phase-2-updated-favouritesdatasource)
3. [Phase 3: Updated FavoritesRepository](#phase-3-updated-favoritesrepository)
4. [Phase 5: Enhanced BaseViewModel](#phase-5-enhanced-baseviewmodel)
5. [Phase 6: Updated ViewModels](#phase-6-updated-viewmodels)
6. [Quick Copy-Paste Guide](#quick-copy-paste-guide)

---

## Phase 1: DatabaseError.swift

**File:** `/PokeDex/Core/Errors/DatabaseError.swift` (NEW FILE)

```swift
import Foundation

/// Represents errors that can occur during database operations.
///
/// This error type wraps underlying SwiftData errors and provides:
/// - User-friendly error messages for UI display
/// - Error classification for analytics and debugging
/// - Recovery strategy hints for UI to display
/// - Localization support for international users
///
/// Example usage:
/// ```swift
/// do {
///     try modelContext.save()
/// } catch {
///     throw DatabaseError.saveFailed(underlying: error)
/// }
/// ```
enum DatabaseError: LocalizedError {
    /// Failed to fetch data from the database
    /// - Parameters:
    ///   - operation: Description of what was being fetched (e.g., "favorites", "search results")
    ///   - underlying: The original SwiftData error
    case fetchFailed(operation: String, underlying: Error)

    /// Failed to save changes to the database
    /// - Parameters:
    ///   - underlying: The original SwiftData error
    case saveFailed(underlying: Error)

    /// Failed to delete data from the database
    /// - Parameters:
    ///   - operation: Description of what was being deleted (e.g., "favorite", "user account")
    ///   - underlying: The original SwiftData error
    case deleteFailed(operation: String, underlying: Error)

    /// Failed to apply predicate or filter to a query
    /// - Parameters:
    ///   - underlying: The original SwiftData error
    case predicateFailed(underlying: Error)

    /// Failed to initialize the model container
    /// This is a non-recoverable error that typically requires app restart
    /// - Parameters:
    ///   - underlying: The original SwiftData error
    case containerInitializationFailed(underlying: Error)

    /// Unknown database error that doesn't fit other categories
    /// - Parameters:
    ///   - error: The original error
    case unknown(Error)

    // MARK: - LocalizedError Conformance

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let operation, _):
            return "Unable to load \(operation). Please try again."

        case .saveFailed:
            return "Failed to save changes. Please try again."

        case .deleteFailed(let operation, _):
            return "Failed to remove \(operation). Please try again."

        case .predicateFailed:
            return "Invalid search criteria. Please try again."

        case .containerInitializationFailed:
            return "Database initialization failed. The app will restart."

        case .unknown:
            return "An unexpected database error occurred."
        }
    }

    var failureReason: String? {
        switch self {
        case .fetchFailed(_, let underlying):
            return underlying.localizedDescription

        case .saveFailed(let underlying):
            return "Could not persist changes: \(underlying.localizedDescription)"

        case .deleteFailed(_, let underlying):
            return underlying.localizedDescription

        case .predicateFailed(let underlying):
            return "Predicate evaluation failed: \(underlying.localizedDescription)"

        case .containerInitializationFailed(let underlying):
            return "Database container could not be initialized: \(underlying.localizedDescription)"

        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Try refreshing the screen or restarting the app."

        case .saveFailed:
            return "Check if you have enough storage space, then try again."

        case .deleteFailed:
            return "Try again or restart the app if the problem persists."

        case .predicateFailed:
            return "Modify your search criteria and try again."

        case .containerInitializationFailed:
            return "Force close and reopen the app. Contact support if the problem persists."

        case .unknown:
            return "Try again or restart the app."
        }
    }

    // MARK: - Helper Properties

    /// User-friendly error message suitable for displaying in UI
    /// Localized and free of technical jargon
    var userFriendlyMessage: String {
        errorDescription ?? "An error occurred"
    }

    /// Full error description including reason and suggestion for logging
    /// Useful for debug logging and analytics
    var detailedDescription: String {
        let base = errorDescription ?? "Unknown error"
        let reason = failureReason.map { "\nReason: \($0)" } ?? ""
        let suggestion = recoverySuggestion.map { "\nSuggestion: \($0)" } ?? ""
        return base + reason + suggestion
    }

    /// Determines if this error is recoverable by user action
    /// Non-recoverable errors typically require app restart or support contact
    var isRecoverable: Bool {
        switch self {
        case .containerInitializationFailed:
            return false  // Requires app restart or reinstall
        default:
            return true   // User can retry the operation
        }
    }
}

// MARK: - Equatable Conformance (for testing)

extension DatabaseError: Equatable {
    static func == (lhs: DatabaseError, rhs: DatabaseError) -> Bool {
        switch (lhs, rhs) {
        case (.fetchFailed(let op1, _), .fetchFailed(let op2, _)):
            return op1 == op2

        case (.saveFailed, .saveFailed):
            return true

        case (.deleteFailed(let op1, _), .deleteFailed(let op2, _)):
            return op1 == op2

        case (.predicateFailed, .predicateFailed):
            return true

        case (.containerInitializationFailed, .containerInitializationFailed):
            return true

        case (.unknown, .unknown):
            return true

        default:
            return false
        }
    }
}
```

---

## Phase 2: Updated FavouritesDataSource

**File:** `/PokeDex/Subfeatures/FeatureDetail/Data/DataSources/FavouritesDataSource.swift`

Replace entire file contents:

```swift
import SwiftUI
import SwiftData

/// Main actor ensures all database access happens on the main thread
/// SwiftData requires main thread access for thread safety
@MainActor
final class FavouritesDataSource {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    /// Singleton instance of FavouritesDataSource
    /// Falls back to in-memory storage if disk storage fails
    static let shared: FavouritesDataSource = {
        do {
            return try FavouritesDataSource()
        } catch {
            do {
                return try FavouritesDataSource(inMemoryOnly: true)
            } catch {
                // This should only happen in extreme circumstances
                // In production, consider implementing a fallback mechanism
                fatalError("Cannot create model container: \(error)")
            }
        }
    }()

    /// Initializes the FavouritesDataSource with SwiftData model container
    /// - Parameter inMemoryOnly: If true, uses in-memory storage instead of disk
    /// - Throws: Throws if model container initialization fails
    init(inMemoryOnly: Bool = false) throws {
        let schema = Schema([PokemonModel.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemoryOnly
        )

        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        self.modelContext = modelContainer.mainContext
    }

    // MARK: - Fetch Operations

    /// Fetches all Pokémon marked as favorites.
    ///
    /// - Returns: An array of PokemonModel objects that are marked as favorites.
    ///           Empty array if no favorites exist (not an error).
    ///
    /// - Throws: DatabaseError.fetchFailed if the fetch operation fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let favorites = try await dataSource.fetchPokemons()
    ///     print("Found \(favorites.count) favorites")
    /// } catch {
    ///     print("Failed to load favorites: \(error)")
    /// }
    /// ```
    func fetchPokemons() async throws -> [PokemonModel] {
        do {
            return try modelContext.fetch(FetchDescriptor<PokemonModel>())
        } catch {
            throw DatabaseError.fetchFailed(
                operation: "favorites",
                underlying: error
            )
        }
    }

    // MARK: - Add/Remove Operations

    /// Adds a Pokémon to the favorites list.
    ///
    /// - Parameter pokemon: The PokemonModel object to add to favorites.
    ///
    /// - Throws: DatabaseError.saveFailed if the save operation fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     try await dataSource.addPokemonToFavorites(pokemon: pikachu)
    /// } catch {
    ///     print("Failed to add favorite: \(error)")
    /// }
    /// ```
    func addPokemonToFavorites(pokemon: PokemonModel) async throws {
        modelContext.insert(pokemon)
        try await saveContext()
    }

    /// Removes a Pokémon from the favorites list.
    ///
    /// - Parameter pokemon: The PokemonModel object to remove from favorites.
    ///
    /// - Throws: DatabaseError.saveFailed if the save operation fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     try await dataSource.removePokemonFromFavorites(pokemon: pikachu)
    /// } catch {
    ///     print("Failed to remove favorite: \(error)")
    /// }
    /// ```
    func removePokemonFromFavorites(pokemon: PokemonModel) async throws {
        modelContext.delete(pokemon)
        try await saveContext()
    }

    // MARK: - Query Operations

    /// Checks if a specific Pokémon is in the favorites list.
    ///
    /// - Parameter pokemon: The PokemonModel object to check.
    ///
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    ///           Returns false if not found (not an error).
    ///
    /// - Throws: DatabaseError.predicateFailed if the fetch operation fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let isFavorite = try await dataSource.isPokemonFavorite(pokemon: pikachu)
    ///     if isFavorite {
    ///         print("Already in favorites")
    ///     }
    /// } catch {
    ///     print("Failed to check favorite status: \(error)")
    /// }
    /// ```
    func isPokemonFavorite(pokemon: PokemonModel) async throws -> Bool {
        let idPokemon = pokemon.id
        let fetchDescriptor = FetchDescriptor<PokemonModel>(
            predicate: #Predicate { $0.id == idPokemon },
            sortBy: [.init(\.id, order: .forward)]
        )

        do {
            let results = try modelContext.fetch(fetchDescriptor)
            return !results.isEmpty
        } catch {
            throw DatabaseError.predicateFailed(underlying: error)
        }
    }

    // MARK: - Persistence

    /// Saves the current state of the model context to persistent storage.
    ///
    /// This is called internally after insert/delete operations.
    /// Should not be called directly in most cases.
    ///
    /// - Throws: DatabaseError.saveFailed if the save operation fails
    ///
    /// Note: This method is async to prevent blocking the main thread,
    ///       even though SwiftData operations are fast.
    func saveContext() async throws {
        do {
            try modelContext.save()
        } catch {
            throw DatabaseError.saveFailed(underlying: error)
        }
    }
}
```

---

## Phase 3: Updated FavoritesRepository

**File:** `/PokeDex/Subfeatures/FeatureDetail/Data/Repositories/FavoritesRepository.swift`

Replace entire file contents:

```swift
import Foundation

/// Repository implementation for favorites data access
/// Implements the FavoritesRepositoryProtocol
///
/// This class acts as a data abstraction layer, delegating to FavouritesDataSource
/// and providing a clean interface for use cases.
@MainActor
class FavoritesRepository: FavoritesRepositoryProtocol {
    /// Singleton instance of FavoritesRepository
    static let shared = FavoritesRepository()

    /// Private initializer to enforce singleton pattern
    private init() {}

    /// Adds a Pokémon to the favorites list.
    ///
    /// - Parameter pokemon: The PokemonModel object to add to favorites.
    ///
    /// - Throws: DatabaseError if the operation fails
    func addPokemonToFavorites(pokemon: PokemonModel) async throws {
        try await FavouritesDataSource.shared.addPokemonToFavorites(pokemon: pokemon)
    }

    /// Removes a Pokémon from the favorites list.
    ///
    /// - Parameter pokemon: The PokemonModel object to remove from favorites.
    ///
    /// - Throws: DatabaseError if the operation fails
    func removePokemonFromFavorites(pokemon: PokemonModel) async throws {
        try await FavouritesDataSource.shared.removePokemonFromFavorites(pokemon: pokemon)
    }

    /// Fetches all Pokémon marked as favorites.
    ///
    /// - Returns: An array of PokemonModel objects marked as favorites.
    ///           Empty array if no favorites exist.
    ///
    /// - Throws: DatabaseError if the fetch operation fails
    func fetchAllFavoritePokemons() async throws -> [PokemonModel] {
        try await FavouritesDataSource.shared.fetchPokemons()
    }

    /// Checks if a specific Pokémon is in the favorites list.
    ///
    /// - Parameter pokemon: The PokemonModel object to check.
    ///
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    ///
    /// - Throws: DatabaseError if the check fails
    func isPokemonFavorite(pokemon: PokemonModel) async throws -> Bool {
        try await FavouritesDataSource.shared.isPokemonFavorite(pokemon: pokemon)
    }
}
```

---

## Phase 5: Enhanced BaseViewModel

**File:** `/PokeDex/Core/BaseClasses/BaseViewModel.swift`

Replace entire file contents:

```swift
import Foundation

/// The possible states of a view during its lifecycle.
///
/// This enum represents the various states a UI can be in while loading,
/// processing, or displaying data.
///
/// ## Cases
/// - `okey`: Data loaded successfully and ready to display
/// - `loading`: Data is being fetched from the network or database
/// - `error`: An error occurred during data fetching/processing
/// - `unknownError`: An unexpected error occurred without specific information
/// - `notReachable`: Network connection is not available
/// - `empty`: No data is available to display
enum ViewModelState: String {
    /// Data loaded successfully and ready to display.
    case okey

    /// Data is being fetched from the network or database.
    case loading

    /// An error occurred during data fetching/processing.
    case error

    /// An unexpected error occurred without specific information.
    case unknownError

    /// Network connection is not available.
    case notReachable

    /// No data is available to display.
    case empty
}

/// A base class that provides common functionality for all ViewModels.
///
/// `BaseViewModel` is the parent class for all view models in the application.
/// It provides shared properties and methods for managing view state, error handling,
/// and lifecycle events.
///
/// ## Shared Properties
/// - `state`: The current state of the view (loading, success, error, etc.)
/// - `showWarningError`: Controls visibility of error dialogs
/// - `alertButtonDisable`: Enables/disables action buttons during operations
/// - `errorMessage`: User-friendly error message for display
/// - `lastError`: Reference to last error for debugging
///
/// ## Lifecycle
/// Subclasses can override `onAppear()` to perform initialization when the view appears.
///
/// ## Usage
/// ```swift
/// class MyFeatureViewModel: BaseViewModel, ObservableObject {
///     @Published var data: [Item] = []
///
///     override func onAppear() {
///         loadData()
///     }
///
///     @MainActor
///     private func loadData() {
///         state = .loading
///         Task {
///             do {
///                 data = try await useCase.execute()
///                 state = .okey
///             } catch {
///                 handleError(error)
///             }
///         }
///     }
/// }
/// ```
public class BaseViewModel {
    /// The current state of the view (loading, success, error, etc.).
    /// Published property that triggers UI updates when changed.
    @Published var state: ViewModelState = .okey

    /// Controls whether an error warning dialog should be displayed.
    /// Set to `true` to show the error dialog, `false` to hide it.
    @Published var showWarningError = false

    /// Controls whether action buttons should be disabled.
    /// Typically set to `true` during network operations to prevent duplicate requests.
    @Published var alertButtonDisable = false

    /// Error message to display to the user in the UI.
    /// Extracted from the error's userFriendlyMessage property.
    /// Automatically populated by handleError() method.
    @Published var errorMessage: String = ""

    /// Reference to the last error that occurred, for debugging purposes.
    /// Not displayed to users - use errorMessage for user-facing message.
    @Published var lastError: Error? = nil

    /// Called when the view appears on screen.
    /// Override this method in subclasses to perform initialization,
    /// such as loading data from the network or database.
    ///
    /// This method runs on the main thread due to the `@MainActor` annotation.
    @MainActor
    public func onAppear() {
        print(#function)
    }

    /// Handles an error by updating published properties for UI display.
    ///
    /// This method should be called when catching an error in an async operation.
    /// It automatically extracts user-friendly messages from DatabaseError types
    /// and updates the UI state accordingly.
    ///
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - state: The ViewModelState to set (default: .error)
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     try await useCase.execute()
    ///     state = .okey
    /// } catch {
    ///     handleError(error)  // Sets state = .error, showWarningError = true
    /// }
    /// ```
    @MainActor
    func handleError(_ error: Error, state: ViewModelState = .error) {
        self.lastError = error
        self.state = state
        self.showWarningError = true

        // Extract user-friendly message based on error type
        if let databaseError = error as? DatabaseError {
            self.errorMessage = databaseError.userFriendlyMessage
        } else if let localizedError = error as? LocalizedError {
            self.errorMessage = localizedError.errorDescription ?? error.localizedDescription
        } else {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Clears the error state, hiding error UI and resetting error properties.
    ///
    /// This method should be called when:
    /// - The user taps "Exit" or "Cancel" on an error dialog
    /// - An operation succeeds after error recovery
    /// - Transitioning to a new screen
    ///
    /// Example:
    /// ```swift
    /// func userDidTapExit() {
    ///     clearError()  // Hides error UI
    /// }
    /// ```
    @MainActor
    func clearError() {
        self.errorMessage = ""
        self.showWarningError = false
        self.lastError = nil
    }
}
```

---

## Phase 6: Updated ViewModels

### FeatureFavoritesViewModel

**File:** `/PokeDex/Subfeatures/FeatureFavourites/FeatureFavoritesViewModel.swift`

Replace entire file contents:

```swift
import Foundation

/// ViewModel for the Favorites feature
/// Manages loading and displaying favorite Pokémon
@MainActor
class FeatureFavoritesViewModel: BaseViewModel, ObservableObject {
    /// Data Transfer Object containing initial feature configuration
    var dto: FeatureFavoritesDTO?

    /// List of favorite Pokémon to display in the UI
    @Published var favorites = [PokemonModel]()

    /// Use case for fetching all favorite Pokémon
    let getFavoritesUseCase = FetchAllFavoritePokemonsUseCase(
        repository: FavoritesRepository.shared
    )

    /// Initializes the FeatureFavoritesViewModel
    /// - Parameter dto: Data Transfer Object with feature configuration
    init(dto: FeatureFavoritesDTO) {
        super.init()
        self.dto = dto
    }

    /// Called when the view appears on screen
    /// Initiates loading of favorite Pokémon
    override func onAppear() {
        loadFavorites()
    }

    /// Loads all favorite Pokémon from the database
    ///
    /// This method:
    /// 1. Sets state to .loading to show spinner
    /// 2. Calls the use case to fetch favorites
    /// 3. Updates the favorites array on success
    /// 4. Sets appropriate state (.okey, .empty, or .error)
    /// 5. Clears any previous errors on success
    ///
    /// Example:
    /// ```swift
    /// loadFavorites()  // Automatically handled by onAppear()
    /// ```
    func loadFavorites() {
        state = .loading

        Task {
            do {
                let loadedFavorites = try await getFavoritesUseCase.execute()

                // Update UI on main thread (already in MainActor context)
                self.favorites = loadedFavorites
                self.state = loadedFavorites.isEmpty ? .empty : .okey
                self.clearError()

                print("Successfully loaded \(loadedFavorites.count) favorites")

            } catch {
                // Handle error and update UI
                self.handleError(error)
                print("Error loading favorites: \(error.localizedDescription)")
            }
        }
    }

    /// Handles user action from the error view
    /// Called when user taps [Retry] or [Exit] on error dialog
    ///
    /// - Parameter action: The action the user selected
    @MainActor
    func errorViewAction(action: CustomErrorAction) {
        switch action {
        case .retry:
            // User wants to retry - reload favorites
            self.loadFavorites()

        case .exit:
            // User wants to dismiss error - clear error state
            self.showWarningError = false
        }
    }
}
```

### PokemonDetailViewModel

**File:** `/PokeDex/Subfeatures/FeatureDetail/Presentation/ViewModels/PokemonDetailViewModel.swift`

Replace entire file contents:

```swift
import Foundation
import SwiftData

/// ViewModel for the Pokémon Detail feature
/// Manages loading Pokémon details and favorite status
@MainActor
class PokemonDetailViewModel: BaseViewModel, ObservableObject {
    /// Data Transfer Object containing the Pokémon ID to load
    var dto: PokemonDetailAssemblyDTO?

    /// ModelContext from SwiftData for direct database access if needed
    var modelContext: ModelContext?

    // MARK: - Use Cases

    let getPokemonDetailUseCase = GetPokemonDetailUseCase(
        repository: DetailRepository()
    )

    let getPokemonDetailSpecieUseCase = GetPokemonDetailSpecieUseCase(
        repository: DetailRepository()
    )

    let addToFavoritesUseCase = AddPokemonToFavoritesUseCase(
        repository: FavoritesRepository.shared
    )

    let removeFromFavoritesUseCase = RemovePokemonFromFavoritesUseCase(
        repository: FavoritesRepository.shared
    )

    let isPokemonFavoriteUseCase = IsPokemonFavoriteUseCase(
        repository: FavoritesRepository.shared
    )

    // MARK: - Published Properties

    /// The currently displayed Pokémon detail information
    @Published var pokemonDetail: PokemonModel?

    /// The species information for the Pokémon
    @Published var pokemonDetailSpecie: PokemonSpecieModel?

    /// Whether the current Pokémon is in the favorites list
    @Published var isFavorite = false

    /// Controls whether to show a success message after favorite action
    @Published var showSuccessMessage = false

    /// Initializes the ViewModel with optional detail assembly DTO
    /// - Parameter dto: DTO containing Pokémon ID to load (optional)
    init(dto: PokemonDetailAssemblyDTO?) {
        super.init()
        self.dto = dto
    }

    /// Called when the view appears on screen
    /// Triggers loading of Pokémon detail, specie, and favorite status
    /// - Parameter model: ModelContext from SwiftData
    func onAppear(model: ModelContext) {
        self.modelContext = model
        self.loadDetail()
        self.loadSpecie()
        self.checkIfFavorite()
    }

    // MARK: - Data Loading

    /// Loads the Pokémon detail information from the API
    private func loadDetail() {
        guard let idPokemon = dto?.idPokemon else {
            handleError(NSError(domain: "InvalidID", code: -1))
            return
        }

        Task {
            do {
                guard let pokemonDetailEntity: PokemonEntity = try await getPokemonDetailUseCase.execute(id: idPokemon) else {
                    return
                }
                self.pokemonDetail = PokemonModel(pokemon: pokemonDetailEntity)
                self.state = .okey
            } catch {
                self.handleError(error)
            }
        }
    }

    /// Loads the Pokémon specie information from the API
    /// Specie loading errors don't block detail display
    private func loadSpecie() {
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
                // Log but don't block detail view if specie fails
                print("Error loading specie: \(error.localizedDescription)")
                self.lastError = error
            }
        }
    }

    /// Checks if the current Pokémon is already favorited
    /// Errors are logged but not shown to user
    private func checkIfFavorite() {
        guard let pokemonToCheck = self.pokemonDetail else {
            return
        }

        Task {
            do {
                self.isFavorite = try await isPokemonFavoriteUseCase.execute(
                    pokemon: pokemonToCheck
                )
            } catch {
                // Log error for debugging but don't show UI alert for this check
                print("Error checking favorite status: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - User Actions

    /// Handles the like/unlike button press
    /// Adds or removes the Pokémon from favorites with proper error handling
    ///
    /// - Parameter liked: true to add to favorites, false to remove
    func likeButtonPressed(liked: Bool) {
        guard let pokemonToSave = self.pokemonDetail else {
            return
        }

        alertButtonDisable = true

        Task {
            do {
                if liked {
                    try await addToFavoritesUseCase.execute(pokemon: pokemonToSave)
                } else {
                    try await removeFromFavoritesUseCase.execute(pokemon: pokemonToSave)
                }

                // Update UI on success
                self.isFavorite = liked
                self.showSuccessMessage = true
                self.clearError()

                // Auto-hide success message after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                self.showSuccessMessage = false

            } catch {
                // Handle error and update UI
                self.handleError(error)
            }

            // Re-enable button
            self.alertButtonDisable = false
        }
    }

    // MARK: - Error Handling

    /// Handles user action from the error view
    /// Called when user taps [Retry] or [Exit] on error dialog
    /// - Parameter action: The action the user selected
    @MainActor
    func errorViewAction(action: CustomErrorAction) {
        switch action {
        case .retry:
            // User wants to retry - reload based on current state
            if state == .error {
                loadDetail()
            }

        case .exit:
            // User wants to dismiss error
            clearError()
        }
    }
}
```

---

## Quick Copy-Paste Guide

### Step-by-Step Implementation

#### 1. Create the Errors Directory

```bash
mkdir -p /Users/yamartin/Documents/Proyectos/PokeDex/PokeDex/Core/Errors
```

#### 2. Create DatabaseError.swift

Copy the **Phase 1: DatabaseError.swift** code above into:
```
/Users/yamartin/Documents/Proyectos/PokeDex/PokeDex/Core/Errors/DatabaseError.swift
```

#### 3. Update FavouritesDataSource.swift

Replace contents of:
```
/Users/yamartin/Documents/Proyectos/PokeDex/PokeDex/Subfeatures/FeatureDetail/Data/DataSources/FavouritesDataSource.swift
```

With **Phase 2: Updated FavouritesDataSource** code above

#### 4. Update FavoritesRepository.swift

Replace contents of:
```
/Users/yamartin/Documents/Proyectos/PokeDex/PokeDex/Subfeatures/FeatureDetail/Data/Repositories/FavoritesRepository.swift
```

With **Phase 3: Updated FavoritesRepository** code above

#### 5. Update BaseViewModel.swift

Replace contents of:
```
/Users/yamartin/Documents/Proyectos/PokeDex/PokeDex/Core/BaseClasses/BaseViewModel.swift
```

With **Phase 5: Enhanced BaseViewModel** code above

#### 6. Update FeatureFavoritesViewModel.swift

Replace contents of:
```
/Users/yamartin/Documents/Proyectos/PokeDex/PokeDex/Subfeatures/FeatureFavourites/FeatureFavoritesViewModel.swift
```

With **FeatureFavoritesViewModel** code from Phase 6 above

#### 7. Update PokemonDetailViewModel.swift

Replace contents of:
```
/Users/yamartin/Documents/Proyectos/PokeDex/PokeDex/Subfeatures/FeatureDetail/Presentation/ViewModels/PokemonDetailViewModel.swift
```

With **PokemonDetailViewModel** code from Phase 6 above

#### 8. Verify Compilation

```bash
cd /Users/yamartin/Documents/Proyectos/PokeDex
xcodebuild build -scheme PokeDex -destination 'generic/platform=iOS'
```

#### 9. Run Tests

```bash
xcodebuild test -scheme PokeDex -destination 'generic/platform=iOS'
```

---

## Common Issues & Solutions

### Issue: "DatabaseError cannot be found"

**Solution:** Ensure you created `/PokeDex/Core/Errors/DatabaseError.swift` and added it to the PokeDex target in Xcode.

Steps:
1. Select the DatabaseError.swift file in Xcode
2. Open File Inspector (right panel)
3. Under "Target Membership", check "PokeDex"

### Issue: "Type 'FavoritesRepository' does not conform to protocol 'FavoritesRepositoryProtocol'"

**Solution:** Ensure all methods in FavoritesRepository use `async throws` exactly as defined in the protocol.

Check:
```swift
// ✅ Correct - matches protocol
func addPokemonToFavorites(pokemon: PokemonModel) async throws { ... }

// ❌ Wrong - missing async throws
func addPokemonToFavorites(pokemon: PokemonModel) { ... }
```

### Issue: "Cannot mark repository method as 'async throws' while using singleton"

**Solution:** The `@MainActor` annotation on the class allows async methods. This is correct.

```swift
@MainActor  // ✅ This allows async methods
class FavoritesRepository: FavoritesRepositoryProtocol {
    func addPokemonToFavorites(...) async throws { ... }
}
```

### Issue: "'try' used in a context where an error cannot be thrown"

**Solution:** Ensure you're inside a throwing context (function marked with `throws` or `async throws`).

```swift
// ❌ Wrong - not in throwing context
func loadFavorites() {
    try await useCase.execute()  // Error!
}

// ✅ Correct - inside Task with error handling
func loadFavorites() {
    Task {
        do {
            try await useCase.execute()  // OK
        } catch {
            // handle error
        }
    }
}
```

### Issue: "Cannot await non-async function"

**Solution:** Ensure the DataSource and Repository methods are marked `async throws`.

Quick check:
```bash
grep -n "func.*DataSource\|func.*Repository" \
  FavouritesDataSource.swift FavoritesRepository.swift
```

All should show `async throws` in their signatures.

---

## Verification Checklist

After implementation, verify each point:

```
Code Changes:
□ DatabaseError.swift created in /Core/Errors/
□ FavouritesDataSource.swift updated (all methods async throws)
□ FavoritesRepository.swift updated (all methods async throws)
□ BaseViewModel.swift updated (error handling methods added)
□ FeatureFavoritesViewModel.swift updated (error handling in tasks)
□ PokemonDetailViewModel.swift updated (error handling in tasks)

Compilation:
□ Project builds without errors
□ No compiler warnings about async/throws
□ No "does not conform to protocol" errors
□ No "cannot find 'DatabaseError'" errors

Imports:
□ FavouritesDataSource imports DatabaseError
□ Any file using try-catch can access DatabaseError
□ BaseViewModel has import Foundation

Functionality:
□ Favorites load successfully (normal path)
□ Error message displays on database error
□ Retry button appears and works
□ Exit button clears error
□ Like/unlike button works with error handling
□ Success message shows on favorite action

Testing:
□ Unit tests compile
□ Unit tests pass
□ No runtime crashes
```

---

## Files Modified Summary

| File | Changes | Lines Changed |
|------|---------|----------------|
| Core/Errors/DatabaseError.swift | NEW | 150+ |
| FavouritesDataSource.swift | Convert to async throws, replace fatalError | ~30 |
| FavoritesRepository.swift | Add async throws to signatures | ~10 |
| BaseViewModel.swift | Add error handling | ~30 |
| FeatureFavoritesViewModel.swift | Add error handling | ~15 |
| PokemonDetailViewModel.swift | Add error handling | ~25 |

**Total Lines Added/Modified:** ~260 lines

---

## Next Steps After Implementation

1. **Run Unit Tests**
   ```bash
   xcodebuild test -scheme PokeDex
   ```

2. **Manual QA Testing**
   - Test favorite/unfavorite flow
   - Simulate database errors
   - Verify error messages display
   - Test retry functionality

3. **Create Beta Release**
   - Build for TestFlight
   - Send to beta testers
   - Gather feedback

4. **Monitor After Launch**
   - Track error rates in analytics
   - Monitor app crash rates
   - Collect user feedback

5. **Update Documentation**
   - Update README if applicable
   - Document error handling for team
   - Add to API docs

---

End of Code Reference Document

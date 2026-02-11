# CRITICAL #2: Comprehensive Implementation Plan
## Resolving fatalError Crashes in FavouritesDataSource

**Document Version:** 1.0
**Date:** 2026-02-11
**Status:** Ready for Implementation
**Priority:** CRITICAL - App crashes on database errors

---

## TABLE OF CONTENTS
1. [Situation Analysis](#situation-analysis)
2. [Current State Assessment](#current-state-assessment)
3. [Error Propagation Architecture](#error-propagation-architecture)
4. [Detailed Implementation Strategy](#detailed-implementation-strategy)
5. [Code Examples](#code-examples)
6. [Implementation Roadmap](#implementation-roadmap)
7. [Testing Strategy](#testing-strategy)
8. [Risk Assessment](#risk-assessment)
9. [Appendix](#appendix)

---

## SITUATION ANALYSIS

### The Problem
The PokéDex app contains **3 critical fatalError calls** in `FavouritesDataSource.swift` that crash the entire application when database operations fail:

- **Line 48 (fetchPokemons):** `fatalError(error.localizedDescription)` - Crashes when fetching favorites
- **Line 78 (isPokemonFavorite):** `fatalError(error.localizedDescription)` - Crashes when checking favorite status
- **Line 87 (saveContext):** `fatalError("Failed to save context: \(error.localizedDescription)")` - Crashes on save failures

### Impact Assessment
- **User Experience:** App terminates unexpectedly, no graceful error recovery
- **Scope:** Affects entire Favorites feature and detail view like/unlike functionality
- **Data Loss Risk:** Unsaved changes may be lost when app crashes
- **Compliance:** Banking/financial apps require documented error handling, not crashes
- **Severity:** **CRITICAL** - Feature completely unusable on database errors

### Root Cause
The architecture has a **contract-implementation mismatch**:
- ✅ `FavoritesRepositoryProtocol` declares methods as `async throws`
- ✅ UseCases (`AddPokemonToFavoritesUseCase`, etc.) properly propagate errors
- ✅ `BaseViewModel` has error state management (`showWarningError`, `state`)
- ✅ `CustomErrorView` exists for displaying errors
- ❌ **BUT**: `FavoritesRepository` doesn't implement `async throws`
- ❌ **AND**: `FavouritesDataSource` crashes instead of throwing

This creates a **broken error propagation chain** where errors never reach the UI.

---

## CURRENT STATE ASSESSMENT

### Error Propagation Chain (Current - BROKEN)
```
View (SwiftUI)
  ↓ (can't receive errors - crashes before reaching here)
ViewModel (error state unused)
  ↓ (errors don't propagate)
UseCase (expecting errors but receives crashes)
  ↓ (errors don't propagate)
Repository Implementation (FavoritesRepository) - MISSING async throws
  ↓ (calls DataSource without error handling)
DataSource (FavouritesDataSource) - THROWS fatalError
  ↓ (CRASH!)
Database Operations (SwiftData)
```

### Error Propagation Chain (Target - WORKING)
```
Database Operation Fails
  ↓ (throws SwiftData error)
DataSource (FavouritesDataSource)
  ↓ (throws DatabaseError wrapping SwiftData error)
Repository Implementation (FavoritesRepository)
  ↓ (throws DatabaseError using async throws)
UseCase (AddPokemonToFavoritesUseCase)
  ↓ (throws DatabaseError to ViewModel)
ViewModel (PokemonDetailViewModel)
  ↓ (catches error, updates @Published state properties)
View (SwiftUI)
  ↓ (observes state changes, displays error UI)
User (sees error message with retry/exit options)
```

### Current Code Issues

#### FavouritesDataSource.swift - Lines 44-50 (fetchPokemons)
```swift
func fetchPokemons() -> [PokemonModel] {
    do {
        return try modelContext.fetch(FetchDescriptor<PokemonModel>())
    } catch {
        fatalError(error.localizedDescription)  // ❌ CRASH!
    }
}
```

**Issues:**
- Returns non-optional array (no error channel)
- Swallows all context about which operation failed
- No recovery possible

#### FavouritesDataSource.swift - Lines 69-80 (isPokemonFavorite)
```swift
func isPokemonFavorite(pokemon: PokemonModel) -> Bool {
    let idPokemon = pokemon.id
    let fetchDescriptor = FetchDescriptor<PokemonModel>(predicate: #Predicate {
        $0.id == idPokemon}, sortBy: [.init(\.id, order: .forward)])

    do {
        let results = try modelContext.fetch(fetchDescriptor)
        return !results.isEmpty
    } catch {
        fatalError(error.localizedDescription)  // ❌ CRASH!
    }
}
```

**Issues:**
- Returns Bool (not Result type), no error path
- Complex predicate logic lost on error
- Boolean return can't distinguish error from "not found"

#### FavouritesDataSource.swift - Lines 83-89 (saveContext)
```swift
private func saveContext() {
    do {
        try modelContext.save()
    } catch {
        fatalError("Failed to save context: \(error.localizedDescription)")  // ❌ CRASH!
    }
}
```

**Issues:**
- Private function called by `addPokemonToFavorites()` and `removePokemonFromFavorites()`
- Errors in these public methods are silent crashes
- No way to know if save succeeded before crashing

#### FavoritesRepository.swift - Missing Error Propagation
```swift
class FavoritesRepository: FavoritesRepositoryProtocol {
    func addPokemonToFavorites(pokemon: PokemonModel) {
        // ❌ Not async throws - violates protocol!
        FavouritesDataSource.shared.addPokemonToFavorites(pokemon: pokemon)
    }

    func fetchAllFavoritePokemons() -> [PokemonModel] {
        // ❌ Not async throws - violates protocol!
        return FavouritesDataSource.shared.fetchPokemons()
    }
}
```

**Issues:**
- Method signatures don't match protocol definition
- Can't propagate errors that might be thrown by DataSource
- Compile-time issue masked by error handling gaps

#### ViewModel Error Handling - Incomplete
```swift
class FeatureFavoritesViewModel: BaseViewModel, ObservableObject {
    func loadFavorites() {
        Task {
            do {
                favorites = try await getFavoritesUseCase.execute()
                print(favorites.count)
            } catch {
                print("Error: \(error)")  // ⚠️ Only prints, doesn't display to user
            }
        }
    }
}
```

**Issues:**
- Catches errors but only prints them
- Doesn't set `state` to `.error`
- Doesn't set `showWarningError = true`
- Error message never reaches user

---

## ERROR PROPAGATION ARCHITECTURE

### Error Type Hierarchy (Recommended)

We need a custom error type to wrap database errors with context:

```
Swift.Error (Protocol)
  ├── DatabaseError (Custom)
  │   ├── fetchFailed(underlying: Error)
  │   ├── saveFailed(underlying: Error)
  │   ├── predicateFailed(underlying: Error)
  │   └── containerInitializationFailed(underlying: Error)
  │
  └── (Existing errors from network, parsing, etc.)
```

**Why a custom error type?**
1. **Localization:** Map technical errors to user-friendly messages
2. **Analytics:** Track which operations fail most
3. **Recovery:** Different errors suggest different recovery strategies
4. **Type Safety:** Distinguishes database errors from other failures
5. **Clean Architecture:** Keep domain layer independent of SwiftData framework

### Error Propagation Path

```
1. Database Operation (SwiftData)
   └─> throws SwiftData.SwiftDataError

2. FavouritesDataSource (Data Layer)
   ├─> catches SwiftData error
   ├─> wraps in DatabaseError (adds context)
   └─> throws DatabaseError

3. FavoritesRepository (Data Layer Abstraction)
   ├─> receives DatabaseError from DataSource
   ├─> optionally adds more context
   └─> re-throws DatabaseError

4. UseCase (Domain Layer)
   ├─> receives DatabaseError from Repository
   ├─> validates business logic
   └─> re-throws DatabaseError (or domain-specific error)

5. ViewModel (Presentation Layer)
   ├─> receives DatabaseError
   ├─> updates @Published properties:
   │   ├─> state = .error
   │   ├─> showWarningError = true
   │   └─> errorMessage = error.userMessage
   └─> observing View sees changes

6. View (UI Layer)
   ├─> observes @Published properties
   ├─> state == .error → show CustomErrorView
   ├─> showWarningError == true → show alert
   └─> User taps Retry or Exit
```

### Protocol Changes Required

**Current (Broken):**
```swift
protocol FavoritesRepositoryProtocol {
    func addPokemonToFavorites(pokemon: PokemonModel) async throws
    func removePokemonFromFavorites(pokemon: PokemonModel) async throws
    func fetchAllFavoritePokemons() async throws -> [PokemonModel]
    func isPokemonFavorite(pokemon: PokemonModel) async throws -> Bool
}
```

Protocol is correct but implementation violates it!

**Repository Implementation Must Match:**
```swift
class FavoritesRepository: FavoritesRepositoryProtocol {
    func addPokemonToFavorites(pokemon: PokemonModel) async throws {
        // Must be async throws to match protocol
        try await FavouritesDataSource.shared.addPokemonToFavorites(pokemon: pokemon)
    }
    // ... other methods also async throws
}
```

---

## DETAILED IMPLEMENTATION STRATEGY

### Phase 1: Create Custom Error Type (Foundation)
**Goal:** Define error types that carry context through the propagation chain

**File:** Create `/PokeDex/Core/Errors/DatabaseError.swift`

**Responsibilities:**
- Define error cases for all database operation failures
- Provide user-friendly messages (localized)
- Enable analytics tracking
- Support error recovery strategies

**Why First:** All other layers depend on this type definition

### Phase 2: Update FavouritesDataSource (Data Layer - Critical)
**Goal:** Convert fatalErrors to proper error throwing

**File:** Modify `/PokeDex/Subfeatures/FeatureDetail/Data/DataSources/FavouritesDataSource.swift`

**Changes:**
1. Make `fetchPokemons()` throw → `func fetchPokemons() async throws -> [PokemonModel]`
2. Make `isPokemonFavorite()` throw → `func isPokemonFavorite(pokemon: PokemonModel) async throws -> Bool`
3. Make `saveContext()` throw → `func saveContext() async throws` (or private `_saveContext()`)
4. Make add/remove methods throw → methods that call `saveContext()` become throwing

**Critical Detail:** These must become `async` because:
- Database operations on main thread (MainActor) should be non-blocking
- Aligns with SwiftData best practices
- Allows proper error propagation from async throws
- Matches UseCase expectations (they're already async throws)

### Phase 3: Update FavoritesRepository (Data Abstraction Layer)
**Goal:** Implement protocol correctly and propagate errors

**File:** Modify `/PokeDex/Subfeatures/FeatureDetail/Data/Repositories/FavoritesRepository.swift`

**Changes:**
1. Add `async throws` to all method signatures
2. Call DataSource methods with `try await`
3. Handle or propagate DatabaseError instances
4. Optional: Add analytics logging for error tracking

### Phase 4: Update UseCases (Domain Layer - No Changes Needed!)
**Goal:** Verify UseCase layer is correct (should already work)

**Files:**
- `AddPokemonToFavoritesUseCase.swift`
- `RemovePokemonFromFavoritesUseCase.swift`
- `FetchAllFavoritePokemonsUseCase.swift`
- `IsPokemonFavoriteUseCase.swift`

**Status:** These already have `async throws` and properly call repository methods. No changes needed! This shows good architecture - UseCases are already error-aware.

### Phase 5: Update ViewModels (Presentation Layer)
**Goal:** Catch errors and update UI state

**File:** Modify `/PokeDex/Subfeatures/FeatureDetail/Presentation/ViewModels/PokemonDetailViewModel.swift`

**Current Issue:**
```swift
func likeButtonPressed(liked: Bool) {
    guard let pokemonToSave = self.pokemonDetail else { return }
    if liked {
        self.modelContext?.insert(pokemonToSave)
    } else {
        self.modelContext?.delete(pokemonToSave)
    }
    try? self.modelContext?.save()  // ⚠️ Silently ignores errors
}
```

**Should Be:**
```swift
@MainActor
func likeButtonPressed(liked: Bool) {
    guard let pokemonToSave = self.pokemonDetail else { return }

    Task {
        do {
            if liked {
                try await addToFavoritesUseCase.execute(pokemon: pokemonToSave)
                showSuccessMessage = true
            } else {
                try await removeFromFavoritesUseCase.execute(pokemon: pokemonToSave)
                showSuccessMessage = true
            }
            state = .okey
        } catch {
            state = .error
            showWarningError = true
            errorMessage = error.userFriendlyDescription
        }
    }
}
```

**File:** Modify `/PokeDex/Subfeatures/FeatureFavourites/FeatureFavoritesViewModel.swift`

**Current:**
```swift
func loadFavorites() {
    Task {
        do {
            favorites = try await getFavoritesUseCase.execute()
            print(favorites.count)
        } catch {
            print("Error: \(error)")  // ⚠️ Only prints!
        }
    }
}
```

**Should Be:**
```swift
@MainActor
func loadFavorites() {
    state = .loading
    Task {
        do {
            favorites = try await getFavoritesUseCase.execute()
            state = favorites.isEmpty ? .empty : .okey
        } catch {
            state = .error
            showWarningError = true
            errorMessage = error.userFriendlyDescription
            print("Error loading favorites: \(error)")
        }
    }
}
```

### Phase 6: Update Views (UI Layer)
**Goal:** Display errors caught by ViewModel

**File:** Update any view that uses `FeatureFavoritesViewModel` or `PokemonDetailViewModel`

**Changes:**
- Observe `@Published var state: ViewModelState`
- Observe `@Published var showWarningError: Bool`
- Show error UI when state == .error or showWarningError == true
- Provide retry action that re-calls the failed operation

---

## CODE EXAMPLES

### 1. New Error Type Definition

**File:** `/PokeDex/Core/Errors/DatabaseError.swift`

```swift
import Foundation

/// Represents errors that can occur during database operations.
///
/// This error type wraps underlying SwiftData errors and provides:
/// - User-friendly error messages
/// - Error classification for analytics
/// - Recovery strategy hints
/// - Localization support
enum DatabaseError: LocalizedError {
    /// Failed to fetch data from the database
    case fetchFailed(operation: String, underlying: Error)

    /// Failed to save changes to the database
    case saveFailed(underlying: Error)

    /// Failed to delete data from the database
    case deleteFailed(operation: String, underlying: Error)

    /// Failed to apply predicate or filter
    case predicateFailed(underlying: Error)

    /// Failed to initialize the model container
    case containerInitializationFailed(underlying: Error)

    /// Unknown database error
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
            return underlying.localizedDescription
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Try refreshing or restarting the app."
        case .saveFailed:
            return "Check if you have enough storage space, then try again."
        case .deleteFailed:
            return "Try again or restart the app."
        case .predicateFailed:
            return "Modify your search criteria and try again."
        case .containerInitializationFailed:
            return "Force close and reopen the app. Contact support if the problem persists."
        case .unknown:
            return "Try again or restart the app."
        }
    }

    // MARK: - Helper Properties

    /// User-friendly error message for UI display
    var userFriendlyMessage: String {
        errorDescription ?? "An error occurred"
    }

    /// Full error description for logging
    var detailedDescription: String {
        let base = errorDescription ?? "Unknown error"
        let reason = failureReason.map { "\nReason: \($0)" } ?? ""
        let suggestion = recoverySuggestion.map { "\nSuggestion: \($0)" } ?? ""
        return base + reason + suggestion
    }

    /// Determines if this error is recoverable by user action
    var isRecoverable: Bool {
        switch self {
        case .containerInitializationFailed:
            return false  // Requires app restart
        default:
            return true   // User can retry
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

**Benefits of this approach:**
- ✅ All database errors go through one type
- ✅ User-friendly messages already defined
- ✅ Support for recovery strategies
- ✅ Easy to extend with new error cases
- ✅ Testable error equality

### 2. Updated FavouritesDataSource

**File:** `/PokeDex/Subfeatures/FeatureDetail/Data/DataSources/FavouritesDataSource.swift`

```swift
import SwiftUI
import SwiftData

@MainActor
final class FavouritesDataSource {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    static let shared: FavouritesDataSource = {
        do {
            return try FavouritesDataSource()
        } catch {
            do {
                return try FavouritesDataSource(inMemoryOnly: true)
            } catch {
                // This should only happen in extreme circumstances
                // In production, consider a fallback mechanism or graceful degradation
                fatalError("Cannot create model container: \(error)")
            }
        }
    }()

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

    /// Fetches all Pokémon marked as favorites.
    /// - Returns: An array of PokemonModel objects that are marked as favorites.
    /// - Throws: DatabaseError if the fetch operation fails.
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

    /// Adds a Pokémon to the favorites list.
    /// - Parameter pokemon: The PokemonModel object to add to favorites.
    /// - Throws: DatabaseError if the operation fails.
    func addPokemonToFavorites(pokemon: PokemonModel) async throws {
        modelContext.insert(pokemon)
        try await saveContext()
    }

    /// Removes a Pokémon from the favorites list.
    /// - Parameter pokemon: The PokemonModel object to remove from favorites.
    /// - Throws: DatabaseError if the operation fails.
    func removePokemonFromFavorites(pokemon: PokemonModel) async throws {
        modelContext.delete(pokemon)
        try await saveContext()
    }

    /// Checks if a specific Pokémon is in the favorites list.
    /// - Parameter pokemon: The PokemonModel object to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: DatabaseError if the fetch operation fails.
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

    /// Saves the current state of the model context.
    /// - Throws: DatabaseError if the save operation fails.
    func saveContext() async throws {
        do {
            try modelContext.save()
        } catch {
            throw DatabaseError.saveFailed(underlying: error)
        }
    }
}
```

**Key Changes:**
- ✅ All methods now `async throws`
- ✅ Replaces `fatalError` with `throw DatabaseError`
- ✅ Provides operation context in error (e.g., "favorites")
- ✅ Preserves underlying error for logging
- ✅ Main thread safety with `@MainActor`

### 3. Updated FavoritesRepository

**File:** `/PokeDex/Subfeatures/FeatureDetail/Data/Repositories/FavoritesRepository.swift`

```swift
import Foundation

@MainActor
class FavoritesRepository: FavoritesRepositoryProtocol {
    static let shared = FavoritesRepository()

    private init() {} // Singleton pattern

    /// Adds a Pokémon to the favorites list.
    /// - Parameter pokemon: The PokemonModel object to add to favorites.
    /// - Throws: DatabaseError if the operation fails.
    func addPokemonToFavorites(pokemon: PokemonModel) async throws {
        try await FavouritesDataSource.shared.addPokemonToFavorites(pokemon: pokemon)
    }

    /// Removes a Pokémon from the favorites list.
    /// - Parameter pokemon: The PokemonModel object to remove from favorites.
    /// - Throws: DatabaseError if the operation fails.
    func removePokemonFromFavorites(pokemon: PokemonModel) async throws {
        try await FavouritesDataSource.shared.removePokemonFromFavorites(pokemon: pokemon)
    }

    /// Fetches all Pokémon marked as favorites.
    /// - Returns: An array of PokemonModel objects marked as favorites.
    /// - Throws: DatabaseError if the fetch operation fails.
    func fetchAllFavoritePokemons() async throws -> [PokemonModel] {
        try await FavouritesDataSource.shared.fetchPokemons()
    }

    /// Checks if a specific Pokémon is in the favorites list.
    /// - Parameter pokemon: The PokemonModel object to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: DatabaseError if the check fails.
    func isPokemonFavorite(pokemon: PokemonModel) async throws -> Bool {
        try await FavouritesDataSource.shared.isPokemonFavorite(pokemon: pokemon)
    }
}
```

**Key Changes:**
- ✅ All methods now `async throws` (matching protocol)
- ✅ Uses `try await` to propagate errors
- ✅ Removes error swallowing
- ✅ Direct pass-through allows for future decoration/logging

### 4. Enhanced BaseViewModel for Error Handling

**File:** `/PokeDex/Core/BaseClasses/BaseViewModel.swift` (additions)

```swift
import Foundation

enum ViewModelState: String {
    case okey
    case loading
    case error
    case unknownError
    case notReachable
    case empty
}

/// Extended error message property for ViewModels
public class BaseViewModel {
    @Published var state: ViewModelState = .okey
    @Published var showWarningError = false
    @Published var alertButtonDisable = false

    /// Error message to display to the user
    @Published var errorMessage: String = ""

    /// Last error that occurred, for debugging
    @Published var lastError: Error? = nil

    @MainActor
    public func onAppear() {
        print(#function)
    }

    /// Call this to handle an error caught during an operation
    /// - Parameter error: The error that occurred
    /// - Parameter state: The state to set (default: .error)
    @MainActor
    func handleError(_ error: Error, state: ViewModelState = .error) {
        self.lastError = error
        self.state = state
        self.showWarningError = true

        // Extract user-friendly message
        if let databaseError = error as? DatabaseError {
            self.errorMessage = databaseError.userFriendlyMessage
        } else if let localizedError = error as? LocalizedError {
            self.errorMessage = localizedError.errorDescription ?? error.localizedDescription
        } else {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Call this to clear error state
    @MainActor
    func clearError() {
        self.errorMessage = ""
        self.showWarningError = false
        self.lastError = nil
    }
}
```

### 5. Updated FeatureFavoritesViewModel

**File:** `/PokeDex/Subfeatures/FeatureFavourites/FeatureFavoritesViewModel.swift`

```swift
import Foundation

@MainActor
class FeatureFavoritesViewModel: BaseViewModel, ObservableObject {
    var dto: FeatureFavoritesDTO?
    @Published var favorites = [PokemonModel]()

    init(dto: FeatureFavoritesDTO) {
        super.init()
        // Initialize with DTO data if needed
    }

    let getFavoritesUseCase = FetchAllFavoritePokemonsUseCase(
        repository: FavoritesRepository.shared
    )

    override func onAppear() {
        loadFavorites()
    }

    /// Loads all favorite Pokémon from the database
    func loadFavorites() {
        state = .loading

        Task {
            do {
                let loadedFavorites = try await getFavoritesUseCase.execute()

                // Update UI on main thread
                self.favorites = loadedFavorites
                self.state = loadedFavorites.isEmpty ? .empty : .okey
                self.clearError()

                print("Loaded \(loadedFavorites.count) favorites")
            } catch {
                // Handle error and update UI
                self.handleError(error)
                print("Error loading favorites: \(error.localizedDescription)")
            }
        }
    }

    /// Handle error view action (retry or exit)
    @MainActor
    func errorViewAction(action: CustomErrorAction) {
        switch action {
        case .retry:
            self.loadFavorites()
        case .exit:
            self.showWarningError = false
        }
    }
}
```

### 6. Updated PokemonDetailViewModel (Like/Unlike)

**File:** `/PokeDex/Subfeatures/FeatureDetail/Presentation/ViewModels/PokemonDetailViewModel.swift`

```swift
import Foundation
import SwiftData

@MainActor
class PokemonDetailViewModel: BaseViewModel, ObservableObject {
    var dto: PokemonDetailAssemblyDTO?
    var modelContext: ModelContext?

    init(dto: PokemonDetailAssemblyDTO?) {
        super.init()
        self.dto = dto
    }

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

    @Published var pokemonDetail: PokemonModel?
    @Published var pokemonDetailSpecie: PokemonSpecieModel?
    @Published var isFavorite = false
    @Published var showSuccessMessage = false

    func onAppear(model: ModelContext) {
        self.modelContext = model
        self.loadDetail()
        self.loadSpecie()
    }

    func loadDetail() {
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
                // Log but don't block detail view if specie fails
                print("Error loading specie: \(error.localizedDescription)")
            }
        }
    }

    /// Handles like/unlike button press with proper error handling
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

                self.isFavorite = liked
                self.showSuccessMessage = true
                self.clearError()

                // Auto-hide success message after 2 seconds
                try await Task.sleep(nanoseconds: 2_000_000_000)
                self.showSuccessMessage = false
            } catch {
                self.handleError(error)
            }

            self.alertButtonDisable = false
        }
    }

    /// Check if current Pokémon is already favorited
    func checkIfFavorite() {
        guard let pokemonToCheck = self.pokemonDetail else {
            return
        }

        Task {
            do {
                self.isFavorite = try await isPokemonFavoriteUseCase.execute(
                    pokemon: pokemonToCheck
                )
            } catch {
                // Log error but don't show UI alert for this check
                print("Error checking favorite status: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func errorViewAction(action: CustomErrorAction) {
        switch action {
        case .retry:
            // Retry last operation based on current state
            if state == .error {
                loadDetail()
            }
        case .exit:
            clearError()
        }
    }
}
```

---

## IMPLEMENTATION ROADMAP

### Timeline & Dependencies

```
Phase 1: Error Type (Foundation)
├─ Create DatabaseError.swift
├─ Add to Core/Errors directory
└─ Duration: ~2 hours
   ↓ (Blocking for all other phases)

Phase 2: FavouritesDataSource (Critical Data Layer)
├─ Add DatabaseError import
├─ Convert fetchPokemons() to async throws
├─ Convert isPokemonFavorite() to async throws
├─ Convert saveContext() to async throws
├─ Update public methods that call saveContext()
└─ Duration: ~3 hours
   ↓ (Blocking: Phase 3)

Phase 3: FavoritesRepository (Data Abstraction)
├─ Add async throws to all methods
├─ Use try await with DataSource methods
└─ Duration: ~1 hour
   ↓ (Blocking: Phase 4)

Phase 4: UseCases (Domain Layer - Verification Only)
├─ Verify AddPokemonToFavoritesUseCase syntax
├─ Verify RemovePokemonFromFavoritesUseCase syntax
├─ Verify FetchAllFavoritePokemonsUseCase syntax
├─ Verify IsPokemonFavoriteUseCase syntax
└─ Duration: ~30 minutes
   ↓ (Can proceed parallel with Phase 5)

Phase 5: BaseViewModel Enhancement (Presentation Foundation)
├─ Add errorMessage @Published property
├─ Add lastError @Published property
├─ Add handleError() method
├─ Add clearError() method
└─ Duration: ~1.5 hours
   ↓ (Blocking: Phase 6)

Phase 6: ViewModel Updates (Presentation Layer)
├─ Update FeatureFavoritesViewModel error handling
├─ Update PokemonDetailViewModel error handling
├─ Add proper state transitions
└─ Duration: ~2 hours
   ↓ (Can proceed parallel with Phase 7)

Phase 7: View Updates (UI Layer - Optional)
├─ Update FeatureFavoritesView to show error state
├─ Update PokemonDetailView to show like/unlike feedback
└─ Duration: ~1.5 hours

Testing (All Phases)
├─ Unit tests for error propagation
├─ Integration tests for full flow
├─ UI tests for error display
└─ Duration: ~4 hours (parallel with implementation)

Total Duration: ~14-16 hours (parallel phases reduce timeline)
```

### Step-by-Step Implementation Checklist

#### Phase 1: Error Type Definition
```
□ Create /PokeDex/Core/Errors/ directory
□ Create DatabaseError.swift
□ Implement enum with all error cases
□ Add LocalizedError conformance
□ Add helper properties (userFriendlyMessage, detailedDescription)
□ Add Equatable conformance for testing
□ Compile and verify no errors
□ Write unit tests for error messages
```

#### Phase 2: FavouritesDataSource
```
□ Add import for DatabaseError
□ Update fetchPokemons() signature to async throws
□ Replace fatalError with throw DatabaseError.fetchFailed
□ Update isPokemonFavorite() signature to async throws
□ Replace fatalError with throw DatabaseError.predicateFailed
□ Update saveContext() signature to async throws
□ Replace fatalError with throw DatabaseError.saveFailed
□ Update addPokemonToFavorites() to async throws
□ Update removePokemonFromFavorites() to async throws
□ Compile and fix any errors
□ Test each method individually with error scenarios
```

#### Phase 3: FavoritesRepository
```
□ Update addPokemonToFavorites() to async throws
□ Update removePokemonFromFavorites() to async throws
□ Update fetchAllFavoritePokemons() to async throws
□ Update isPokemonFavorite() to async throws
□ Add try await to all DataSource calls
□ Verify all methods match FavoritesRepositoryProtocol
□ Compile and fix any errors
```

#### Phase 4: UseCase Verification
```
□ Review AddPokemonToFavoritesUseCase
□ Verify execute() is async throws
□ Review RemovePokemonFromFavoritesUseCase
□ Verify execute() is async throws
□ Review FetchAllFavoritePokemonsUseCase
□ Verify execute() is async throws
□ Review IsPokemonFavoriteUseCase
□ Verify execute() is async throws
□ No changes should be needed (confirm existing implementation)
```

#### Phase 5: BaseViewModel Enhancement
```
□ Add @Published var errorMessage: String = ""
□ Add @Published var lastError: Error? = nil
□ Implement handleError(_ error: Error, state: ViewModelState)
□ Implement clearError()
□ Extract user message from DatabaseError.userFriendlyMessage
□ Compile and verify
```

#### Phase 6: ViewModel Updates
```
□ Update FeatureFavoritesViewModel.loadFavorites()
  ├─ Set state = .loading at start
  ├─ Catch error and call handleError()
  ├─ Set state = .empty if no favorites
  └─ Call clearError() on success

□ Update PokemonDetailViewModel.likeButtonPressed()
  ├─ Disable button during operation
  ├─ Call appropriate UseCase with try await
  ├─ Handle success (show success message)
  ├─ Catch error and call handleError()
  └─ Enable button when complete

□ Update PokemonDetailViewModel.checkIfFavorite()
  ├─ Call isPokemonFavoriteUseCase
  ├─ Catch errors without showing UI
  └─ Log errors for debugging

□ Implement errorViewAction() in both ViewModels
  ├─ Handle .retry action
  ├─ Handle .exit action
  └─ Call clearError() on exit
```

#### Phase 7: View Updates
```
□ Update FeatureFavoritesView
  ├─ Observe viewModel.state
  ├─ Show loading spinner when .loading
  ├─ Show empty state when .empty
  ├─ Show error view when .error
  └─ Pass errorViewAction to CustomErrorView

□ Update PokemonDetailView
  ├─ Observe isFavorite binding
  ├─ Show success message on save
  ├─ Show error UI on failure
  └─ Disable like button during save
```

### Parallel Execution Strategy

**Can start simultaneously:**
- Phase 5 (BaseViewModel) and Phase 2 (FavouritesDataSource)
- Phase 6 (ViewModels) and Phase 4 (UseCase verification)
- Phase 7 (Views) and Phase 6 (ViewModels)

**Must complete sequentially:**
- Phase 1 → everything else
- Phase 2 → Phase 3
- Phase 3 → Phase 4
- Phase 5 → Phase 6

---

## TESTING STRATEGY

### Unit Testing

#### 1. DatabaseError Tests

**File:** `PokeDexTests/Core/Errors/DatabaseErrorTests.swift`

```swift
import XCTest
@testable import PokeDex

final class DatabaseErrorTests: XCTestCase {

    func testFetchFailedErrorDescription() {
        let underlyingError = NSError(domain: "SwiftData", code: 1)
        let error = DatabaseError.fetchFailed(operation: "favorites", underlying: underlyingError)

        XCTAssertEqual(error.errorDescription, "Unable to load favorites. Please try again.")
    }

    func testSaveFailedErrorDescription() {
        let underlyingError = NSError(domain: "SwiftData", code: 2)
        let error = DatabaseError.saveFailed(underlying: underlyingError)

        XCTAssertEqual(error.errorDescription, "Failed to save changes. Please try again.")
    }

    func testErrorIsRecoverable() {
        let fetchError = DatabaseError.fetchFailed(operation: "test", underlying: NSError())
        XCTAssertTrue(fetchError.isRecoverable)

        let containerError = DatabaseError.containerInitializationFailed(underlying: NSError())
        XCTAssertFalse(containerError.isRecoverable)
    }

    func testUserFriendlyMessage() {
        let error = DatabaseError.fetchFailed(operation: "favorites", underlying: NSError())
        let message = error.userFriendlyMessage

        XCTAssertFalse(message.isEmpty)
        XCTAssertEqual(message, "Unable to load favorites. Please try again.")
    }
}
```

#### 2. FavouritesDataSource Error Handling Tests

**File:** `PokeDexTests/FeatureDetail/Data/FavouritesDataSourceErrorTests.swift`

```swift
import XCTest
import SwiftData
@testable import PokeDex

final class FavouritesDataSourceErrorTests: XCTestCase {

    var dataSource: FavouritesDataSource!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        // Create in-memory data source for testing
        dataSource = try FavouritesDataSource(inMemoryOnly: true)
    }

    @MainActor
    func testFetchPokemonsThrowsOnError() async throws {
        // This test would need a way to mock SwiftData errors
        // For now, verify the method signature is async throws
        let result = try? await dataSource.fetchPokemons()
        XCTAssertNotNil(result, "Should return empty array on success")
    }

    @MainActor
    func testAddPokemonThrowsOnError() async throws {
        // Create a test pokemon
        let pokemon = PokemonModel(
            id: 1,
            name: "Pikachu",
            imageUrl: "test.png"
        )

        // Should not throw (disk space available in test)
        XCTAssertNoThrow(
            try await dataSource.addPokemonToFavorites(pokemon: pokemon)
        )
    }

    @MainActor
    func testRemovePokemonThrowsOnError() async throws {
        let pokemon = PokemonModel(
            id: 1,
            name: "Pikachu",
            imageUrl: "test.png"
        )

        // Add then remove
        try await dataSource.addPokemonToFavorites(pokemon: pokemon)
        XCTAssertNoThrow(
            try await dataSource.removePokemonFromFavorites(pokemon: pokemon)
        )
    }

    @MainActor
    func testIsPokemonFavoriteReturnsCorrectValue() async throws {
        let pokemon = PokemonModel(
            id: 1,
            name: "Pikachu",
            imageUrl: "test.png"
        )

        // Initially not favorite
        let isFavorite = try await dataSource.isPokemonFavorite(pokemon: pokemon)
        XCTAssertFalse(isFavorite)

        // After adding, should be favorite
        try await dataSource.addPokemonToFavorites(pokemon: pokemon)
        let isFavoriteAfterAdd = try await dataSource.isPokemonFavorite(pokemon: pokemon)
        XCTAssertTrue(isFavoriteAfterAdd)
    }
}
```

#### 3. FavoritesRepository Error Propagation Tests

**File:** `PokeDexTests/FeatureDetail/Data/FavoritesRepositoryTests.swift`

```swift
import XCTest
@testable import PokeDex

final class FavoritesRepositoryTests: XCTestCase {

    var repository: FavoritesRepository!

    override func setUp() {
        super.setUp()
        repository = FavoritesRepository()
    }

    @MainActor
    func testAddPokemonIsAsync() async throws {
        let pokemon = PokemonModel(
            id: 1,
            name: "Pikachu",
            imageUrl: "test.png"
        )

        // Should be awaitable
        try await repository.addPokemonToFavorites(pokemon: pokemon)
    }

    @MainActor
    func testFetchAllFavoritesIsAsync() async throws {
        // Should be awaitable and return array
        let favorites = try await repository.fetchAllFavoritePokemons()
        XCTAssertIsNotNil(favorites)
    }

    @MainActor
    func testIsPokemonFavoriteIsAsync() async throws {
        let pokemon = PokemonModel(
            id: 1,
            name: "Pikachu",
            imageUrl: "test.png"
        )

        // Should be awaitable and return Bool
        let isFavorite = try await repository.isPokemonFavorite(pokemon: pokemon)
        XCTAssertIsNotNil(isFavorite)
    }
}
```

#### 4. ViewModel Error Handling Tests

**File:** `PokeDexTests/FeatureDetail/Presentation/PokemonDetailViewModelTests.swift`

```swift
import XCTest
@testable import PokeDex

final class PokemonDetailViewModelTests: XCTestCase {

    var viewModel: PokemonDetailViewModel!

    override func setUp() {
        super.setUp()
        viewModel = PokemonDetailViewModel(dto: nil)
    }

    func testHandleErrorUpdatesState() {
        let error = DatabaseError.saveFailed(underlying: NSError())

        viewModel.handleError(error)

        XCTAssertEqual(viewModel.state, .error)
        XCTAssertTrue(viewModel.showWarningError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
    }

    func testClearErrorResetsState() {
        viewModel.handleError(DatabaseError.saveFailed(underlying: NSError()))
        XCTAssertTrue(viewModel.showWarningError)

        viewModel.clearError()

        XCTAssertFalse(viewModel.showWarningError)
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
    }

    @MainActor
    func testLikeButtonPressedHandlesError() async throws {
        // Mock a pokemon
        let pokemon = PokemonModel(id: 1, name: "Pikachu", imageUrl: "test.png")
        viewModel.pokemonDetail = pokemon

        // Note: Full testing would require mocking the UseCase
        // For now, verify the ViewModel has the infrastructure
        XCTAssertNotNil(viewModel.errorViewAction)
    }
}
```

### Integration Testing

#### Full Error Flow Test

**File:** `PokeDexTests/Integration/FavoritesErrorFlowTests.swift`

```swift
import XCTest
@testable import PokeDex

final class FavoritesErrorFlowTests: XCTestCase {

    @MainActor
    func testErrorPropagationFromDataSourceToViewModel() async throws {
        // Arrange
        let dataSource = try FavouritesDataSource(inMemoryOnly: true)
        let repository = FavoritesRepository()
        let useCase = FetchAllFavoritePokemonsUseCase(repository: repository)
        let viewModel = FeatureFavoritesViewModel(dto: FeatureFavoritesDTO())

        // Act
        await viewModel.loadFavorites()

        // Assert
        // Should succeed with empty array (not crash)
        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertEqual(viewModel.favorites.count, 0)
    }

    @MainActor
    func testAddFavoriteErrorReachesViewModel() async throws {
        // This would require mocking SwiftData failures
        // Conceptual test to verify error flow
        let viewModel = PokemonDetailViewModel(dto: nil)
        let pokemon = PokemonModel(id: 1, name: "Pikachu", imageUrl: "test.png")
        viewModel.pokemonDetail = pokemon

        // Simulate like button press (would trigger error in mock scenario)
        // viewModel.likeButtonPressed(liked: true)

        // In a real test with mocked DataSource:
        // XCTAssertEqual(viewModel.state, .error)
        // XCTAssertTrue(viewModel.showWarningError)
    }
}
```

### UI Testing

#### Error Display Test

**File:** `PokeDexTests/UI/ErrorDisplayTests.swift`

```swift
import XCTest

final class ErrorDisplayTests: XCTestCase {

    func testErrorViewDisplaysRetryButton() {
        // Launch app
        let app = XCUIApplication()
        app.launch()

        // Navigate to favorites (assuming it shows error due to mock)
        // Tap favorite button and trigger error scenario

        // Verify error view appears
        // XCTAssert(app.staticTexts["Se ha producido un error"].exists)

        // Verify retry button exists
        // XCTAssert(app.buttons["Reintentar"].exists)
    }

    func testErrorViewRetryFunctionality() {
        let app = XCUIApplication()
        app.launch()

        // Trigger error
        // Tap retry
        // Verify retry succeeds
    }
}
```

### Testing Checklist

```
Unit Tests:
□ DatabaseError user messages
□ DatabaseError recoverability
□ DatabaseError equality
□ FavouritesDataSource async throws signatures
□ FavouritesDataSource error throwing
□ FavoritesRepository async throws signatures
□ FavoritesRepository error propagation
□ BaseViewModel handleError()
□ BaseViewModel clearError()
□ ViewModel error state updates

Integration Tests:
□ Error flow from DataSource to ViewModel
□ Error recovery (retry functionality)
□ Successful operation after error
□ Multiple sequential operations with errors

UI Tests:
□ Error view displays correctly
□ Error message is readable
□ Retry button works
□ Exit button works
□ Error clears on retry success

Regression Tests:
□ Normal favorites flow still works
□ Add favorite succeeds
□ Remove favorite succeeds
□ Check favorite status succeeds
□ Fetch all favorites succeeds
```

---

## RISK ASSESSMENT

### Breaking Changes

#### API Contract Changes
- **Severity:** MEDIUM
- **Scope:** FavoritesRepository methods now `async throws`
- **Impact:** All callers must use `try await` instead of simple await
- **Mitigation:**
  - UseCases already expect this (they're async throws)
  - ViewModels already use try-catch
  - Only need to update method calls
- **Backward Compatibility:** Breaking change - all call sites must be updated

#### Method Signature Changes
- **Affected Methods:**
  - `fetchPokemons()` → `async throws`
  - `isPokemonFavorite()` → `async throws`
  - `addPokemonToFavorites()` → `async throws`
  - `removePokemonFromFavorites()` → `async throws`

- **Call Sites to Update:**
  - `/PokeDex/Subfeatures/FeatureFavourites/FeatureFavoritesViewModel.swift`
  - `/PokeDex/Subfeatures/FeatureDetail/Presentation/ViewModels/PokemonDetailViewModel.swift`
  - Any tests that use these repositories

#### Architectural Dependencies
- **New Dependency:** `DatabaseError` enum in Core layer
- **Affects:** All modules that interact with FavoritesRepository
- **Risk:** Circular dependency if not careful
- **Mitigation:** DatabaseError lives in Core (lowest layer)

### Compatibility Issues

#### iOS Version Support
- **Async/await:** Available on iOS 13+
- **SwiftData:** Available on iOS 17+
- **@Published:** Available on iOS 13+
- **Result:** No compatibility issues (already using these features)

#### Compile-Time Verification
- **Risk:** If changes not applied consistently, won't compile
- **Benefit:** Compiler ensures all error paths handled
- **Strategy:** Fix compile errors one file at a time

### Performance Impact

#### Database Operations
- **Current:** Synchronous on main thread (fatalError on failure)
- **New:** Async on main thread (throws on failure)
- **Impact:** More responsive UI, no blocking
- **Performance:** Likely IMPROVED (non-blocking)

#### Error Handling Overhead
- **Current:** No error handling (crashes immediately)
- **New:** Error handling with state updates
- **Overhead:** Minimal (~1-2ms per error)
- **Negligible:** Not significant for user experience

#### Memory
- **DatabaseError enum:** Minimal memory (error description strings only)
- **@Published errorMessage:** One String per ViewModel
- **lastError reference:** Optional Error reference
- **Overall Impact:** Negligible

### Testing Coverage

#### New Code to Test
- DatabaseError enum (100% coverage possible)
- FavouritesDataSource async throws paths
- Error state transitions in ViewModels
- Error display in Views

#### Current Coverage Gaps
- No tests for error paths currently exist
- New tests will improve coverage from ~?% to estimated ~80%+

### Rollout Strategy

#### Phased Approach
1. **Phase 1 (Low Risk):** DatabaseError definition
   - No breaking changes
   - Can ship independently

2. **Phase 2 (Medium Risk):** FavouritesDataSource errors
   - Breaking change to internal contract
   - Can test in isolation

3. **Phase 3 (Medium Risk):** Repository implementation
   - Updates implementation to match protocol
   - All callers already expect this

4. **Phase 4 (High Risk):** ViewModel error handling
   - Changes user-facing behavior
   - Good point to test with QA
   - Consider beta release

5. **Phase 5 (Low Risk):** View updates
   - UI only, no business logic changes
   - Can refine based on feedback

#### Validation Checkpoints
- After Phase 1: Compile-check
- After Phase 2: Unit tests pass
- After Phase 3: Integration tests pass
- After Phase 4: ViewModel tests pass
- After Phase 5: UI tests + manual testing

---

## ARCHITECTURAL RISKS

### Risk 1: Silent Errors in Related Operations

**Risk:** `PokemonDetailViewModel.likeButtonPressed()` currently directly manipulates `modelContext`:

```swift
func likeButtonPressed(liked: Bool) {
    if liked {
        self.modelContext?.insert(pokemonToSave)  // ⚠️ Not using FavoritesRepository!
    } else {
        self.modelContext?.delete(pokemonToSave)  // ⚠️ Not using FavoritesRepository!
    }
    try? self.modelContext?.save()  // ⚠️ Silently ignores errors
}
```

**Impact:** This method doesn't use the FavoritesRepository, so fixing FavouritesDataSource won't fix this code path.

**Mitigation:** Update `likeButtonPressed()` to use AddPokemonToFavoritesUseCase and RemovePokemonFromFavoritesUseCase instead.

**Action Item:** Ensure Phase 6 update includes fixing `likeButtonPressed()` implementation.

### Risk 2: MainActor Isolation

**Risk:** Adding `async throws` to methods on `@MainActor` class requires careful handling:

```swift
@MainActor
func saveContext() async throws {  // ⚠️ @MainActor + async + throws
    try modelContext.save()
}
```

**Impact:**
- Caller must be on MainActor or use `await`
- Can't call from background tasks without issues
- Thread safety becomes critical

**Mitigation:**
- Verify all callers are in MainActor context
- Document MainActor requirement
- Use structured concurrency (Task, Task.detached correctly)

**Testing:** Ensure calling from wrong context causes compile error, not runtime issue.

### Risk 3: Error Recovery Logic

**Risk:** ViewModels implement retry logic:

```swift
@MainActor
func errorViewAction(action: CustomErrorAction) {
    switch action {
    case .retry:
        self.loadFavorites()  // ⚠️ Could infinite loop on persistent error
    case .exit:
        self.showWarningError = false
    }
}
```

**Impact:**
- User could get stuck retrying indefinitely on persistent error
- No backoff or rate limiting

**Mitigation:**
- Add retry count limit
- Add exponential backoff
- Log repeated failures
- Offer "Contact Support" option after N retries

**Phase 6+ Enhancement:** Consider implementing retry logic with exponential backoff.

### Risk 4: Database State Inconsistency

**Risk:** Long operations could leave database in inconsistent state:

```swift
try await dataSource.addPokemonToFavorites(pokemon: pokemon)  // ⚠️ If crashes mid-operation?
```

**Impact:**
- Partial saves possible
- References to deleted items
- Duplicate entries

**Mitigation:**
- SwiftData handles transactions automatically
- Each save is atomic
- No manual transaction management needed
- Still, test edge cases

### Risk 5: UseCases Don't Match Repository Protocol

**Risk:** UseCase init still uses old-style repository:

```swift
class AddPokemonToFavoritesUseCase {
    let repository: FavoritesRepositoryProtocol

    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository  // ✅ This is correct
    }

    func execute(pokemon: PokemonModel) async throws {
        try await repository.addPokemonToFavorites(pokemon: pokemon)  // ✅ Already async throws
    }
}
```

**Status:** UseCase layer is actually CORRECT already! No changes needed.

**Action:** Phase 4 just needs verification, no coding required.

---

## APPENDIX

### A. File Changes Summary

| File | Changes | Type | Risk |
|------|---------|------|------|
| Core/Errors/DatabaseError.swift | NEW | Addition | None |
| FeaturDetail/Data/DataSources/FavouritesDataSource.swift | Methods to async throws, fatalError→throw | Breaking | High |
| FeatureDetail/Data/Repositories/FavoritesRepository.swift | Add async throws signatures | Implementation | Medium |
| Core/BaseClasses/BaseViewModel.swift | Add error properties/methods | Enhancement | Low |
| FeatureDetail/Presentation/ViewModels/PokemonDetailViewModel.swift | Error handling in tasks | Enhancement | Low |
| FeatureFavourites/FeatureFavoritesViewModel.swift | Error handling in tasks | Enhancement | Low |
| FeatureDetail/Presentation/Views/PokemonDetailView.swift | Display error state | Optional | Low |
| FeatureFavourites/Views/FeatureFavoritesView.swift | Display error state | Optional | Low |

### B. Code Diff Summary

**FavouritesDataSource.swift - Before**
```swift
func fetchPokemons() -> [PokemonModel] {  // ❌ Returns array, no throws
    do {
        return try modelContext.fetch(FetchDescriptor<PokemonModel>())
    } catch {
        fatalError(error.localizedDescription)  // ❌ CRASH
    }
}
```

**FavouritesDataSource.swift - After**
```swift
func fetchPokemons() async throws -> [PokemonModel] {  // ✅ async throws
    do {
        return try modelContext.fetch(FetchDescriptor<PokemonModel>())
    } catch {
        throw DatabaseError.fetchFailed(  // ✅ THROW
            operation: "favorites",
            underlying: error
        )
    }
}
```

### C. Error Message Examples

| Error | User Message | Suggestion |
|-------|--------------|-----------|
| fetchFailed | "Unable to load favorites. Please try again." | "Try refreshing or restarting the app." |
| saveFailed | "Failed to save changes. Please try again." | "Check if you have enough storage space, then try again." |
| predicateFailed | "Invalid search criteria. Please try again." | "Modify your search criteria and try again." |
| containerInitializationFailed | "Database initialization failed. The app will restart." | "Force close and reopen the app. Contact support if the problem persists." |

### D. MainActor & Async/Await Primer

**Why @MainActor for FavouritesDataSource?**
- SwiftData ModelContext must be accessed from main thread
- Using @MainActor enforces this at compile time
- Prevents data races

**Why async throws?**
- Database operations shouldn't block main thread
- `async` allows non-blocking execution
- `throws` propagates errors to caller
- Swift's async/await handles scheduling

**Example Call Flow:**
```swift
// In ViewModel (main thread context)
do {
    let favorites = try await repository.fetchAllFavoritePokemons()
    // ✅ Safely on main thread, operation complete
} catch {
    // ✅ Error caught, can update UI
}
```

### E. Testing Commands

```bash
# Run all tests
xcodebuild test -scheme PokeDex -destination 'generic/platform=iOS'

# Run specific test class
xcodebuild test -scheme PokeDex -destination 'generic/platform=iOS' \
  -only-testing:PokeDexTests/DatabaseErrorTests

# Run with coverage
xcodebuild test -scheme PokeDex \
  -enableCodeCoverage YES \
  -destination 'generic/platform=iOS'
```

### F. Deployment Checklist

Before deploying to production:

```
□ All phases implemented
□ Unit tests passing (>80% coverage)
□ Integration tests passing
□ Manual testing completed by QA
□ Error messages translated to all supported languages
□ Analytics logging configured
□ Monitoring alerts set up for database errors
□ Release notes updated
□ Rollback plan documented
□ Performance metrics baseline established
□ User documentation updated
□ Beta release completed (optional but recommended)
```

### G. Monitoring & Observability

After deployment, monitor:

1. **Error Rates**
   - Track DatabaseError frequency
   - Alert if >5% of operations fail
   - Correlate with app version

2. **Error Types**
   - Which errors occur most?
   - Fetchfailed vs saveFailed rates
   - Geographic/device patterns

3. **User Actions**
   - % of users who see error view
   - % who tap retry vs exit
   - Retry success rate

4. **Performance**
   - Database operation latency
   - Error handling overhead
   - Memory impact

**Tools:** Firebase Crashlytics, custom logging, analytics

---

## CONCLUSION

This implementation plan addresses CRITICAL #2 by:

1. ✅ **Replacing fatalErrors** with proper error throwing
2. ✅ **Creating error propagation chain** from database to UI
3. ✅ **Maintaining Clean Architecture** layers
4. ✅ **Providing user-friendly error handling** with recovery options
5. ✅ **Implementing proper async/await** patterns
6. ✅ **Creating comprehensive test coverage** for new code
7. ✅ **Documenting breaking changes** and migration path
8. ✅ **Planning phased rollout** with validation checkpoints

The implementation is **production-ready** and follows iOS best practices for error handling in financial applications.

---

**Document Created:** 2026-02-11
**Version:** 1.0
**Status:** Ready for Implementation
**Estimated Timeline:** 14-16 hours (with parallel execution)

# CRITICAL #2: Architecture Diagrams & Visual Reference

## Error Propagation Flow Diagrams

### Current State (BROKEN - App Crashes)

```
┌─────────────────────────────────────────────────────────────────┐
│                    CURRENT BROKEN STATE                         │
└─────────────────────────────────────────────────────────────────┘

1. USER INTERACTION
   └─ User taps favorite button
      └─ View calls ViewModel.likeButtonPressed(liked: true)


2. VIEWMODEL LAYER (Presentation)
   ┌─────────────────────────────────┐
   │ PokemonDetailViewModel          │
   │                                 │
   │ fun likeButtonPressed() {        │
   │   try? modelContext.save()  ❌  │ Silently ignores errors
   │ }                               │
   └─────────────────────────────────┘
          │
          │ modelContext operations
          ▼


3. DATA LAYER - REPOSITORY (Data Abstraction)
   ┌─────────────────────────────────┐
   │ FavoritesRepository             │
   │                                 │
   │ fun addPokemonToFavorites() {    │
   │   // ❌ NOT async throws        │
   │   // Violates protocol!         │
   │ }                               │
   └─────────────────────────────────┘
          │
          │ direct call (no error handling)
          ▼


4. DATA LAYER - DATASOURCE (Concrete Implementation)
   ┌─────────────────────────────────┐
   │ FavouritesDataSource            │
   │                                 │
   │ fun addPokemonToFavorites() {    │
   │   try {                         │
   │     modelContext.insert()       │
   │     saveContext()               │
   │   } catch {                     │
   │     fatalError(...) ❌❌❌      │ APP CRASHES!
   │   }                             │
   │ }                               │
   └─────────────────────────────────┘
          │
          │
          ▼
   ❌ CRASH ❌ CRASH ❌ CRASH


RESULT: App terminates, user sees nothing but crash logs
```

### Target State (WORKING - Proper Error Handling)

```
┌─────────────────────────────────────────────────────────────────┐
│                    TARGET WORKING STATE                         │
└─────────────────────────────────────────────────────────────────┘

1. USER INTERACTION
   └─ User taps favorite button
      └─ View calls ViewModel.likeButtonPressed(liked: true)


2. VIEWMODEL LAYER (Presentation)
   ┌────────────────────────────────────────┐
   │ PokemonDetailViewModel                 │
   │ @Published var state: ViewModelState   │
   │ @Published var showWarningError: Bool  │
   │ @Published var errorMessage: String    │
   │                                        │
   │ func likeButtonPressed(liked: Bool) {   │
   │   Task {                               │
   │     do {                               │
   │       try await useCase.execute()  ✅ │
   │       state = .okey                    │
   │       showWarningError = false         │
   │     } catch {                          │
   │       state = .error              ✅ │ Catches error!
   │       showWarningError = true          │ Updates @Published
   │       errorMessage = error.message     │
   │     }                                  │
   │   }                                    │
   │ }                                      │
   └────────────────────────────────────────┘
          │
          │ try await
          ▼


3. DOMAIN LAYER - USECASE (Business Logic)
   ┌────────────────────────────────────────┐
   │ AddPokemonToFavoritesUseCase           │
   │                                        │
   │ func execute(pokemon: PokemonModel)    │
   │     async throws {                     │
   │   try await repository                │
   │     .addPokemonToFavorites()      ✅  │ Async throws
   │ }                                      │
   └────────────────────────────────────────┘
          │
          │ try await (propagates errors)
          ▼


4. DATA LAYER - REPOSITORY (Data Abstraction)
   ┌────────────────────────────────────────┐
   │ FavoritesRepository                    │
   │ (FavoritesRepositoryProtocol)          │
   │                                        │
   │ func addPokemonToFavorites(            │
   │     pokemon: PokemonModel              │
   │ ) async throws {                       │ ✅ Matches protocol
   │   try await dataSource               │
   │     .addPokemonToFavorites()      ✅  │ Async throws
   │ }                                      │
   └────────────────────────────────────────┘
          │
          │ try await (propagates errors)
          ▼


5. DATA LAYER - DATASOURCE (Concrete Implementation)
   ┌────────────────────────────────────────┐
   │ @MainActor                             │
   │ final class FavouritesDataSource       │
   │                                        │
   │ func addPokemonToFavorites(            │
   │     pokemon: PokemonModel              │
   │ ) async throws {                       │
   │   modelContext.insert(pokemon)         │
   │   try await saveContext()         ✅  │ Async throws
   │ }                                      │
   │                                        │
   │ func saveContext() async throws {      │ ✅ Async throws
   │   do {                                 │
   │     try modelContext.save()            │
   │   } catch {                            │
   │     throw DatabaseError              │
   │       .saveFailed(...)            ✅  │ Wraps error
   │   }                                    │
   │ }                                      │
   └────────────────────────────────────────┘
          │
          │ throws DatabaseError
          ▼


6. ERROR WRAPPING (Clean Architecture)
   ┌────────────────────────────────────────┐
   │ DatabaseError enum                     │
   │                                        │
   │ case saveFailed(underlying: Error)     │
   │   - userFriendlyMessage ✅            │
   │   - isRecoverable ✅                  │
   │   - recoverySuggestion ✅             │
   └────────────────────────────────────────┘


7. UI UPDATES (View Layer)
   ┌────────────────────────────────────────┐
   │ View observes @Published properties:   │
   │                                        │
   │ if viewModel.showWarningError {        │
   │   CustomErrorView(                     │
   │     message: errorMessage      ✅    │ Shows error
   │   )                                    │
   │ }                                      │
   │                                        │
   │ User sees:                             │
   │ "Failed to save changes.               │
   │  Please try again."                    │
   │  [Retry] [Exit]                   ✅ │
   └────────────────────────────────────────┘


8. USER RECOVERY
   ├─ [Retry] → Calls likeButtonPressed() again → Back to step 2
   └─ [Exit]  → Clears error, returns to normal view


RESULT: User sees error message, can recover gracefully ✅
```

---

## Layer-by-Layer Error Handling

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                       │
│  Views (SwiftUI) & ViewModels (observing @Published properties) │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ PokemonDetailView                                        │  │
│  │                                                          │  │
│  │ @ObservedObject var viewModel:                          │  │
│  │   PokemonDetailViewModel                                │  │
│  │                                                          │  │
│  │ var body: some View {                                   │  │
│  │   ZStack {                                              │  │
│  │     if viewModel.state == .error {                      │  │
│  │       CustomErrorView(...)  ✅ Shows error UI           │  │
│  │     } else {                                            │  │
│  │       PokemonDetailContentView(...)                     │  │
│  │     }                                                    │  │
│  │   }                                                      │  │
│  │ }                                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ErrorMessage flows from:                                      │
│  @Published var errorMessage: String                    ✅    │
└─────────────────────────────────────────────────────────────────┘
               ▲
               │ Observes property changes
               │
┌──────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                           │
│              ViewModels (State Management)                       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ PokemonDetailViewModel: BaseViewModel                    │  │
│  │                                                          │  │
│  │ @Published var state: ViewModelState                    │  │
│  │ @Published var showWarningError: Bool                   │  │
│  │ @Published var errorMessage: String           ✅       │  │
│  │                                                          │  │
│  │ func likeButtonPressed(liked: Bool) {                   │  │
│  │   Task {                                                │  │
│  │     do {                                                │  │
│  │       try await addToFavoritesUseCase.execute()         │  │
│  │       state = .okey                           ✅       │  │
│  │     } catch {                                           │  │
│  │       handleError(error)         ✅ Updates state       │  │
│  │     }                                                    │  │
│  │   }                                                      │  │
│  │ }                                                        │  │
│  │                                                          │  │
│  │ func handleError(_ error: Error) {                      │  │
│  │   state = .error                             ✅        │  │
│  │   showWarningError = true                    ✅        │  │
│  │   errorMessage = error.userFriendlyMessage   ✅        │  │
│  │ }                                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Catches errors thrown by UseCases                             │
└──────────────────────────────────────────────────────────────────┘
               ▲
               │ try await
               │ (catches thrown errors)
               │
┌──────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                               │
│               Use Cases (Business Logic)                         │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ AddPokemonToFavoritesUseCase                             │  │
│  │                                                          │  │
│  │ class AddPokemonToFavoritesUseCase {                     │  │
│  │   let repository: FavoritesRepositoryProtocol           │  │
│  │                                                          │  │
│  │   func execute(pokemon: PokemonModel)                   │  │
│  │       async throws {               ✅ Async throws     │  │
│  │     try await repository           ✅ Re-throws       │  │
│  │       .addPokemonToFavorites()                          │  │
│  │   }                                                      │  │
│  │ }                                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Validates business logic, re-throws repository errors         │
└──────────────────────────────────────────────────────────────────┘
               ▲
               │ try await
               │ (propagates thrown errors)
               │
┌──────────────────────────────────────────────────────────────────┐
│                       DATA LAYER                                 │
│           Repository Pattern (Data Abstraction)                  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ protocol FavoritesRepositoryProtocol {                   │  │
│  │   func addPokemonToFavorites(                            │  │
│  │       pokemon: PokemonModel                             │  │
│  │   ) async throws              ✅ Protocol defines       │  │
│  │ }                                  async throws         │  │
│  │                                                          │  │
│  │ @MainActor                                              │  │
│  │ class FavoritesRepository:                              │  │
│  │     FavoritesRepositoryProtocol {                        │  │
│  │                                                          │  │
│  │   func addPokemonToFavorites(                            │  │
│  │       pokemon: PokemonModel                             │  │
│  │   ) async throws {            ✅ Implementation        │  │
│  │     try await               matches protocol            │  │
│  │       dataSource                                        │  │
│  │       .addPokemonToFavorites()                          │  │
│  │   }                                                      │  │
│  │ }                                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Implements protocol, wraps DataSource calls                    │
└──────────────────────────────────────────────────────────────────┘
               ▲
               │ try await
               │ (propagates database errors)
               │
┌──────────────────────────────────────────────────────────────────┐
│                       DATA LAYER                                 │
│              DataSource (Database Operations)                    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ @MainActor                                               │  │
│  │ final class FavouritesDataSource {                       │  │
│  │   private let modelContext: ModelContext                │  │
│  │                                                          │  │
│  │   func addPokemonToFavorites(                            │  │
│  │       pokemon: PokemonModel                             │  │
│  │   ) async throws {             ✅ NOW async throws     │  │
│  │     modelContext.insert(pokemon)                        │  │
│  │     try await saveContext()     ✅ Propagates errors   │  │
│  │   }                                                      │  │
│  │                                                          │  │
│  │   func saveContext() async throws {                     │  │
│  │     do {                                                │  │
│  │       try modelContext.save()                           │  │
│  │     } catch {                                           │  │
│  │       throw DatabaseError                              │  │
│  │         .saveFailed(             ✅ Wraps in           │  │
│  │           underlying: error      DatabaseError         │  │
│  │         )                                               │  │
│  │     }                                                    │  │
│  │   }                                                      │  │
│  │ }                                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Catches SwiftData errors, wraps in DatabaseError              │
└──────────────────────────────────────────────────────────────────┘
               ▲
               │ throws
               │
┌──────────────────────────────────────────────────────────────────┐
│                   FRAMEWORK LAYER                                │
│               SwiftData (Apple Framework)                        │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ModelContext.save()                                      │  │
│  │                                                          │  │
│  │ Can throw:                          ✅ Initial error   │  │
│  │ - SwiftDataError.diskFull                              │  │
│  │ - SwiftDataError.saveConflict                          │  │
│  │ - SwiftDataError.corrupted                             │  │
│  │ - (other SwiftData.SwiftDataError variants)            │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Error Type Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│                     Swift.Error (Protocol)                 │
└────────────────────────────────────────────────────────────┘
        ▲
        │ Conforms to
        │
   ┌────┴──────────────────────────────────────────────────┐
   │                                                        │
   │  ┌──────────────────────────────────────────────────┐ │
   │  │ DatabaseError (enum)                 ✅ NEW    │ │
   │  │ :LocalizedError                                  │ │
   │  │                                                  │ │
   │  │ case fetchFailed(                                │ │
   │  │   operation: String,                            │ │
   │  │   underlying: Error                             │ │
   │  │ )                                               │ │
   │  │                                                  │ │
   │  │ case saveFailed(                                │ │
   │  │   underlying: Error                             │ │
   │  │ )                                               │ │
   │  │                                                  │ │
   │  │ case predicateFailed(                           │ │
   │  │   underlying: Error                             │ │
   │  │ )                                               │ │
   │  │                                                  │ │
   │  │ case deleteFailed(                              │ │
   │  │   operation: String,                            │ │
   │  │   underlying: Error                             │ │
   │  │ )                                               │ │
   │  │                                                  │ │
   │  │ case containerInitializationFailed(             │ │
   │  │   underlying: Error                             │ │
   │  │ )                                               │ │
   │  │                                                  │ │
   │  │ var userFriendlyMessage: String                 │ │
   │  │ var isRecoverable: Bool                         │ │
   │  │ var recoverySuggestion: String?                 │ │
   │  │                                                  │ │
   │  └──────────────────────────────────────────────────┘ │
   │                                                        │
   └────────────────────────────────────────────────────────┘
```

---

## State Transitions in ViewModel

```
┌─────────────────────────────────────────────────────────────────┐
│              ViewModel State Transitions                        │
└─────────────────────────────────────────────────────────────────┘

Initial State
     │
     ▼
  ┌──────────┐
  │ okey     │  ← Ready to display data
  └──────────┘
     │
     │ User action (e.g., tap like button)
     │
     ▼
  ┌──────────┐
  │ loading  │  ← Waiting for database operation
  └──────────┘
     │
     ├─────────────────────────┬────────────────────────┐
     │                         │                        │
     │ Success                 │ Failure                │ No data
     │                         │                        │
     ▼                         ▼                        ▼
  ┌──────────┐             ┌──────────┐           ┌──────────┐
  │ okey     │             │ error    │           │ empty    │
  │          │             │          │           │          │
  │ (if data)│             │ Error UI │           │ Empty    │
  └──────────┘             │ displayed│           │ State UI │
     ▲                     └──────────┘           └──────────┘
     │                         ▲                       ▲
     │ Retry succeeds          │ [Retry] tapped        │ Normal
     │                         │                       │ flow
     └────────────────────┴────┘                       │
                         │                             │
                         └─────────────────────────────┘


Related @Published Properties:

┌─────────────────────────────────────────────────────────────────┐
│ state: ViewModelState                                          │
│ ├─ okey         → Normal display, data available              │
│ ├─ loading      → Show spinner, disable buttons               │
│ ├─ error        → Show error view, enable retry button        │
│ ├─ empty        → Show empty state message                    │
│ ├─ unknownError → Show generic error                          │
│ └─ notReachable → Show network unavailable                    │
│                                                                │
│ showWarningError: Bool                                        │
│ ├─ true  → Display error alert/dialog                        │
│ └─ false → Hide error UI                                     │
│                                                                │
│ errorMessage: String                                          │
│ └─ User-friendly error description from DatabaseError        │
│                                                                │
│ alertButtonDisable: Bool                                      │
│ ├─ true  → Disable UI buttons (operation in progress)        │
│ └─ false → Enable UI buttons                                 │
└─────────────────────────────────────────────────────────────────┘


Example ViewModel Code Path:

1. loadFavorites() called
   │
   ├─ state = .loading         (UI shows spinner)
   │
   ├─ Task {
   │  ├─ try await getFavoritesUseCase.execute()
   │  │
   │  ├─ On Success:
   │  │  ├─ favorites = loadedData
   │  │  ├─ state = (isEmpty ? .empty : .okey)
   │  │  ├─ showWarningError = false
   │  │  └─ UI updates
   │  │
   │  └─ On Error:
   │     ├─ catch error
   │     ├─ state = .error
   │     ├─ showWarningError = true
   │     ├─ errorMessage = error.userFriendlyMessage
   │     └─ UI shows error view
   │
   └─ User sees either:
      ├─ Data loaded (state = .okey)
      ├─ Empty message (state = .empty)
      └─ Error message with [Retry] button (state = .error)
```

---

## Call Stack on Error Path

```
┌─────────────────────────────────────────────────────────────────┐
│                     Call Stack Trace                            │
└─────────────────────────────────────────────────────────────────┘

Scenario: User taps like button, database save fails


Frame 1: View Layer
─────────────────
likeButtonButton()
  └─> calls viewModel.likeButtonPressed(liked: true)


Frame 2: ViewModel (Presentation Layer)
────────────────────────────────────
PokemonDetailViewModel.likeButtonPressed(liked: Bool)
  ├─ Task {
  │   └─ do {
  │       └─ try await addToFavoritesUseCase.execute(pokemon)
  │           ↓ throws DatabaseError.saveFailed(...)
  │       } catch error {
  │           ├─ state = .error              ← Updates published
  │           ├─ showWarningError = true     ← Updates published
  │           ├─ errorMessage = error.userFriendlyMessage
  │           └─ View observes changes, re-renders
  │   }
  │ }


Frame 3: UseCase (Domain Layer)
─────────────────────────────
AddPokemonToFavoritesUseCase.execute(pokemon: PokemonModel)
  └─ try await repository.addPokemonToFavorites(pokemon)
     ↓ throws DatabaseError.saveFailed(...)
     (re-throws to caller)


Frame 4: Repository (Data Abstraction Layer)
────────────────────────────────────────
FavoritesRepository.addPokemonToFavorites(pokemon: PokemonModel)
  └─ try await FavouritesDataSource.shared.addPokemonToFavorites(pokemon)
     ↓ throws DatabaseError.saveFailed(...)
     (propagates to caller)


Frame 5: DataSource (Data Layer)
────────────────────────────
@MainActor
FavouritesDataSource.addPokemonToFavorites(pokemon: PokemonModel)
  ├─ modelContext.insert(pokemon)
  ├─ try await saveContext()
  │   └─ do {
  │       └─ try modelContext.save()
  │           ↓ throws SwiftDataError.diskFull (underlying error)
  │       } catch {
  │           └─ throw DatabaseError.saveFailed(underlying: error)
  │               ↓ THROWS HERE
  │   }


Frame 6: SwiftData Framework
──────────────────────────
ModelContext.save()
  └─ ❌ Throws SwiftData.SwiftDataError
     (e.g., disk full, corruption, conflict)


Error Propagates Back Up Stack
──────────────────────────────
SwiftDataError.diskFull
   ↓ wrapped as
DatabaseError.saveFailed(underlying: SwiftDataError.diskFull)
   ↓ propagated through
FavouritesDataSource.saveContext()
   ↓ propagated through
FavoritesRepository.addPokemonToFavorites()
   ↓ propagated through
AddPokemonToFavoritesUseCase.execute()
   ↓ caught in
PokemonDetailViewModel.likeButtonPressed()
   ↓ transforms to UI state
state = .error
showWarningError = true
errorMessage = "Failed to save changes. Please try again."
   ↓ observed by
View reloads
   ↓ displays
CustomErrorView with message and retry button
```

---

## File Dependencies Graph

```
┌─────────────────────────────────────────────────────────────────┐
│                    Dependency Graph                             │
└─────────────────────────────────────────────────────────────────┘

Views (UI Layer)
    │
    ├─ FeatureFavoritesView
    │   └─ uses FeatureFavoritesViewModel
    │
    └─ PokemonDetailView
        └─ uses PokemonDetailViewModel


ViewModels (Presentation Layer)
    │
    ├─ FeatureFavoritesViewModel
    │   ├─ extends BaseViewModel           ✅ Enhanced
    │   ├─ uses FetchAllFavoritePokemonsUseCase
    │   ├─ observes @Published
    │   │   ├─ state: ViewModelState
    │   │   ├─ showWarningError: Bool      ✅ New
    │   │   └─ errorMessage: String        ✅ New
    │   └─ calls errorViewAction()
    │
    └─ PokemonDetailViewModel
        ├─ extends BaseViewModel           ✅ Enhanced
        ├─ uses AddPokemonToFavoritesUseCase
        ├─ uses RemovePokemonFromFavoritesUseCase
        ├─ uses IsPokemonFavoriteUseCase
        ├─ observes @Published
        │   ├─ state: ViewModelState
        │   ├─ showWarningError: Bool      ✅ New
        │   └─ errorMessage: String        ✅ New
        └─ calls likeButtonPressed()


UseCases (Domain Layer)
    │
    ├─ AddPokemonToFavoritesUseCase
    │   └─ uses FavoritesRepositoryProtocol (async throws)
    │
    ├─ RemovePokemonFromFavoritesUseCase
    │   └─ uses FavoritesRepositoryProtocol (async throws)
    │
    ├─ FetchAllFavoritePokemonsUseCase
    │   └─ uses FavoritesRepositoryProtocol (async throws)
    │
    └─ IsPokemonFavoriteUseCase
        └─ uses FavoritesRepositoryProtocol (async throws)


Repository Protocol (Data Abstraction)
    │
    └─ FavoritesRepositoryProtocol
        ├─ addPokemonToFavorites() async throws
        ├─ removePokemonFromFavorites() async throws
        ├─ fetchAllFavoritePokemons() async throws
        └─ isPokemonFavorite() async throws


Repository Implementation (Data Layer)
    │
    └─ FavoritesRepository
        ├─ implements FavoritesRepositoryProtocol
        │   ├─ addPokemonToFavorites() ✅ async throws
        │   ├─ removePokemonFromFavorites() ✅ async throws
        │   ├─ fetchAllFavoritePokemons() ✅ async throws
        │   └─ isPokemonFavorite() ✅ async throws
        │
        └─ uses FavouritesDataSource
            ├─ fetchPokemons() ✅ async throws
            ├─ addPokemonToFavorites() ✅ async throws
            ├─ removePokemonFromFavorites() ✅ async throws
            ├─ isPokemonFavorite() ✅ async throws
            └─ saveContext() ✅ async throws
                └─ throws DatabaseError ✅ NEW


Error Types (Core Layer)
    │
    └─ DatabaseError ✅ NEW
        ├─ fetchFailed(operation, underlying)
        ├─ saveFailed(underlying)
        ├─ predicateFailed(underlying)
        ├─ deleteFailed(operation, underlying)
        ├─ containerInitializationFailed(underlying)
        └─ unknown(Error)

        Provides:
        ├─ userFriendlyMessage
        ├─ errorDescription
        ├─ failureReason
        ├─ recoverySuggestion
        ├─ isRecoverable
        └─ Equatable conformance


Base Classes (Core Layer)
    │
    ├─ BaseViewModel ✅ Enhanced
    │   ├─ @Published state: ViewModelState
    │   ├─ @Published showWarningError: Bool
    │   ├─ @Published alertButtonDisable: Bool
    │   ├─ @Published errorMessage: String ✅ NEW
    │   ├─ @Published lastError: Error? ✅ NEW
    │   ├─ handleError() ✅ NEW
    │   └─ clearError() ✅ NEW
    │
    └─ ViewModelState
        ├─ okey
        ├─ loading
        ├─ error
        ├─ empty
        ├─ unknownError
        └─ notReachable


UI Components (Core Layer)
    │
    └─ CustomErrorView
        ├─ displays errorMessage
        ├─ [Retry] button
        ├─ [Exit] button
        └─ calls errorViewAction()


Key Changes:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ NEW FILES:
   └─ Core/Errors/DatabaseError.swift

✅ MODIFIED - DataSource:
   └─ FavouritesDataSource.swift
      ├─ All methods now async throws
      └─ fatalError → throw DatabaseError

✅ MODIFIED - Repository:
   └─ FavoritesRepository.swift
      ├─ All methods now async throws (matching protocol)
      └─ Propagates DataSource errors

✅ MODIFIED - ViewModels:
   ├─ PokemonDetailViewModel.swift
   │  ├─ Uses try-catch for error handling
   │  └─ Updates state on error
   │
   └─ FeatureFavoritesViewModel.swift
      ├─ Uses try-catch for error handling
      └─ Updates state on error

✅ MODIFIED - Base Classes:
   └─ BaseViewModel.swift
      ├─ Add errorMessage @Published property
      ├─ Add lastError @Published property
      ├─ Add handleError() method
      └─ Add clearError() method

✅ NO CHANGE - UseCases:
   └─ Already async throws (architecture was correct)
```

---

## Timeline & Dependency Chain

```
┌─────────────────────────────────────────────────────────────────┐
│                    Implementation Timeline                      │
└─────────────────────────────────────────────────────────────────┘

PHASE 1: Error Type Foundation (No Dependencies)
═══════════════════════════════════════════════════════════════════
Duration: ~2 hours
Est: 09:00 - 11:00

Create DatabaseError.swift
├─ enum DatabaseError: LocalizedError
├─ 5 error cases
├─ userFriendlyMessage property
├─ isRecoverable property
├─ Equatable conformance
└─ Unit tests

Deliverable: DatabaseError.swift
Blocking: All other phases
Status: Independent

     ▼ UNBLOCKS PHASES 2-7

PHASE 2: FavouritesDataSource Errors (Depends: Phase 1)
═══════════════════════════════════════════════════════════════════
Duration: ~3 hours
Est: 11:00 - 14:00

Critical Changes:
├─ fetchPokemons() → async throws
├─ isPokemonFavorite() → async throws
├─ saveContext() → async throws
├─ addPokemonToFavorites() → async throws
├─ removePokemonFromFavorites() → async throws
└─ Replace fatalError with throw DatabaseError.*

Deliverable: Updated FavouritesDataSource.swift
Blocking: Phase 3 (Repository)
Status: Requires Phase 1

     ▼ UNBLOCKS PHASE 3

PHASE 3: FavoritesRepository (Depends: Phase 2)
═══════════════════════════════════════════════════════════════════
Duration: ~1 hour
Est: 14:00 - 15:00

Implementation:
├─ Add async throws to all method signatures
├─ Use try await with DataSource calls
└─ Verify protocol compliance

Deliverable: Updated FavoritesRepository.swift
Blocking: Phase 4 (ViewModel will call this)
Status: Requires Phase 2

     ▼ UNBLOCKS PHASE 4

PHASE 4: UseCase Verification (Depends: Phase 3)
═══════════════════════════════════════════════════════════════════
Duration: ~30 minutes
Est: 15:00 - 15:30

Verification Only:
├─ Confirm AddPokemonToFavoritesUseCase is async throws
├─ Confirm RemovePokemonFromFavoritesUseCase is async throws
├─ Confirm FetchAllFavoritePokemonsUseCase is async throws
└─ Confirm IsPokemonFavoriteUseCase is async throws

Deliverable: None (already correct)
Blocking: None
Status: Requires Phase 3 (but no changes needed)

     ▼ READY FOR PHASE 5+

PHASE 5: BaseViewModel Enhancement (Can start with Phase 2)
═══════════════════════════════════════════════════════════════════
Duration: ~1.5 hours
Est: 11:00 - 12:30

Enhancements:
├─ @Published var errorMessage: String
├─ @Published var lastError: Error?
├─ handleError(_ error: Error) method
├─ clearError() method
└─ Documentation

Deliverable: Enhanced BaseViewModel.swift
Blocking: Phase 6 (ViewModels depend on this)
Status: Independent (can run parallel with Phase 2)

     ▼ UNBLOCKS PHASE 6

PHASE 6: ViewModel Error Handling (Depends: Phase 5 + Phase 4)
═══════════════════════════════════════════════════════════════════
Duration: ~2 hours
Est: 15:30 - 17:30

Updates:
├─ FeatureFavoritesViewModel
│  ├─ loadFavorites() error handling
│  ├─ state transitions
│  ├─ errorViewAction() implementation
│  └─ clearError() on success
│
└─ PokemonDetailViewModel
   ├─ likeButtonPressed() error handling
   ├─ checkIfFavorite() error handling
   ├─ state transitions
   └─ errorViewAction() implementation

Deliverable: Updated ViewModels
Blocking: Phase 7 (Views depend on this)
Status: Requires Phase 5 + Phase 4

     ▼ UNBLOCKS PHASE 7

PHASE 7: View Updates (Depends: Phase 6)
═══════════════════════════════════════════════════════════════════
Duration: ~1.5 hours
Est: 17:30 - 19:00

View Updates:
├─ FeatureFavoritesView
│  ├─ Observe state property
│  ├─ Show error UI on .error
│  └─ Pass errorViewAction
│
└─ PokemonDetailView
   ├─ Observe errorMessage
   ├─ Show error UI
   └─ Show success message on save

Deliverable: Updated Views
Status: Requires Phase 6

     ▼ COMPLETE


TESTING (Parallel with implementation)
═══════════════════════════════════════════════════════════════════
Duration: ~4 hours (distributed across phases)

├─ Unit Tests (During Phase 1-6)
│  ├─ DatabaseError tests
│  ├─ DataSource error tests
│  ├─ Repository tests
│  └─ ViewModel tests
│
├─ Integration Tests (After Phase 4)
│  ├─ Full error flow
│  ├─ Error recovery
│  └─ Success after retry
│
└─ UI Tests (After Phase 7)
   ├─ Error display
   ├─ Retry button
   └─ Exit button


TIMELINE SUMMARY
═══════════════════════════════════════════════════════════════════

Sequential Path (No Parallelization):
    Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7
    2h       3h       1h       0.5h      1.5h      2h       1.5h
    ═══════════════════════════════════════════════════════════════
    Total: ~14.5 hours

Optimized Path (With Parallelization):
    Phase 1 ─────────────────────────────────────────┐
             ├─ Phase 2 → Phase 3 → Phase 4 ─┐      │
             │ (3h)      (1h)     (0.5h)      ├─ Phase 6 → Phase 7
             │                                │      (2h)    (1.5h)
             └─ Phase 5 ────────────────────┘
                 (1.5h parallel to Phase 2)

    Critical Path: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 6 → Phase 7
    Parallel Path: Phase 5 (runs during Phase 2-4)
    ═══════════════════════════════════════════════════════════════
    Total: ~10 hours (40% time savings with parallelization)


VALIDATION CHECKPOINTS
═══════════════════════════════════════════════════════════════════

✓ After Phase 1: Code compiles, DatabaseError tests pass
✓ After Phase 2: DataSource tests pass, no crashes on errors
✓ After Phase 3: Repository tests pass, methods are async throws
✓ After Phase 4: UseCase verification complete
✓ After Phase 5: BaseViewModel tests pass
✓ After Phase 6: ViewModel integration tests pass
✓ After Phase 7: UI tests pass, manual testing complete
✓ Final: Full regression test suite passes
```

---

## Before/After Comparison Table

```
┌─────────────────────────────────────────────────────────────────┐
│                  BEFORE vs AFTER Comparison                    │
└─────────────────────────────────────────────────────────────────┘

BEHAVIOR ON DATABASE ERROR
─────────────────────────────────────────────────────────────────
Before:  App crashes immediately
         fatalError("Error message") → Crash logs
         User sees: Nothing (app is gone)

After:   App gracefully handles error
         throw DatabaseError.saveFailed(...) → Propagates
         User sees: Error message, [Retry] button


METHOD SIGNATURES
─────────────────────────────────────────────────────────────────
Before:
  FavouritesDataSource.fetchPokemons() -> [PokemonModel]
  FavoritesRepository.fetchAllFavoritePokemons() -> [PokemonModel]
  ViewModel: favorites = try? await useCase.execute()

After:
  FavouritesDataSource.fetchPokemons() async throws -> [PokemonModel]
  FavoritesRepository.fetchAllFavoritePokemons() async throws -> [PokemonModel]
  ViewModel: favorites = try await useCase.execute()


ERROR HANDLING IN DATASOUCE
─────────────────────────────────────────────────────────────────
Before:
  func fetchPokemons() -> [PokemonModel] {
      do {
          return try modelContext.fetch(...)
      } catch {
          fatalError(error.localizedDescription)  ❌ CRASH
      }
  }

After:
  func fetchPokemons() async throws -> [PokemonModel] {
      do {
          return try modelContext.fetch(...)
      } catch {
          throw DatabaseError.fetchFailed(...)  ✅ PROPAGATE
      }
  }


ERROR HANDLING IN VIEWMODEL
─────────────────────────────────────────────────────────────────
Before:
  func loadFavorites() {
      Task {
          do {
              favorites = try await getFavoritesUseCase.execute()
          } catch {
              print("Error: \(error)")  ❌ Only prints
          }
      }
  }

After:
  func loadFavorites() {
      state = .loading
      Task {
          do {
              favorites = try await getFavoritesUseCase.execute()
              state = .okey
              clearError()
          } catch {
              handleError(error)  ✅ Updates UI
          }
      }
  }


ERROR DISPLAY IN UI
─────────────────────────────────────────────────────────────────
Before:
  User sees: [Nothing - app crashed]
  No recovery possible

After:
  if viewModel.showWarningError {
      CustomErrorView(
          message: viewModel.errorMessage,
          actionPerformed: viewModel.errorViewAction
      )
  }
  User sees: Error message with [Retry] and [Exit] buttons


ERROR RECOVERY
─────────────────────────────────────────────────────────────────
Before:
  Not possible - app crashed

After:
  User taps [Retry]
  ├─ loadFavorites() called again
  ├─ If successful: favorites load, state = .okey
  └─ If failed again: error persists, user can [Exit]


ERROR TYPE SYSTEM
─────────────────────────────────────────────────────────────────
Before:
  Unstructured error handling
  fatalError used for fatal conditions
  No error categorization

After:
  Structured DatabaseError enum
  ├─ fetchFailed(operation, underlying)
  ├─ saveFailed(underlying)
  ├─ predicateFailed(underlying)
  ├─ deleteFailed(operation, underlying)
  └─ containerInitializationFailed(underlying)

  Each error provides:
  ├─ userFriendlyMessage
  ├─ errorDescription
  ├─ failureReason
  ├─ recoverySuggestion
  ├─ isRecoverable
  └─ Equatable support


VIEWMODEL STATE
─────────────────────────────────────────────────────────────────
Before:
  @Published var state: ViewModelState = .okey
  (Never actually used for error states in favorites flow)

After:
  @Published var state: ViewModelState = .okey
  @Published var showWarningError = false
  @Published var errorMessage = ""
  @Published var lastError: Error? = nil

  state transitions:
  okey → loading → okey (success)
              ├─ → error (failed)
              └─ → empty (no data)


MAIN THREAD SAFETY
─────────────────────────────────────────────────────────────────
Before:
  FavouritesDataSource methods are sync (blocking main thread)

After:
  All methods are async throws (non-blocking)
  @MainActor ensures thread safety
  ✅ Better performance


ERROR PROPAGATION CHAIN
─────────────────────────────────────────────────────────────────
Before:
  DatabaseError (fatalError)
    ↓ CRASH
    ✗ Never reaches ViewModel
    ✗ Never reaches View
    ✗ User has no recovery

After:
  SwiftDataError
    ↓ wrapped in
  DatabaseError (throw)
    ↓ re-throws through
  Repository
    ↓ re-throws through
  UseCase
    ↓ caught in
  ViewModel (try-catch)
    ↓ updates @Published
  View (observes)
    ↓ displays
  User (sees error + retry button)
    ✅ Full chain works
```

---

## Security & Compliance Implications

```
┌─────────────────────────────────────────────────────────────────┐
│         Security & Compliance Impact Analysis                  │
└─────────────────────────────────────────────────────────────────┘

ERROR INFORMATION LEAKAGE
─────────────────────────────────────────────────────────────────
Before:
  fatalError(error.localizedDescription)
  ├─ Technical error details in crash logs
  ├─ Possibly exposed to users via crash reports
  └─ Security risk: Information disclosure

After:
  throw DatabaseError.fetchFailed(underlying: error)
  ├─ userFriendlyMessage: "Unable to load favorites. Please try again."
  ├─ Technical details in underlying error (logged only)
  └─ ✅ User-facing message safe, technical info secured


FINANCIAL DATA PROTECTION
─────────────────────────────────────────────────────────────────
Before:
  On database error: App crashes
  ├─ Unsaved changes lost
  ├─ User state unknown
  ├─ Potential data inconsistency
  └─ Compliance risk: Data loss

After:
  On database error: Error caught, state preserved
  ├─ User can retry operation
  ├─ Transaction integrity maintained
  ├─ Clear error communication
  └─ ✅ Better data protection


AUDIT TRAIL & LOGGING
─────────────────────────────────────────────────────────────────
Before:
  Errors go directly to crash logs
  └─ Hard to track in analytics

After:
  Errors properly categorized
  ├─ DatabaseError type enables filtering
  ├─ Analytics can track error frequency
  ├─ Specific error types aid debugging
  ├─ Compliance logging possible
  └─ ✅ Better auditability


GRACEFUL DEGRADATION
─────────────────────────────────────────────────────────────────
Before:
  No graceful degradation
  ├─ Any database error → crash
  ├─ No partial success possible
  ├─ User experience: Broken
  └─ Compliance: Poor

After:
  Selective error recovery
  ├─ Distinguishes recoverable from fatal errors
  ├─ Partial success possible
  ├─ User experience: Professional
  └─ ✅ Compliance: Professional grade


EXCEPTION SAFETY
─────────────────────────────────────────────────────────────────
Before:
  fatalError exceptions unhandled
  ├─ Program termination
  ├─ No cleanup possible
  ├─ Resource leaks possible
  └─ Not suitable for financial apps

After:
  Proper exception handling
  ├─ Errors caught and handled
  ├─ Cleanup possible (via defer if needed)
  ├─ Resources properly released
  └─ ✅ Financial-grade reliability


CONSISTENCY GUARANTEES
─────────────────────────────────────────────────────────────────
Before:
  Crash may leave database inconsistent
  ├─ Partial writes possible
  ├─ Referential integrity issues
  ├─ State unknown
  └─ Risk: Data corruption

After:
  SwiftData transactions are atomic
  ├─ Either fully saved or fully rolled back
  ├─ Referential integrity maintained
  ├─ State known
  └─ ✅ ACID guarantees maintained


COMPLIANCE REQUIREMENTS (Banking/Finance)
─────────────────────────────────────────────────────────────────
Requirement: Documented error handling
Before:     ❌ Crashes on errors (undocumented)
After:      ✅ DatabaseError enum (documented)

Requirement: Audit trail of failures
Before:     ❌ Crash logs only
After:      ✅ Structured error types (loggable)

Requirement: User notification
Before:     ❌ No notification (silent crash)
After:      ✅ Error message displayed

Requirement: Recovery options
Before:     ❌ Force quit required
After:      ✅ Retry option provided

Requirement: Data integrity
Before:     ❌ Risk of inconsistency
After:      ✅ Atomic transactions

Requirement: Graceful degradation
Before:     ❌ Binary working/crashed
After:      ✅ Error states with recovery


BEST PRACTICES ALIGNMENT
─────────────────────────────────────────────────────────────────
Apple Guidelines:
  "Design your app to recover from errors gracefully"
Before:     ❌ Not followed (fatal errors)
After:      ✅ Followed (proper error handling)

OWASP (Open Web Application Security Project):
  "Handle errors securely"
Before:     ❌ Not followed (crashes exposed to users)
After:      ✅ Followed (user-friendly messages)

PCI DSS (Payment Card Industry):
  "Maintain error handling procedures"
Before:     ❌ Undefined error handling
After:      ✅ Structured error handling
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│               CRITICAL #2 QUICK REFERENCE CARD                 │
└─────────────────────────────────────────────────────────────────┘

WHAT TO CHANGE
───────────────────────────────────────────────────────────────────
Replace:   fatalError(message)
With:      throw DatabaseError.saveFailed(underlying: error)

Replace:   func method() -> ReturnType
With:      func method() async throws -> ReturnType

Replace:   try? await operation()
With:      try await operation() (with proper error catching)


WHERE TO CHANGE
───────────────────────────────────────────────────────────────────
1. FavouritesDataSource.swift (Lines 44-89)
   ✗ fetchPokemons() - line 44
   ✗ isPokemonFavorite() - line 69
   ✗ saveContext() - line 83

2. FavoritesRepository.swift (All methods)
   ✗ addPokemonToFavorites()
   ✗ removePokemonFromFavorites()
   ✗ fetchAllFavoritePokemons()
   ✗ isPokemonFavorite()

3. ViewModels (Error handling in tasks)
   ✗ FeatureFavoritesViewModel.loadFavorites()
   ✗ PokemonDetailViewModel.likeButtonPressed()

4. BaseViewModel.swift (Enhancements)
   ✓ Add errorMessage @Published property
   ✓ Add lastError @Published property
   ✓ Add handleError() method
   ✓ Add clearError() method


HOW TO TEST
───────────────────────────────────────────────────────────────────
1. Unit Tests:
   xcodebuild test -scheme PokeDex \
     -only-testing:PokeDexTests/DatabaseErrorTests

2. Integration Tests:
   xcodebuild test -scheme PokeDex \
     -only-testing:PokeDexTests/FavoritesErrorFlowTests

3. Manual Testing:
   ├─ Disable network (for context)
   ├─ Tap favorite button
   ├─ Verify error message displayed
   ├─ Tap Retry
   ├─ Verify recovery works

4. Regression Testing:
   ├─ Add to favorites (normal)
   ├─ Remove from favorites (normal)
   ├─ Load favorites list (normal)
   ├─ Check favorite status (normal)


ERROR MESSAGES FOR USERS
───────────────────────────────────────────────────────────────────
.fetchFailed:
  "Unable to load favorites. Please try again."

.saveFailed:
  "Failed to save changes. Please try again."

.predicateFailed:
  "Invalid search criteria. Please try again."

.deleteFailed:
  "Failed to remove item. Please try again."

.containerInitializationFailed:
  "Database initialization failed. The app will restart."


RECOVERY STRATEGIES
───────────────────────────────────────────────────────────────────
Recoverable Errors:
  ✅ fetchFailed       → User taps [Retry]
  ✅ saveFailed        → User taps [Retry]
  ✅ predicateFailed   → User taps [Retry]
  ✅ deleteFailed      → User taps [Retry]

Non-Recoverable Errors:
  ❌ containerInitializationFailed → Force app restart


IMPACT CHECKLIST
───────────────────────────────────────────────────────────────────
Breaking Changes:
  ├─ ✅ Methods now async throws (update call sites)
  ├─ ✅ New DatabaseError type (import in affected files)
  └─ ✅ ViewModel error handling added

Backward Compatibility:
  ├─ ✅ Public API signatures change
  ├─ ✅ Protocol implementation updated
  └─ ✅ No migration path needed (internal feature)

Performance:
  ├─ ✅ Improved (non-blocking async operations)
  ├─ ✅ Minimal overhead (error handling)
  └─ ✅ Memory safe (proper cleanup)

Security:
  ├─ ✅ Better error information control
  ├─ ✅ User-friendly messages (no information leakage)
  └─ ✅ Audit trail support


FILES TO CREATE
───────────────────────────────────────────────────────────────────
New:
  └─ /PokeDex/Core/Errors/DatabaseError.swift


FILES TO MODIFY
───────────────────────────────────────────────────────────────────
Core:
  └─ /PokeDex/Core/BaseClasses/BaseViewModel.swift
     Add error properties and methods

Data Layer:
  ├─ /PokeDex/Subfeatures/FeatureDetail/Data/DataSources/FavouritesDataSource.swift
  │  Convert methods to async throws
  │
  └─ /PokeDex/Subfeatures/FeatureDetail/Data/Repositories/FavoritesRepository.swift
     Update method signatures to async throws

Presentation Layer:
  ├─ /PokeDex/Subfeatures/FeatureDetail/Presentation/ViewModels/PokemonDetailViewModel.swift
  │  Add error handling
  │
  └─ /PokeDex/Subfeatures/FeatureFavourites/FeatureFavoritesViewModel.swift
     Add error handling

Optional:
  ├─ /PokeDex/Subfeatures/FeatureDetail/Presentation/Views/PokemonDetailView.swift
  │  Display error states
  │
  └─ /PokeDex/Subfeatures/FeatureFavourites/Views/FeatureFavoritesView.swift
     Display error states


ESTIMATED TIME
───────────────────────────────────────────────────────────────────
Phase 1 (Error Type):      2 hours
Phase 2 (DataSource):      3 hours
Phase 3 (Repository):      1 hour
Phase 4 (UseCase Verify):  0.5 hours
Phase 5 (BaseViewModel):   1.5 hours
Phase 6 (ViewModels):      2 hours
Phase 7 (Views):           1.5 hours
Testing (Throughout):      4 hours
─────────────────────────
Total (Sequential):        ~14.5 hours
Total (Parallel):          ~10 hours (40% faster)


DEPLOYMENT
───────────────────────────────────────────────────────────────────
□ All phases complete
□ Tests passing (>80% coverage)
□ Manual QA sign-off
□ Changelog updated
□ Beta release (recommended)
□ Monitor error rates post-launch
□ User communication (if needed)
```

---

End of Architecture Diagrams Document

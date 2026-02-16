# Code Examples: Clean Architecture in Action

This document showcases real code examples from PokéDex demonstrating Clean Architecture patterns and best practices.

---

## Table of Contents

1. [Data Layer](#data-layer)
2. [Domain Layer](#domain-layer)
3. [Presentation Layer](#presentation-layer)
4. [Error Handling](#error-handling)
5. [Async/Await Patterns](#asyncawait-patterns)
6. [Testing](#testing)

---

## Data Layer

### Data Transfer Objects (DTOs)

DTOs map exactly to API responses. They're separate from Domain entities:

```swift
// MARK: - API Response Models (DTOs)

struct PokemonListResponseModel: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonResponseModel]
}

struct PokemonResponseModel: Codable {
    let name: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case name
        case url
    }
}

struct PokemonDetailResponseModel: Codable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let baseExperience: Int?
    let types: [PokemonTypeDTO]
    let stats: [StatDTO]
    let sprites: SpritesDTO
    let species: SpeciesDTO

    enum CodingKeys: String, CodingKey {
        case id, name, height, weight
        case baseExperience = "base_experience"
        case types, stats, sprites, species
    }
}
```

**Why separate from Domain?**
- API response format can change without affecting business logic
- Multiple data sources can use different DTOs
- Decoupling from external dependencies

### DataSource: Network Operations

DataSources handle raw data fetching:

```swift
@MainActor
final class ExploreDataSource {

    /// Fetches the list of Pokémon from PokeAPI.
    ///
    /// - Parameters:
    ///   - limit: Number of Pokémon to fetch
    /// - Returns: PokemonListResponseModel containing paginated results
    /// - Throws: NetworkError if the request fails
    func fetchPokemons(limit: Int) async throws -> PokemonListResponseModel {
        let endpoint = "https://pokeapi.co/api/v2/pokemon?limit=\(limit)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let result = try decoder.decode(
            PokemonListResponseModel.self,
            from: data
        )

        return result
    }

    /// Fetches detailed information for a specific Pokémon.
    ///
    /// - Parameter id: The Pokémon ID
    /// - Returns: PokemonDetailResponseModel with full details
    /// - Throws: NetworkError if the request fails
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailResponseModel {
        let endpoint = "https://pokeapi.co/api/v2/pokemon/\(id)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(
            PokemonDetailResponseModel.self,
            from: data
        )
    }
}
```

**Key Points**:
- ✅ Only handles network communication
- ✅ Proper error handling with typed errors
- ✅ Async/await for modern concurrency
- ✅ Thread-safe with @MainActor
- ✅ Well-documented with DocC comments

### Repository: Data Abstraction

Repositories implement Domain protocols and handle DTO → Entity mapping:

```swift
final class ExploreRepository: ExploreRepositoryProtocol {
    private let exploreDataSource: ExploreDataSource

    init(exploreDataSource: ExploreDataSource) {
        self.exploreDataSource = exploreDataSource
    }

    /// Fetches list of Pokémon and converts to entities.
    ///
    /// - Parameter limit: Number of Pokémon to fetch
    /// - Returns: Array of PokemonEntity objects
    /// - Throws: Propagates DataSource errors
    func fetchPokemons(limit: Int) async throws -> [PokemonEntity] {
        let response = try await exploreDataSource.fetchPokemons(limit: limit)

        return response.results.compactMap { pokemonResponse in
            // Map DTO to Entity
            PokemonEntity(
                id: extractIdFromUrl(pokemonResponse.url),
                name: pokemonResponse.name.capitalized
            )
        }
    }

    /// Fetches detailed information for a Pokémon.
    ///
    /// - Parameter id: The Pokémon ID
    /// - Returns: Complete PokemonEntity with all details
    /// - Throws: Propagates DataSource errors
    func fetchPokemonDetail(id: Int) async throws -> PokemonEntity {
        let response = try await exploreDataSource.fetchPokemonDetail(id: id)

        return PokemonEntity(
            id: response.id,
            name: response.name.capitalized,
            height: response.height,
            weight: response.weight,
            types: mapTypes(response.types),
            stats: mapStats(response.stats),
            artwork: response.sprites.other?.officialArtwork?.frontDefault
        )
    }

    private func extractIdFromUrl(_ url: String) -> Int {
        let components = url.split(separator: "/")
        return Int(components[components.count - 2]) ?? 0
    }

    private func mapTypes(_ dtoTypes: [PokemonTypeDTO]) -> [PokemonTypes] {
        dtoTypes.map { PokemonTypes(name: $0.type.name) }
    }

    private func mapStats(_ dtoStats: [StatDTO]) -> PokemonStats {
        PokemonStats(
            hp: dtoStats.first(where: { $0.stat.name == "hp" })?.baseStat ?? 0,
            attack: dtoStats.first(where: { $0.stat.name == "attack" })?.baseStat ?? 0,
            defense: dtoStats.first(where: { $0.stat.name == "defense" })?.baseStat ?? 0
            // ... more stats
        )
    }
}
```

**Why this pattern?**
- ✅ Separates network details from business logic
- ✅ DTO → Entity transformation in one place
- ✅ Repository protocol enables mocking for tests
- ✅ Easy to add caching later

---

## Domain Layer

### Entities: Pure Business Objects

Entities represent core business concepts, independent of frameworks:

```swift
/// Represents a Pokémon in the business domain.
///
/// Entities are framework-agnostic and contain no persistence,
/// networking, or UI logic. They're pure business objects.
struct PokemonEntity: Sendable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let types: [PokemonTypes]
    let stats: PokemonStats
    let artwork: String?

    init(
        id: Int,
        name: String,
        height: Int = 0,
        weight: Int = 0,
        types: [PokemonTypes] = [],
        stats: PokemonStats = PokemonStats(),
        artwork: String? = nil
    ) {
        self.id = id
        self.name = name
        self.height = height
        self.weight = weight
        self.types = types
        self.stats = stats
        self.artwork = artwork
    }
}

struct PokemonStats: Sendable {
    let hp: Int
    let attack: Int
    let defense: Int
    let spAtk: Int
    let spDef: Int
    let speed: Int

    init(
        hp: Int = 0,
        attack: Int = 0,
        defense: Int = 0,
        spAtk: Int = 0,
        spDef: Int = 0,
        speed: Int = 0
    ) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.spAtk = spAtk
        self.spDef = spDef
        self.speed = speed
    }
}
```

**Key Characteristics**:
- ✅ No imports of UI frameworks
- ✅ No Codable conformance (that's for DTOs)
- ✅ Pure data representation
- ✅ `Sendable` for thread-safety

### Repository Protocol: Contracts

Define contracts in Domain, implement in Data:

```swift
/// Protocol for Pokémon data access operations.
///
/// This protocol defines the contract that any data source
/// (network, local database, cache) must fulfill.
protocol ExploreRepositoryProtocol: Sendable {

    /// Fetches a list of Pokémon.
    ///
    /// - Parameter limit: Maximum number of Pokémon to retrieve
    /// - Returns: Array of PokemonEntity objects
    /// - Throws: DataError if the operation fails
    func fetchPokemons(limit: Int) async throws -> [PokemonEntity]

    /// Fetches detailed information for a specific Pokémon.
    ///
    /// - Parameter id: The Pokémon's unique identifier
    /// - Returns: Detailed PokemonEntity
    /// - Throws: DataError if the Pokémon is not found
    func fetchPokemonDetail(id: Int) async throws -> PokemonEntity
}
```

**Design Benefits**:
- ✅ Domain doesn't depend on implementation details
- ✅ Easy to mock for tests
- ✅ Can swap implementations (HTTP → Cache → Local DB)
- ✅ Dependency Inversion Principle in action

### Use Cases: Business Logic

UseCases encapsulate specific business operations:

```swift
/// Use case for retrieving the list of Pokémon.
///
/// Handles fetching Pokémon list with proper error handling
/// and logging. One responsibility: get Pokemon list.
@MainActor
final class GetPokemonListUseCase {
    private let pokeDexRepository: ExploreRepositoryProtocol

    init(pokeDexRepository: ExploreRepositoryProtocol) {
        self.pokeDexRepository = pokeDexRepository
    }

    /// Executes the use case to fetch Pokémon list.
    ///
    /// - Parameter limit: Number of Pokémon to fetch
    /// - Returns: Array of Pokémon entities
    /// - Throws: DataError if fetching fails
    func execute(limit: Int = 155) async throws -> [PokemonEntity] {
        return try await pokeDexRepository.fetchPokemons(limit: limit)
    }
}

/// Use case for retrieving detailed Pokémon information.
@MainActor
final class GetPokemonDetailUseCase {
    private let pokeDexRepository: ExploreRepositoryProtocol

    init(pokeDexRepository: ExploreRepositoryProtocol) {
        self.pokeDexRepository = pokeDexRepository
    }

    /// Fetches detailed information for a single Pokémon.
    ///
    /// - Parameter id: The Pokémon ID
    /// - Returns: Detailed Pokémon entity
    /// - Throws: DataError if not found
    func execute(id: Int) async throws -> PokemonEntity {
        return try await pokeDexRepository.fetchPokemonDetail(id: id)
    }
}
```

**UseCases Design**:
- ✅ One responsibility per UseCase
- ✅ Testable without UI or networking
- ✅ Encapsulates business rules
- ✅ Easy to compose for complex operations

---

## Presentation Layer

### ViewModels: UI Logic

ViewModels manage UI state and communicate with UseCases:

```swift
/// ViewModel for the Pokémon exploration screen.
///
/// Manages:
/// - Loading and storing Pokémon list
/// - UI state (loading, error, success)
/// - User interactions
/// - Error presentation to user
@MainActor
final class PokemonExploreViewModel: BaseViewModel, ObservableObject {

    // MARK: - Published Properties
    @Published var pokemons = [PokemonModel]()
    @Published var state: ViewModelState = .idle

    // MARK: - Dependencies
    private let getPokemonListUseCase: GetPokemonListUseCase
    private let getPokemonDetailUseCase: GetPokemonDetailUseCase

    // MARK: - Initialization
    init(
        getPokemonListUseCase: GetPokemonListUseCase,
        getPokemonDetailUseCase: GetPokemonDetailUseCase
    ) {
        self.getPokemonListUseCase = getPokemonListUseCase
        self.getPokemonDetailUseCase = getPokemonDetailUseCase
        super.init()
    }

    // MARK: - Public Methods

    /// Loads the initial list of Pokémon.
    func loadPokemonList() async {
        state = .loading
        do {
            let entities = try await getPokemonListUseCase.execute(limit: 155)

            // Convert entities to presentation models
            let models = entities.map { PokemonModel(entity: $0) }

            await MainActor.run {
                self.pokemons = models
                self.state = .okey
            }
        } catch {
            await MainActor.run {
                self.state = .error
                self.showWarningError = true
                self.logError("Failed to load Pokémon list", error: error)
            }
        }
    }

    /// Fetches detailed information for a Pokémon.
    ///
    /// - Parameter id: The Pokémon ID
    func fetchPokemonDetail(id: Int) async {
        do {
            let entity = try await getPokemonDetailUseCase.execute(id: id)
            let model = PokemonModel(entity: entity)

            await MainActor.run {
                // Update specific Pokémon in list
                if let index = self.pokemons.firstIndex(where: { $0.id == id }) {
                    self.pokemons[index] = model
                }
            }
        } catch {
            self.logError("Failed to fetch Pokémon details", error: error)
        }
    }

    // MARK: - Error Handling
    override func errorViewAction(action: CustomErrorAction) {
        showWarningError = false
    }
}
```

**ViewModel Responsibilities**:
- ✅ Manages UI state (@Published properties)
- ✅ Calls UseCases for business logic
- ✅ Converts entities to presentation models
- ✅ Handles errors and user feedback
- ✅ @MainActor ensures thread-safety

### SwiftUI Views

Views observe ViewModel state and delegate actions:

```swift
struct PokemonExploreView: View {
    @StateObject private var viewModel: PokemonExploreViewModel

    init(viewModel: PokemonExploreViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .idle, .loading:
                LoaderView()

            case .okey:
                pokemonList

            case .error:
                errorView
            }
        }
        .onAppear {
            Task {
                await viewModel.loadPokemonList()
            }
        }
        .alert(
            "Error",
            isPresented: $viewModel.showWarningError,
            actions: {
                Button("OK") {
                    viewModel.errorViewAction(action: .ok)
                }
            },
            message: {
                Text("Failed to load Pokémon. Please try again.")
            }
        )
    }

    private var pokemonList: some View {
        List {
            ForEach(viewModel.pokemons) { pokemon in
                PokemonCellView(pokemon: pokemon)
                    .onAppear {
                        Task {
                            await viewModel.fetchPokemonDetail(id: pokemon.id)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    private var errorView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Failed to load Pokémon")
                .font(.headline)
            Button("Try Again") {
                Task {
                    await viewModel.loadPokemonList()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}
```

**View Best Practices**:
- ✅ No business logic in views
- ✅ Observes ViewModel state reactively
- ✅ Delegates user actions to ViewModel
- ✅ Handles different states (loading, error, success)
- ✅ Uses extracted sub-views for readability

---

## Error Handling

### Typed Errors

Use proper error types instead of generic Error:

```swift
/// Custom errors for data operations.
enum DataError: LocalizedError, Sendable {
    case networkFailure(String)
    case decodingFailure(String)
    case notFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .networkFailure(let message):
            return "Network error: \(message)"
        case .decodingFailure(let message):
            return "Failed to parse data: \(message)"
        case .notFound:
            return "Pokémon not found"
        case .invalidData:
            return "Invalid data received"
        }
    }
}
```

### Error Propagation

Let errors propagate up with proper handling:

```swift
func loadPokemonList() async {
    state = .loading
    do {
        let entities = try await getPokemonListUseCase.execute(limit: 155)
        let models = entities.map { PokemonModel(entity: $0) }

        self.pokemons = models
        self.state = .okey

    } catch let error as DataError {
        // Handle specific errors
        state = .error
        logError("Data error: \(error.localizedDescription)", error: error)

    } catch {
        // Handle unknown errors
        state = .error
        logError("Unexpected error", error: error)
    }

    showWarningError = (state == .error)
}
```

### Logging

Centralized error logging in BaseViewModel:

```swift
@MainActor
class BaseViewModel: ObservableObject {
    @Published var showWarningError = false

    /// Logs an error with OSLog for debugging.
    ///
    /// - Parameters:
    ///   - message: User-friendly error message
    ///   - error: The actual error object
    func logError(_ message: String, error: Error? = nil) {
        let logger = Logger(subsystem: "com.pokedex", category: "ViewModels")

        if let error = error {
            logger.error("\(message): \(error.localizedDescription)")
        } else {
            logger.error("\(message)")
        }
    }
}
```

---

## Async/Await Patterns

### TaskGroups for Parallel Operations

Fetch multiple Pokémon details in parallel:

```swift
/// Fetches details for multiple Pokémon in parallel.
///
/// Uses TaskGroup to fetch details concurrently, improving performance
/// by factor of ~3-4x compared to sequential fetching.
///
/// - Parameter ids: Array of Pokémon IDs
/// - Returns: Dictionary of Pokemon ID to detailed entity
/// - Throws: Propagates any fetch errors
func fetchPokemonDetailsInParallel(ids: [Int]) async throws -> [PokemonEntity] {
    var results: [PokemonEntity] = []

    try await withThrowingTaskGroup(of: PokemonEntity.self) { group in
        for id in ids {
            group.addTask {
                return try await self.getPokemonDetailUseCase.execute(id: id)
            }
        }

        for try await pokemon in group {
            results.append(pokemon)
        }
    }

    return results
}
```

### Error Handling in TaskGroups

Properly handle errors in concurrent operations:

```swift
func loadPokemonDetailsWithErrorHandling(ids: [Int]) async {
    do {
        let pokemonDetails = try await fetchPokemonDetailsInParallel(ids: ids)

        await MainActor.run {
            self.pokemons = pokemonDetails.map { PokemonModel(entity: $0) }
            self.state = .okey
        }

    } catch {
        await MainActor.run {
            self.state = .error
            self.showWarningError = true
            self.logError("Failed to load Pokémon details", error: error)
        }
    }
}
```

---

## Testing

### Mocking Dependencies

Create mocks for testing without real dependencies:

```swift
// MARK: - Mock Repository

class MockExploreRepository: ExploreRepositoryProtocol {
    var pokemonsToReturn: [PokemonEntity] = []
    var shouldThrowError = false
    var error: Error?

    func fetchPokemons(limit: Int) async throws -> [PokemonEntity] {
        if shouldThrowError {
            throw error ?? DataError.networkFailure("Mock error")
        }
        return pokemonsToReturn
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonEntity {
        if shouldThrowError {
            throw error ?? DataError.notFound
        }

        return pokemonsToReturn.first { $0.id == id }
            ?? PokemonEntity(id: id, name: "Unknown")
    }
}
```

### UseCase Tests

Test business logic in isolation:

```swift
@MainActor
class GetPokemonListUseCaseTests: XCTestCase {
    var sut: GetPokemonListUseCase!
    var mockRepository: MockExploreRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockExploreRepository()
        sut = GetPokemonListUseCase(pokeDexRepository: mockRepository)
    }

    func testExecuteReturnsPokemonList() async throws {
        // Arrange
        let expectedPokemon = PokemonEntity(
            id: 1,
            name: "Bulbasaur",
            types: [PokemonTypes(name: "grass")],
            stats: PokemonStats(hp: 45, attack: 49)
        )
        mockRepository.pokemonsToReturn = [expectedPokemon]

        // Act
        let result = try await sut.execute(limit: 10)

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Bulbasaur")
    }

    func testExecuteThrowsErrorWhenRepositoryFails() async {
        // Arrange
        mockRepository.shouldThrowError = true
        mockRepository.error = DataError.networkFailure("No connection")

        // Act & Assert
        do {
            _ = try await sut.execute(limit: 10)
            XCTFail("Should have thrown an error")
        } catch DataError.networkFailure(let message) {
            XCTAssertEqual(message, "No connection")
        } catch {
            XCTFail("Unexpected error type")
        }
    }
}
```

### ViewModel Tests

Test UI logic with mocked UseCases:

```swift
@MainActor
class PokemonExploreViewModelTests: XCTestCase {
    var sut: PokemonExploreViewModel!
    var mockGetListUseCase: MockGetPokemonListUseCase!
    var mockGetDetailUseCase: MockGetPokemonDetailUseCase!

    override func setUp() {
        super.setUp()
        mockGetListUseCase = MockGetPokemonListUseCase()
        mockGetDetailUseCase = MockGetPokemonDetailUseCase()

        sut = PokemonExploreViewModel(
            getPokemonListUseCase: mockGetListUseCase,
            getPokemonDetailUseCase: mockGetDetailUseCase
        )
    }

    func testLoadPokemonListUpdatesState() async {
        // Arrange
        let pokemon = PokemonEntity(id: 1, name: "Bulbasaur")
        mockGetListUseCase.pokemonsToReturn = [pokemon]

        // Act
        await sut.loadPokemonList()

        // Assert
        XCTAssertEqual(sut.state, .okey)
        XCTAssertEqual(sut.pokemons.count, 1)
        XCTAssertEqual(sut.pokemons.first?.name, "Bulbasaur")
    }

    func testLoadPokemonListHandlesError() async {
        // Arrange
        mockGetListUseCase.shouldThrowError = true
        mockGetListUseCase.error = DataError.networkFailure("No internet")

        // Act
        await sut.loadPokemonList()

        // Assert
        XCTAssertEqual(sut.state, .error)
        XCTAssertTrue(sut.showWarningError)
        XCTAssertEqual(sut.pokemons.count, 0)
    }
}
```

---

## Key Takeaways

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Testability**: Mock dependencies for isolated testing
3. **Error Handling**: Use typed errors and proper propagation
4. **Async/Await**: Modern concurrency for clean async code
5. **Data Transformation**: DTO → Entity → Presentation Model
6. **Thread Safety**: @MainActor for UI updates
7. **Documentation**: DocC comments for clarity

This architecture makes PokéDex maintainable, testable, and scalable.

---

**Last Updated**: February 2026

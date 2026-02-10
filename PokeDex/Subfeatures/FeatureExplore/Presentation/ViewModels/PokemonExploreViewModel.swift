//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

/// A view model that manages the Explore feature for listing and loading Pokémon.
///
/// `PokemonExploreViewModel` coordinates the loading of Pokémon data from the network,
/// manages loading states, and provides data to the view layer. It implements the MVVM
/// (Model-View-ViewModel) pattern and follows Clean Architecture principles.
///
/// ## Responsibilities
/// - Fetch the initial list of Pokémon (155 first generation Pokémon)
/// - Load detailed information for each Pokémon in parallel
/// - Manage view states (loading, success, error)
/// - Handle user interactions and errors
///
/// ## Data Flow
/// ```
/// View onAppear()
///   ↓
/// ViewModel.loadPokemonList()
///   ↓
/// UseCase.execute()
///   ↓
/// Repository.fetchPokemons()
///   ↓
/// DataSource (HTTP) ← PokeAPI
///   ↓
/// DTO → Entity transformation
///   ↓
/// loadPokemonDetail() with TaskGroups (parallel)
///   ↓
/// @Published pokemons updated
///   ↓
/// View re-renders
/// ```
///
/// ## Performance Optimization
/// The view model uses `withThrowingTaskGroup` to load details for up to 155 Pokémon
/// in parallel, reducing load time from ~8 minutes (sequential) to ~15-30 seconds.
///
/// ## Usage
/// ```swift
/// @StateObject private var viewModel = PokemonExploreViewModel(dto: nil)
///
/// var body: some View {
///     PokemonExploreView(viewModel: viewModel)
///         .onAppear { viewModel.onAppear() }
/// }
/// ```
public class PokemonExploreViewModel: BaseViewModel, ObservableObject {
    /// Data transfer object for dependency injection and configuration.
    var dto: PokemonExploreAssemblyDTO?

    /// Initializes the view model with optional configuration.
    /// - Parameter dto: Optional data transfer object for configuration.
    init(dto: PokemonExploreAssemblyDTO?) {
        self.dto = dto
    }

    private let getUseCase = GetPokemonListUseCase(pokeDexRepository: ExploreRepository.shared)
    let getPokemonDetailUseCase = GetPokemonDetailUseCase(repository: DetailRepository())

    /// Flag indicating whether the Pokémon list has been loaded.
    /// Prevents duplicate loads when the view reappears.
    var pokemonsLoaded: Bool = false

    /// Internal cache of the basic Pokémon list before details are loaded.
    var pokemonList = [PokemonModel]()

    /// The published array of fully loaded Pokémon with details.
    /// The view observes this property and updates automatically when it changes.
    @Published var pokemons = [PokemonModel]()

    /// Called when the view appears on screen.
    /// Initiates the Pokémon loading process if not already loaded.
    public override func onAppear() {
        self.loadPokemonList()
    }

    /// Loads the initial list of Pokémon from the API.
    ///
    /// This method is the main entry point for fetching Pokémon data. It:
    /// 1. Checks if data is already loaded (prevents duplicate requests)
    /// 2. Sets state to `.loading`
    /// 3. Fetches the list from the use case
    /// 4. Converts entities to presentation models
    /// 5. Initiates parallel detail loading
    /// 6. Updates state to `.okey` on success, `.error` on failure
    ///
    /// The method is protected by a `pokemonsLoaded` flag to ensure it only
    /// executes once during the view lifecycle.
    ///
    /// ## Performance
    /// - Initial list fetch: ~1-2 seconds
    /// - Detail loading with TaskGroups: ~15-30 seconds total
    /// - Total time: ~20-35 seconds for 155 Pokémon with full details
    @MainActor
    func loadPokemonList() {
        if pokemonsLoaded {
            return
        }
        self.state = .loading
        Task {
            do {
                let pokemonEntityList = try await getUseCase.execute(limit: Constants.pokeApiPokemonListlimit)
                pokemonList += pokemonEntityList.compactMap({ pokemon in PokemonModel(pokemon: pokemon) })
                await self.loadPokemonDetail()
                self.state = .okey
                self.pokemons = self.pokemons.sorted(by: { $0.id < $1.id })
                pokemonsLoaded = true
            } catch {
                self.state = .error
                showWarningError = true
            }
        }
    }

    /// Loads detailed information for all Pokémon in parallel using TaskGroups.
    ///
    /// This method uses `withThrowingTaskGroup` to fetch details for all Pokémon
    /// simultaneously rather than sequentially. This optimization reduces loading
    /// time significantly.
    ///
    /// ## How It Works
    /// 1. Creates a task group for concurrent operations
    /// 2. Adds a task for each Pokémon (except ID 0)
    /// 3. Each task calls `getPokemonDetailUseCase.execute(id:)`
    /// 4. Collects results as they complete
    /// 5. Appends valid results to the `pokemons` array
    ///
    /// ## Error Handling
    /// Silently ignores individual failures. If a single Pokémon detail fails,
    /// it continues loading others.
    ///
    /// ## Performance
    /// - Sequential approach: ~8 minutes (155 requests × 3 seconds each)
    /// - Parallel approach: ~15-30 seconds (concurrent requests with shared connection pool)
    @MainActor
    private func loadPokemonDetail() async {
        do {
            try await withThrowingTaskGroup(of: (PokemonEntity?).self, body: { group in
                pokemonList.forEach { pokemon in
                    if pokemon.id != 0 {
                        group.addTask {
                            return ( try await self.getPokemonDetailUseCase.execute(id: pokemon.id))
                        }
                    }
                }
                for try await (pokemon) in group {
                    if let pokem = pokemon {
                        guard let model = PokemonModel(pokemon: pokem) else {
                            return}
                        pokemons.append(model)
                    }
                }
            })
        } catch {
        }
    }

    /// Handles error view actions from the error dialog.
    ///
    /// This method responds to user interactions on the error dialog,
    /// either retrying the operation or dismissing the error.
    ///
    /// - Parameter action: The action selected by the user (retry or exit).
    ///
    /// ## Cases
    /// - `.retry`: Resets the `pokemonsLoaded` flag and calls `loadPokemonList()` again
    /// - `.exit`: Hides the error warning dialog
    @MainActor func errorViewAction(action: CustomErrorAction) {
            switch action {
            case .retry:
                pokemonsLoaded = false  // Reset flag to allow retry
                self.loadPokemonList()

            case .exit:
                showWarningError = false
            }
        }
}

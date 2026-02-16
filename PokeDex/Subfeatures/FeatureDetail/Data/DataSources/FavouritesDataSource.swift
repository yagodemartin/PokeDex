//
//  DataSource.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//
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
    /// - Throws: Any errors that occur during the database fetch operation.
    func fetchPokemons() async throws -> [PokemonModel] {
        return try modelContext.fetch(FetchDescriptor<PokemonModel>())
    }

    /// Adds a Pokémon to the favorites list.
    /// - Parameter pokemon: The PokemonModel object to add to favorites.
    /// - Throws: Any errors that occur during the insert or save operation.
    func addPokemonToFavorites(pokemon: PokemonModel) async throws {
        modelContext.insert(pokemon)
        try await saveContext()
    }

    /// Removes a Pokémon from the favorites list.
    /// - Parameter pokemon: The PokemonModel object to remove from favorites.
    /// - Throws: Any errors that occur during the delete or save operation.
    func removePokemonFromFavorites(pokemon: PokemonModel) async throws {
        modelContext.delete(pokemon)
        try await saveContext()
    }

    /// Checks if a specific Pokémon is in the favorites list.
    /// - Parameter pokemon: The PokemonModel object to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: Any errors that occur during the database fetch operation.
    func isPokemonFavorite(pokemon: PokemonModel) async throws -> Bool {
        let idPokemon = pokemon.id
        let fetchDescriptor = FetchDescriptor<PokemonModel>(predicate: #Predicate {
            $0.id == idPokemon}, sortBy: [.init(\.id, order: .forward)])

        let results = try modelContext.fetch(fetchDescriptor)
        return !results.isEmpty
    }

    /// Saves the current state of the model context.
    /// - Throws: Any errors that occur during the save operation.
    func saveContext() async throws {
        try modelContext.save()
    }
}

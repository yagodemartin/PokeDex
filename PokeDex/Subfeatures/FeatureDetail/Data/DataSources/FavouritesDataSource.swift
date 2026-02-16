//
//  FavouritesDataSource.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

import SwiftUI
import SwiftData

/// DataSource for managing Pokémon favorites in SwiftData.
///
/// Handles all database operations for favorite Pokémon using SwiftData.
/// Operates exclusively on the main thread with @MainActor.
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
    ///
    /// - Returns: An array of PokemonModel objects that are marked as favorites.
    /// - Throws: Any errors that occur during the database fetch operation.
    func fetchPokemons() async throws -> [PokemonModel] {
        return try modelContext.fetch(FetchDescriptor<PokemonModel>())
    }

    /// Adds a Pokémon to the favorites list.
    ///
    /// Creates a new PokemonModel instance and inserts it into the database.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to add to favorites.
    /// - Throws: Any errors that occur during the insert or save operation.
    func addPokemonToFavorites(pokemonID: Int) async throws {
        let fetchDescriptor = FetchDescriptor<PokemonModel>(
            predicate: #Predicate { $0.id == pokemonID },
            sortBy: [.init(\.id, order: .forward)]
        )

        let results = try modelContext.fetch(fetchDescriptor)

        if results.isEmpty {
            let pokemon = PokemonModel(id: pokemonID, name: "")
            modelContext.insert(pokemon)
            try await saveContext()
        }
    }

    /// Removes a Pokémon from the favorites list.
    ///
    /// Finds the Pokémon by ID and deletes it from the database.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to remove from favorites.
    /// - Throws: Any errors that occur during the delete or save operation.
    func removePokemonFromFavorites(pokemonID: Int) async throws {
        let fetchDescriptor = FetchDescriptor<PokemonModel>(
            predicate: #Predicate { $0.id == pokemonID },
            sortBy: [.init(\.id, order: .forward)]
        )

        let results = try modelContext.fetch(fetchDescriptor)

        for pokemon in results {
            modelContext.delete(pokemon)
        }

        try await saveContext()
    }

    /// Checks if a specific Pokémon is in the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: Any errors that occur during the database fetch operation.
    func isPokemonFavorite(pokemonID: Int) async throws -> Bool {
        let fetchDescriptor = FetchDescriptor<PokemonModel>(
            predicate: #Predicate { $0.id == pokemonID },
            sortBy: [.init(\.id, order: .forward)]
        )

        let results = try modelContext.fetch(fetchDescriptor)
        return !results.isEmpty
    }

    /// Saves the current state of the model context.
    ///
    /// - Throws: Any errors that occur during the save operation.
    func saveContext() async throws {
        try modelContext.save()
    }
}

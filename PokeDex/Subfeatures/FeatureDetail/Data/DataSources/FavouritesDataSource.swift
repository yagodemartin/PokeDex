//
//  FavouritesDataSource.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

import SwiftUI
import SwiftData

/// Data Transfer Object for storing Pokémon favorites in SwiftData.
///
/// Complete DTO that stores all Pokémon data independently from PokemonModel.
/// This prevents assertion failures when PokemonModel is modified or deleted.
/// All fields are copied from PokemonModel to create a persistent snapshot.
@Model
final class FavoritePokemonDTO {
    var pokemonID: Int
    var name: String
    var imageURL: URL?
    var height: Int?
    var weight: Int?
    var types: [PokemonTypes]
    var stats: PokemonStats?

    init(
        pokemonID: Int,
        name: String,
        imageURL: URL? = nil,
        height: Int? = nil,
        weight: Int? = nil,
        types: [PokemonTypes] = [],
        stats: PokemonStats? = nil
    ) {
        self.pokemonID = pokemonID
        self.name = name
        self.imageURL = imageURL
        self.height = height
        self.weight = weight
        self.types = types
        self.stats = stats
    }
}

/// DataSource for managing Pokémon favorites in SwiftData.
///
/// Handles all database operations for favorite Pokémon using SwiftData.
/// Operates exclusively on the main thread with @MainActor.
/// Uses FavoritePokemonDTO to avoid keeping references to PokemonModel.
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
        let schema = Schema([FavoritePokemonDTO.self])
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
    /// - Returns: An array of FavoritePokemonDTO objects.
    /// - Throws: Any errors that occur during the database fetch operation.
    func fetchPokemons() async throws -> [FavoritePokemonDTO] {
        return try modelContext.fetch(FetchDescriptor<FavoritePokemonDTO>())
    }

    /// Adds a Pokémon to the favorites list.
    ///
    /// Creates a new FavoritePokemonDTO instance with complete Pokémon data and inserts it into the database.
    /// Copies all fields from PokemonModel to ensure data independence from the main model.
    /// This prevents data loss if the original PokemonModel is modified or deleted.
    ///
    /// - Parameters:
    ///   - pokemonID: The unique identifier of the Pokémon to add to favorites.
    ///   - pokemonData: Complete PokemonModel containing all fields (name, image, types, stats, height, weight).
    /// - Throws: Any errors that occur during the insert or save operation.
    func addPokemonToFavorites(pokemonID: Int, pokemonData: PokemonModel?) async throws {
        let idToAdd = pokemonID
        let fetchDescriptor = FetchDescriptor<FavoritePokemonDTO>(
            predicate: #Predicate { $0.pokemonID == idToAdd }
        )

        let results = try modelContext.fetch(fetchDescriptor)

        if results.isEmpty {
            let favorite = FavoritePokemonDTO(
                pokemonID: pokemonID,
                name: pokemonData?.name ?? "",
                imageURL: pokemonData?.imageURL,
                height: pokemonData?.height,
                weight: pokemonData?.weight,
                types: pokemonData?.types ?? [],
                stats: pokemonData?.stats
            )
            modelContext.insert(favorite)
            try await saveContext()
        }
    }

    /// Removes a Pokémon from the favorites list.
    ///
    /// Finds the favorite by ID and deletes it from the database.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to remove from favorites.
    /// - Throws: Any errors that occur during the delete or save operation.
    func removePokemonFromFavorites(pokemonID: Int) async throws {
        let idToRemove = pokemonID
        let fetchDescriptor = FetchDescriptor<FavoritePokemonDTO>(
            predicate: #Predicate { $0.pokemonID == idToRemove }
        )

        let results = try modelContext.fetch(fetchDescriptor)

        for favorite in results {
            modelContext.delete(favorite)
        }

        try await saveContext()
    }

    /// Checks if a specific Pokémon is in the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: Any errors that occur during the database fetch operation.
    func isPokemonFavorite(pokemonID: Int) async throws -> Bool {
        let idToCheck = pokemonID
        let fetchDescriptor = FetchDescriptor<FavoritePokemonDTO>(
            predicate: #Predicate { $0.pokemonID == idToCheck }
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

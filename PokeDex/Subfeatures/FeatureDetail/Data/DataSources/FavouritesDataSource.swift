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
        func fetchPokemons() -> [PokemonModel] {
            do {
                return try modelContext.fetch(FetchDescriptor<PokemonModel>())
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Adds a Pokémon to the favorites list.
        /// - Parameter pokemon: The PokemonModel object to add to favorites.
        func addPokemonToFavorites(pokemon: PokemonModel) {
            modelContext.insert(pokemon)
            saveContext()
        }

        /// Removes a Pokémon from the favorites list.
        /// - Parameter pokemon: The PokemonModel object to remove from favorites.
        func removePokemonFromFavorites(pokemon: PokemonModel) {
            modelContext.delete(pokemon)
            saveContext()
        }

        /// Checks if a specific Pokémon is in the favorites list.
        /// - Parameter pokemon: The PokemonModel object to check.
        /// - Returns: A boolean indicating whether the Pokémon is a favorite.
        func isPokemonFavorite(pokemon: PokemonModel) -> Bool {
            let idPokemon = pokemon.id
            let fetchDescriptor = FetchDescriptor<PokemonModel>(predicate: #Predicate {
                $0.id == idPokemon}, sortBy: [.init(\.id, order: .forward)])

            do {
                let results = try modelContext.fetch(fetchDescriptor)
                return !results.isEmpty
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Saves the current state of the model context.
        private func saveContext() {
            do {
                try modelContext.save()
            } catch {
                fatalError("Failed to save context: \(error.localizedDescription)")
            }
        }
}

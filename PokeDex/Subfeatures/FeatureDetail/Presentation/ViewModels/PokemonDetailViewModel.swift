//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import Foundation
import SwiftData

@MainActor
class PokemonDetailViewModel: BaseViewModel, ObservableObject {
    var dto: PokemonDetailAssemblyDTO?
    var modelContext: ModelContext?

    init(dto: PokemonDetailAssemblyDTO?) {
        self.dto = dto
    }

    let getPokemonDetailUseCase = GetPokemonDetailUseCase(repository: DetailRepository())
    let getPokemonDetailSpecieUseCase = GetPokemonDetailSpecieUseCase(repository: DetailRepository())

    @Published var pokemonDetail: PokemonModel?
    @Published var pokemonDetailSpecie: PokemonSpecieModel?

    func onAppear(model: ModelContext) {
        self.modelContext = model
        self.loadDetail()
        self.loadSpecie()
        self.fetchData()
    }

    func loadDetail() {
        guard let idPokemon = dto?.idPokemon else {
            return // Mostrar error
        }

        Task {
            do {
                guard let pokemonDetailEntity: PokemonEntity = try await getPokemonDetailUseCase.execute(id: idPokemon) else {
                    return
                }

                self.pokemonDetail = PokemonModel(pokemon: pokemonDetailEntity)
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func loadSpecie() {
        guard let idPokemon = dto?.idPokemon else {
            return // Mostrar error
        }

        Task {
            do {
                guard let pokemonSpeciesEntity: PokemonSpeciesEntity = try await getPokemonDetailSpecieUseCase.execute(id: idPokemon) else {
                    return
                }

                self.pokemonDetailSpecie = PokemonSpecieModel(pokemon: pokemonSpeciesEntity)
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func likeButtonPressed(liked: Bool) {
        guard let pokemonToSave = self.pokemonDetail else {
                return
        }
        if liked {
            // Grabamos en BBDD
            self.modelContext?.insert(pokemonToSave)
        } else {
            // Grabamos en BBDD
            self.modelContext?.delete(pokemonToSave)
        }
        try? self.modelContext?.save()
    }

    func fetchData() {
                do {
                    let descriptor = FetchDescriptor<PokemonModel>(sortBy: [SortDescriptor(\.id)])
                    let pokemons = try modelContext?.fetch(descriptor)
                    if let pokemons = pokemons {
                        if !pokemons.isEmpty {
                            let pokem = pokemons[0]
                            print(pokem.name)
                            print(pokem.id)

                        }
                    }
                } catch {
                    print("Fetch failed")
                }
            }
}

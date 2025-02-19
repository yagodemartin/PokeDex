//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import Foundation

@MainActor
class PokemonDetailViewModel: BaseViewModel, ObservableObject {

    var dto: PokemonDetailAssemblyDTO?

    init(dto: PokemonDetailAssemblyDTO?) {
        self.dto = dto
    }

    let getPokemonDetailUseCase = GetPokemonDetailUseCase(repository: DetailRepository())
    let getPokemonDetailSpecieUseCase = GetPokemonDetailSpecieUseCase(repository: DetailRepository())

    @Published var pokemonDetail: PokemonModel?
    @Published var pokemonDetailSpecie: PokemonSpecieModel?

    override func onAppear() {
        self.loadDetail()
        self.loadSpecie()
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
}

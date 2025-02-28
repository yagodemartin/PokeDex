//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

public class PokemonExploreViewModel: BaseViewModel, ObservableObject {
    var dto: PokemonExploreAssemblyDTO?

    init(dto: PokemonExploreAssemblyDTO?) {
        self.dto = dto
    }

    private let getUseCase = GetPokemonListUseCase(pokeDexRepository: ExploreRepository.shared)
    let getPokemonDetailUseCase = GetPokemonDetailUseCase(repository: DetailRepository())

    var pokemonsLoaded: Bool = false
    var pokemonList = [PokemonModel]()
    @Published var pokemons = [PokemonModel]()
    public override func onAppear() {
        self.loadPokemonList()
    }

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

    @MainActor func errorViewAction(action: CustomErrorAction) {
            switch action {
            case .retry:
                self.loadPokemonList()

            case .exit:
                showWarningError = false
            }
        }
}

//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

class PokemonExploreViewModel: BaseViewModel, ObservableObject {

    var dto: PokemonExploreAssemblyDTO?

    init(dto: PokemonExploreAssemblyDTO?) {
        self.dto = dto
    }

    private let getPokemonListUseCase: GetPokemonListUseCase = GetPokemonListUseCase(pokeDexRepository: ExploreRepository.shared)
    let getPokemonDetailUseCase = GetPokemonDetailUseCase(repository: DetailRepository())
    @Published var pokemonList: [PokemonModel] = [PokemonModel]()
    @Published var pokemons: [PokemonModel] = [PokemonModel]()

    public override func onAppear() {
        self.loadPokemonList()
    }

    @MainActor
    func loadPokemonList() {
        self.state = .loading
        Task {
            do {
                let pokemonEntityList = try await getPokemonListUseCase.execute(limit: Constants.pokeApiPokemonListlimit)
                pokemonList += pokemonEntityList.compactMap({ pokemon in PokemonModel(pokemon: pokemon) })
                self.state = .okey
                await self.loadPokemonDetail()
                self.pokemons = self.pokemons.sorted(by: { $0.id < $1.id })

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

                    if (pokemon.id != 0) {
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

        } catch (let error) {
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

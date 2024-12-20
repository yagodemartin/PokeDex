//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation


class PokemonExploreViewModel: BaseViewModel,ObservableObject {
    
    var dto: PokemonExploreAssemblyDTO?
    
    init(dto: PokemonExploreAssemblyDTO?) {
        self.dto = dto
    }
    
    private let getPokemonListUseCase: GetPokemonListUseCase = GetPokemonListUseCase(pokeDexRepository: ExploreRepository.shared)
    
    @Published var pokemonList: [PokemonModel] = [PokemonModel]()

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
            } catch {
                self.state = .error
                showWarningError = true
            }
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

//
//  PokemonExploreViewModel.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

@MainActor
class PokemonExploreViewModel: ObservableObject {
    
    var dto: PokemonExploreAssemblyDTO?
    
    init(dto: PokemonExploreAssemblyDTO?) {
        self.dto = dto
    }
    
    private let getPokemonListUseCase: GetPokemonListUseCase = GetPokemonListUseCase(pokeDexRepository: ExploreRepository.shared)
    
    @Published var pokemonList: [PokemonModel] = [PokemonModel]()
    @Published var offset: Int = 20
    
    func onAppear() {
        self.loadPokemonList()
    }
    
    func loadPokemonList() {
        Task {
            do {
                let pokemonEntityList = try await getPokemonListUseCase.execute(limit: Constants.pokeApiPokemonListlimit, offset: offset)
                pokemonList += pokemonEntityList.compactMap({ pokemon in PokemonModel(pokemon: pokemon) })
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    

    
}

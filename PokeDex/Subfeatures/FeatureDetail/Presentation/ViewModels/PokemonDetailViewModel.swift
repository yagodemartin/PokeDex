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
    
    @Published var pokemonDetail: PokemonDetailModel?
    
    override func onAppear() {
        self.loadDetail()
    }
    
    func loadDetail() {
        
        guard let idPokemon = dto?.idPokemon else {
            return // Mostrar error
        }
        
        Task {
            do {
                guard let pokemonDetailEntity: PokemonDetailEntity = try await getPokemonDetailUseCase.execute(id: idPokemon) else {
                    return
                }
                
                self.pokemonDetail = PokemonDetailModel(pokemonDetail: pokemonDetailEntity)
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

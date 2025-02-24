//
//  DetailRepositoryProtocol.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

protocol DetailRepositoryProtocol {
    func fetchPokemonDetail(id: Int) async throws -> PokemonEntity?
    func fetchPokemonDetailSpecie(id: Int) async throws -> PokemonSpeciesEntity?
}

//
//  PokemonModel 2.swift
//  PokeDex
//
//  Created by yamartin on 18/2/25.
//

import Foundation

struct PokemonSpecieModel {
    var flavorText: String

    init?(pokemon: PokemonSpeciesEntity) {
        let langStr = Locale.current.language.languageCode?.identifier
        self.flavorText =
            pokemon.flavorTextEntries.first(where: { $0.language.name == langStr })?.flavorText
                ?? pokemon.flavorTextEntries.first?.flavorText ?? ""
        self.flavorText = self.flavorText.replacingOccurrences(of: "\n", with: " ")
    }
}

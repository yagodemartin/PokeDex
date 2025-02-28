//
//  Pokemon.swift
//  PokeDex
//
//  Created by yamartin on 18/2/25.
//
import SwiftData

@Model
class PokemonStats {
    var hpoint: Int
    var attack: Int
    var defense: Int
    var specialAttack: Int
    var specialDefense: Int
    var speed: Int

    init(from stats: [Stat]) {
        var tempStats: [String: Int] = [:]
        for stat in stats {
            tempStats[stat.stat.name] = stat.baseStat
        }

        self.hpoint = tempStats["hp"] ?? 0
        self.attack = tempStats["attack"] ?? 0
        self.defense = tempStats["defense"] ?? 0
        self.specialAttack = tempStats["special-attack"] ?? 0
        self.specialDefense = tempStats["special-defense"] ?? 0
        self.speed = tempStats["speed"] ?? 0
    }
}

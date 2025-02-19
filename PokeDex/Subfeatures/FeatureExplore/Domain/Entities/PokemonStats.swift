
//
//  Pokemon.swift
//  PokeDex
//
//  Created by yamartin on 18/2/25.
//


struct PokemonStats {
    let hp: Int
    let attack: Int
    let defense: Int
    let specialAttack: Int
    let specialDefense: Int
    let speed: Int
    
    init(from stats: [Stat]) {
        var tempStats: [String: Int] = [:]
        
        for stat in stats {
            tempStats[stat.stat.name] = stat.baseStat
        }
        
        self.hp = tempStats["hp"] ?? 0
        self.attack = tempStats["attack"] ?? 0
        self.defense = tempStats["defense"] ?? 0
        self.specialAttack = tempStats["special-attack"] ?? 0
        self.specialDefense = tempStats["special-defense"] ?? 0
        self.speed = tempStats["speed"] ?? 0
    }
}

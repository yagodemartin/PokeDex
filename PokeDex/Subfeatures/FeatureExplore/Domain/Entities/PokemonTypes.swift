//
//  PokemonTypes.swift
//  PokeDex
//
//  Created by yamartin on 17/2/25.
//


//
//  PokemonTypes.swift
//  NTTData-Networking
//
//  Created by Pedro Maria Moreno Gonzalez on 22/11/22.
//

import Foundation
import SwiftUI

enum PokemonTypes: String {
    case normal
    case fire
    case fighting
    case water
    case flying
    case grass
    case poison
    case electric
    case ground
    case psychic
    case rock
    case ice
    case bug
    case dragon
    case ghost
    case dark
    case steel
    case fairy
    case unknown = "???"
    
    func getColor() -> Color {
        switch self {
        case .normal:
            return .Types.normal
            
        case .fire:
            return .Types.fire

        case .fighting:
            return .Types.fighting

        case .water:
            return .Types.water

        case .flying:
            return .Types.flying

        case .grass:
            return .Types.grass

        case .poison:
            return .Types.poison

        case .electric:
            return .Types.electric

        case .ground:
            return .Types.ground

        case .psychic:
            return .Types.psychic

        case .rock:
            return .Types.rock

        case .ice:
            return .Types.ice

        case .bug:
            return .Types.bug

        case .dragon:
            return .Types.dragon

        case .ghost:
            return .Types.ghost

        case .dark:
            return .Types.dark

        case .steel:
            return .Types.steel

        case .fairy:
            return .Types.fairy

        case .unknown:
            return .Types.unkwnown

        }
    }
}

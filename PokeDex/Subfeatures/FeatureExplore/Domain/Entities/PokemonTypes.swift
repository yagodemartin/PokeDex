//
//  PokemonTypes.swift
//  PokeDex
//
//  Created by yamartin on 17/

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

    func getImage() -> Image {
        switch self {
        case .normal:
            return Image("normal")

        case .fire:
            return Image("fire")

        case .fighting:
            return Image("fighting")

        case .water:
            return Image("water")

        case .flying:
            return Image("flying")

        case .grass:
            return Image("grass")

        case .poison:
            return Image("poison")

        case .electric:
            return Image("electric")

        case .ground:
            return Image("ground")

        case .psychic:
            return Image("psychic")

        case .rock:
            return Image("rock")

        case .ice:
            return Image("ice")

        case .bug:
            return Image("bug")

        case .dragon:
            return Image("dragon")

        case .ghost:
            return Image("ghost")

        case .dark:
            return Image("dark")

        case .steel:
            return Image("steel")

        case .fairy:
            return Image("fairy")

        case .unknown:
            return Image("fire")
        }
    }
}

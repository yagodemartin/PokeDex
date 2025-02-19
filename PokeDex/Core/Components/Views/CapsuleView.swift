//
//  CapsuleView.swift
//  PokeDex
//
//  Created by yamartin on 18/2/25.
//

import SwiftUI

struct CapsuleView: View {

    var type: PokemonTypes

    var body: some View {
        HStack {
            type.getImage().resizable().frame(width: 20 , height: 20)
            Text(type.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.white)
        }
        .frame(width: 120 , height: 30)
                        .background(type.getColor())
                        .cornerRadius(5)
                        .shadow(color: type.getColor().adjust(brightness: -0.2), radius: 5, x: 0, y: 5)

    }
}

#Preview {
    CapsuleView(type: .fighting)
}

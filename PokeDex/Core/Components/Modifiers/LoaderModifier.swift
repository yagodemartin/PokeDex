//
//  LoaderModifier.swift
//  PokeDex
//
//  Created by yamartin on 12/12/24.
//

import Foundation

import SwiftUI

struct LoaderModifier: ViewModifier {
    var state: ViewModelState
    var loader: AnyView
    
    init(state: ViewModelState,
         loader: AnyView) {
        self.state = state
        self.loader = loader
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center), content: {
            content
            if state == ViewModelState.loading {
                loader
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        })
    }
}

//
//  LoaderView.swift
//  PokeDex
//
//  Created by yamartin on 12/12/24.
//

import Foundation
import SwiftUI
import Lottie

struct LoaderView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                VStack(alignment: .center, spacing: 0.0) {
                    Spacer()
                    LottieView(animation: .named("lottieAnimation"))
                        .playing()
                        .resizable()
                        .frame(width: 200, height: 200)
                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct LoaderView_Previews: PreviewProvider {
    static var previews: some View {
        LoaderView()
    }
}

extension View {
    func loaderBase(state: ViewModelState) -> some View {
        self.modifier(LoaderModifier(state: state, loader: AnyView(LoaderView())))
    }
}

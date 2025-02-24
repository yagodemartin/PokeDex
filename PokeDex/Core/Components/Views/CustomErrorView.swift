//
//  CustomErrorView.swift
//  PokeDex
//
//  Created by yamartin on 20/12/24.
//

import SwiftUI

enum CustomErrorAction {
    case retry
    case exit
}

struct CustomErrorView: View {
    var actionPerformed: ((CustomErrorAction) -> Void)?

    var body: some View {
        VStack {
            Text("Se ha producido un error")
            Button(action: {
                               actionPerformed?(.retry)
                              }, label: {
                                      Text("Reintentar")
                       })
                       Button(action: {
                               actionPerformed?(.exit)
                              }, label: {
                                      Text("Salir")
                       })
        }
        .ignoresSafeArea()
                .navigationBarHidden(true)
    }
}

#Preview {
    CustomErrorView()
}

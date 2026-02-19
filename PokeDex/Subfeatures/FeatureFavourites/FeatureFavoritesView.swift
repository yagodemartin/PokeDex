import SwiftUI

struct FeatureFavoritesView: View {
    @StateObject private var viewModel: FeatureFavoritesViewModel

    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10),
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    init(_ viewModel: FeatureFavoritesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.state == .okey {
                list
            } else if viewModel.state == .error {
                HStack {
                    Text("Ha habido un error")
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(isPresented: self.$viewModel.showWarningError) {
            CustomErrorView(actionPerformed: viewModel.errorViewAction)
        }
        .loaderBase(state: self.viewModel.state)
    }

    var list: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                ForEach(viewModel.favorites, id: \.id) { favorite in
                    NavigationLink(destination: PokemonDetailAssembly.view(dto: PokemonDetailAssemblyDTO(idPokemon: favorite.pokemonID))) {
                        PokemonCellView(name: favorite.name,
                                        number: favorite.pokemonID,
                                        imageURL: favorite.imageURL,
                                        background: PokemonTypes(rawValue: favorite.typeColorName)?.getColor() ?? .gray)
                    }
                }
            }
        }
        .padding(.horizontal)
        .background(Color.defaultBackground)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

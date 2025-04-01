import SwiftUI

struct FeatureFavoritesView: View {
    @EnvironmentObject var tabBarState: TabBarState
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
            } // VSTACK

        .onAppear {
            tabBarState.isTabBarVisible = true
            viewModel.onAppear()
        }
        .sheet(isPresented: self.$viewModel.showWarningError) {
            CustomErrorView(actionPerformed: viewModel.errorViewAction)
        }
        .loaderBase(state: self.viewModel.state)
        .toolbar(.hidden, for: .tabBar)
    }

    var list: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                ForEach(viewModel.favorites) { pokemon in
                    NavigationLink(destination: PokemonDetailAssembly.view(dto: PokemonDetailAssemblyDTO(idPokemon: pokemon.id))) {
                        PokemonCellView(name: pokemon.name,
                                        number: pokemon.id,
                                        imageURL: pokemon.imageURL,
                                        background: pokemon.types.first?.getColor() ?? .black)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                                    tabBarState.isTabBarVisible = false // Hide tab bar when navigating
                                })
                }
            }
        }
        .padding(.horizontal)
        .background(Color.defaultBackground)
        .ignoresSafeArea(.all, edges: .bottom)

    }
}

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
        }
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
                ForEach(viewModel.favorites) { favorite in
                    NavigationLink(destination: PokemonDetailAssembly.view(dto: PokemonDetailAssemblyDTO(idPokemon: favorite.pokemonID))) {
                        PokemonCellView(name: favorite.name,
                                        number: favorite.pokemonID,
                                        imageURL: favorite.imageURL,
                                        background: Color.gray)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        tabBarState.isTabBarVisible = false
                    })
                }
            }
        }
        .padding(.horizontal)
        .background(Color.defaultBackground)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

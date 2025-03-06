//
//  FloatingTabBar.swift
//  PokeDex
//
//  Created by yamartin on 24/2/25.
//

import SwiftUI

struct FloatingTabBar: View {
    enum Tabs {
        case pokedex
        case favorites
        case search
        case settings
    }
    @EnvironmentObject var tabBarState: TabBarState
    @State private var selectedTab: Tabs = .pokedex
    @State private var isTabBarVisible: Bool = true // Estado para controlar la visibilidad

    @State private var likeAnimationViews: [LikeAnimationView] = []
    private let animationDuration = 1.0

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab, content: {
                Group {
                    NavigationStack {
                        PokemonExploreAssembly.view(dto: PokemonExploreAssemblyDTO())
                    }                            .tag(Tabs.pokedex)

                    NavigationStack {
                        FeatureFavoritesAssembly.view(dto: FeatureFavoritesDTO())
                    }                            .tag(Tabs.favorites)

                    NavigationStack {
                        Color(.orange).ignoresSafeArea()
                    }                            .tag(Tabs.search)

                    NavigationStack {
                        Color(.brown).ignoresSafeArea()
                    }                            .tag(Tabs.settings)
                }
                .toolbar(.hidden, for: .tabBar)
            })
            .onAppear {
                tabBarState.isTabBarVisible = true
                // Ensure tab bar is visible when main view appears
            }
            VStack {
                Spacer()
                ForEach(likeAnimationViews) { likeAnimationView in
                    likeAnimationView.onAppear {
                        // when the animation ends, remove a LikeAnimationView from the array
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                            likeAnimationViews.removeFirst()
                        }
                    }
                }
                tabBar
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: tabBarState.isLiked) {
            if tabBarState.isLiked {
                likeAnimationViews.append(LikeAnimationView(duration: animationDuration))
                tabBarState.isLiked = false
            }
        }
    }

    private var tabBar: some View {
        VStack {
            if tabBarState.isTabBarVisible {
                HStack(content: {
                    Spacer()

                    Button(action: {
                        withAnimation {
                            selectedTab = .pokedex
                        }
                    }, label: {
                        VStack(alignment: .center, content: {
                            Image("pikachuTab")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22)
                            if selectedTab == .pokedex {
                                Text("Pokedex")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                            }
                        })
                    })
                    .foregroundStyle(selectedTab == .pokedex ? .white : .black)
                    Spacer()

                    Button(action: {
                        withAnimation {
                            selectedTab = .favorites
                        }
                    }, label: {
                        VStack(alignment: .center, content: {
                            Image(systemName: "sparkle.magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22)
                            if selectedTab == .favorites {
                                Text("Collection")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                            }
                        })
                    })
                    .foregroundStyle(selectedTab == .favorites ? .white : .black)
                    Spacer()

                    Button(action: {
                        withAnimation {
                            selectedTab = .search
                        }
                    }, label: {
                        VStack(alignment: .center, content: {
                            Image(systemName: "bell.badge.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22)
                            if selectedTab == .search {
                                Text("Search")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                            }
                        })
                    })
                    .foregroundStyle(selectedTab == .search ? .white : .black)
                    Spacer()

                    Button(action: {
                        withAnimation {
                            selectedTab = .settings
                        }
                    }, label: {
                        VStack(alignment: .center, content: {
                            Image(systemName: "gear.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22)
                            if selectedTab == .settings {
                                Text("Settings")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                            }
                        })
                    })
                    .foregroundStyle(selectedTab == .settings ? .white : .black)
                    Spacer()
                })
                .padding()
                .frame(height: 72)
                .background {
                    RoundedRectangle(cornerRadius: 36)
                        .fill(Color.headerBackground.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.5), radius: 8, y: 2)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FloatingTabBar_Previews: PreviewProvider {
    static var previews: some View {
        FloatingTabBar()
    }
}

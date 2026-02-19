//
//  FloatingTabBar.swift
//  PokeDex
//
//  Created by yamartin on 24/2/25.
//

import SwiftUI

/// Native TabBar with Liquid Glass effect (iOS 18+)
/// Handles tab switching and like/dislike animations that float above the native tab bar.
struct FloatingTabBar: View {
    @EnvironmentObject var tabBarState: TabBarState
    @State private var likeAnimationViews: [LikeAnimationView] = []
    private let animationDuration = 1.0

    var body: some View {
        ZStack {
            // Native TabView with iOS 18+ Tab API for Liquid Glass
            if #available(iOS 18, *) {
                TabView {
                    Tab("Pokédex", image: "pikachuTab") {
                        NavigationStack {
                            PokemonExploreAssembly.view(dto: PokemonExploreAssemblyDTO())
                        }
                    }

                    Tab("Collection", systemImage: "sparkle.magnifyingglass") {
                        NavigationStack {
                            FeatureFavoritesAssembly.view(dto: FeatureFavoritesDTO())
                        }
                    }

                    Tab("Search", systemImage: "bell.badge.fill") {
                        NavigationStack {
                            Color(.orange).ignoresSafeArea()
                        }
                    }

                    Tab("Settings", systemImage: "gear.circle") {
                        NavigationStack {
                            Color(.brown).ignoresSafeArea()
                        }
                    }
                }
                // iOS 26+: Add minimize behavior on scroll down
                .modifier(MinimizeBehaviorModifier())
            } else {
                // Fallback for iOS 16-17 using older TabView API
                TabView {
                    NavigationStack {
                        PokemonExploreAssembly.view(dto: PokemonExploreAssemblyDTO())
                    }
                    .tabItem {
                        Image("pikachuTab")
                        Text("Pokédex")
                    }

                    NavigationStack {
                        FeatureFavoritesAssembly.view(dto: FeatureFavoritesDTO())
                    }
                    .tabItem {
                        Image(systemName: "sparkle.magnifyingglass")
                        Text("Collection")
                    }

                    NavigationStack {
                        Color(.orange).ignoresSafeArea()
                    }
                    .tabItem {
                        Image(systemName: "bell.badge.fill")
                        Text("Search")
                    }

                    NavigationStack {
                        Color(.brown).ignoresSafeArea()
                    }
                    .tabItem {
                        Image(systemName: "gear.circle")
                        Text("Settings")
                    }
                }
            }

            // Like/Dislike animation overlay (floats above native tab bar)
            VStack {
                Spacer()
                ForEach(likeAnimationViews) { likeAnimationView in
                    likeAnimationView.onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                            likeAnimationViews.removeFirst()
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: tabBarState.isLiked) {
            if tabBarState.isLiked {
                likeAnimationViews.append(LikeAnimationView(duration: animationDuration, type: .like))
                tabBarState.isLiked = false
            }
        }
        .onChange(of: tabBarState.isDisliked) {
            if tabBarState.isDisliked {
                likeAnimationViews.append(LikeAnimationView(duration: animationDuration, type: .dislike))
                tabBarState.isDisliked = false
            }
        }
    }
}

// Modifier to conditionally apply iOS 26+ minimize behavior
private struct MinimizeBehaviorModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

struct FloatingTabBar_Previews: PreviewProvider {
    static var previews: some View {
        FloatingTabBar()
    }
}

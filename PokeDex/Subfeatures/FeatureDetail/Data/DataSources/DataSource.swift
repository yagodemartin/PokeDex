//
//  DataSource.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//
import SwiftUI
import SwiftData

final class FavouritesDataSource {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    @MainActor
    static let shared = FavouritesDataSource()

    @MainActor
    private init() {
        self.modelContainer = try! ModelContainer(for: PokemonModel.self) // swiftlint:disable:this force_try
        self.modelContext = modelContainer.mainContext
    }
}

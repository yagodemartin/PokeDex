//
//  PokemonTCGRemoteDataSource.swift
//  PokeDex
//
//  Created by yamartin on 19/3/25.
//
import Foundation

class PokemonTCGRemoteDataSource: PokemonTCGRepository {
    func fetchCards(named name: String, completion: @escaping ([PokemonTCGCardServiceModel]?) -> Void) {
        let urlString = "https://api.pokemontcg.io/v2/cards?q=name:\(name)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let response = try JSONDecoder().decode([String: [PokemonTCGCardServiceModel]].self, from: data)
                completion(response["data"])
            } catch {
                print("Error al decodificar JSON: \(error)")
                completion(nil)
            }
        }.resume()
    }
}

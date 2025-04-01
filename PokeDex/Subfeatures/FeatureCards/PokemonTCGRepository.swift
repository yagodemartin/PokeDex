import Foundation

protocol PokemonTCGRepository {
    func fetchCards(named name: String, completion: @escaping ([PokemonTCGCardServiceModel]?) -> Void)
}

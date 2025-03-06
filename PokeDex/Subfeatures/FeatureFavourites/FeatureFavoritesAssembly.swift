import SwiftUI

class FeatureFavoritesAssembly {
    @MainActor
    static func view(dto: FeatureFavoritesDTO) -> some View {
        let viewModel = FeatureFavoritesViewModel(dto: dto)
        return FeatureFavoritesView(viewModel)
    }
}

struct FeatureFavoritesDTO {
}

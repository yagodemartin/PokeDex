# ✨ Features - Guía de Funcionalidades

Documentación detallada de cada feature del proyecto PokéDex con ejemplos de uso.

## 📋 Tabla de Contenidos

1. [FeatureExplore](#featureexplore---exploración-de-pokémon)
2. [FeatureDetail](#featuredetail---detalle-de-pokémon)
3. [FeatureFavourites](#featurefavourites---favoritos)
4. [FeatureCards](#featurecards---cartas-tcg)
5. [TabBar](#tabbar---navegación)
6. [Core Components](#core-components---componentes-reutilizables)

---

## 🔍 FeatureExplore - Exploración de Pokémon

**Ubicación**: `PokeDex/Subfeatures/FeatureExplore/`

**Propósito**: Listar y explorar la colección de Pokémon desde la API.

### 📊 Estados de la Pantalla

```
┌─────────────────────────────┐
│  LOADING (Primera carga)    │
│  ┌─────────────────────────┐│
│  │   Loader Animation      ││
│  │  "Cargando Pokémon..."  ││
│  └─────────────────────────┘│
└─────────────────────────────┘
           ↓ (después de 3-5s)
┌─────────────────────────────┐
│  SUCCESS (Lista cargada)    │
│  ┌─────────────────────────┐│
│  │ [Pokémon #1]            ││
│  │ [Pokémon #2]            ││
│  │ [Pokémon #3]            ││
│  │ ...                     ││
│  └─────────────────────────┘│
└─────────────────────────────┘
           ↓ (si error en red)
┌─────────────────────────────┐
│  ERROR (Fallo de red)       │
│  ┌─────────────────────────┐│
│  │ Error Icon              ││
│  │ "Fallo de conexión"     ││
│  │ [Reintentar] [Salir]    ││
│  └─────────────────────────┘│
└─────────────────────────────┘
```

### 🏗️ Arquitectura Interna

```
PokemonExploreView (UI)
        ↓
PokemonExploreViewModel
├─ loadPokemonList()
├─ loadPokemonDetail()
└─ errorViewAction()
        ↓
GetPokemonListUseCase
        ↓
ExploreRepository (implementación)
        ↓
ExploreDataSource (HTTP)
        ↓
PokeAPI (Red externa)
```

### 🔄 Flujo de Carga

```swift
// 1. Vista aparece
PokemonExploreView.onAppear()
    ↓
// 2. ViewModel inicia carga
viewModel.loadPokemonList()
    ↓ @MainActor
// 3. UseCase obtiene lista básica
getUseCase.execute(limit: 155)
    ↓
// 4. DataSource llama API
GET /pokemon?limit=155
    ↓
// 5. Repository mapea DTO → Entity
PokemonListResponseModel → [PokemonEntity]
    ↓
// 6. ViewModel obtiene detalles en paralelo
withThrowingTaskGroup (155 requests en paralelo)
    ↓
// 7. Actualiza @Published
@Published pokemons = [...]
    ↓
// 8. UI se renderiza automáticamente
View re-renders con nueva data
```

### 💡 Optimización: Carga Paralela

**Problema**: Cargar 155 Pokémon secuencialmente toma ~8 minutos

**Solución**: TaskGroup para paralelismo

```swift
@MainActor
private func loadPokemonDetail() async {
    do {
        try await withThrowingTaskGroup(
            of: (PokemonEntity?).self,
            body: { group in
                // Agregar 155 tasks en paralelo
                pokemonList.forEach { pokemon in
                    if pokemon.id != 0 {
                        group.addTask {
                            return try await self.getPokemonDetailUseCase
                                .execute(id: pokemon.id)
                        }
                    }
                }
                // Recopilar resultados conforme llegan
                for try await pokemon in group {
                    if let pokem = pokemon {
                        pokemons.append(PokemonModel(pokemon: pokem))
                    }
                }
            }
        )
    } catch { }
}
```

**Resultado**: Reduce tiempo de ~8 minutos a ~15-30 segundos

### 🎨 Componentes Visuales

#### PokemonCellView
Tarjeta individual de Pokémon:

```
┌──────────────────────────┐
│  ┌────────────────────┐  │
│  │                    │  │
│  │   [Pokémon Img]    │  │
│  │                    │  │
│  └────────────────────┘  │
│  Charizard      #006     │
│  🔥                      │
└──────────────────────────┘
```

**Props**:
- `name`: String (nombre del Pokémon)
- `number`: Int (ID/número Pokédex)
- `imageURL`: URL (imagen oficial)
- `background`: Color (color del tipo)

#### LazyVGrid
Grid adaptable de 2 columnas:

```swift
let columns = [
    GridItem(.adaptive(minimum: 150), spacing: 10),
    GridItem(.adaptive(minimum: 150), spacing: 10)
]

LazyVGrid(columns: columns) {
    ForEach(pokemons) { pokemon in
        PokemonCellView(...)
    }
}
```

### 🔌 APIs Utilizadas

```
GET https://pokeapi.co/api/v2/pokemon?limit=155
├─ Response:
│  {
│    "count": 1025,
│    "next": "...",
│    "previous": null,
│    "results": [
│      {"name": "bulbasaur", "url": "..."},
│      {"name": "ivysaur", "url": "..."},
│      ...
│    ]
│  }
└─ Mapeo a: PokemonEntity[]
```

### 📤 Navegación

Al tappear un Pokémon:

```swift
NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
    PokemonCellView(...)
}
```

Pasa a **FeatureDetail**

---

## 📖 FeatureDetail - Detalle de Pokémon

**Ubicación**: `PokeDex/Subfeatures/FeatureDetail/`

**Propósito**: Mostrar información completa y estadísticas de un Pokémon.

### 📊 Pantalla de Detalle

```
┌────────────────────────────────┐
│ Header con imagen              │
├────────────────────────────────┤
│ Nombre y tipo                  │
├────────────────────────────────┤
│ Botón ❤️ Agregar a Favoritos   │
├────────────────────────────────┤
│ ESTADÍSTICAS                   │
│ ├─ HP:      [████░░░]  60      │
│ ├─ ATK:     [███████░]  62     │
│ ├─ DEF:     [████░░░░]  63     │
│ ├─ SP.ATK:  [███████░]  70     │
│ ├─ SP.DEF:  [███░░░░░]  65     │
│ └─ SPD:     [█████░░░]  80     │
├────────────────────────────────┤
│ CARTAS TCG                     │
│ [Mostrar cartas relacionadas]  │
└────────────────────────────────┘
```

### 🏗️ Arquitectura

```
PokemonDetailView
        ↓
PokemonDetailViewModel
├─ onAppear() → cargar detalles
├─ toggleFavorite() → agregar/quitar
└─ loadTCGCards() → cartas
        ↓
GetPokemonDetailUseCase
GetPokemonDetailSpecieUseCase
AddPokemonToFavoritesUseCase
        ↓
DetailRepository
FavoritesRepository
        ↓
DetailDataSource (HTTP)
FavouritesDataSource (SwiftData)
```

### 📊 Estadísticas Gráficas

Componente: `PokemonStatsChartView`

```swift
struct PokemonStats {
    let hp: Int
    let attack: Int
    let defense: Int
    let spAttack: Int
    let spDefense: Int
    let speed: Int
}

// Visualización:
// HP:     ████████░░░░░░░░░░░ 60/255
// ATK:    ███████░░░░░░░░░░░░░ 62/255
// DEF:    ████░░░░░░░░░░░░░░░░ 63/255
```

### ❤️ Sistema de Favoritos

#### Agregar a Favoritos

```swift
// ViewModel
@Published var isFavorite: Bool = false

func toggleFavorite() {
    if isFavorite {
        removeFavoriteUseCase.execute(pokemonId: id)
    } else {
        addFavoriteUseCase.execute(pokemonId: id)
    }
    isFavorite.toggle()
}
```

#### Verificar si es Favorito

```swift
// ViewModel onAppear
@MainActor
override func onAppear() {
    Task {
        let favorite = try await isPokemonFavoriteUseCase
            .execute(pokemonId: id)
        isFavorite = favorite
    }
}
```

#### Persistencia

Usa SwiftData para guardar localmente:

```swift
@Model
final class PokemonModel {
    var id: Int
    var name: String
    var isFavorite: Bool = false

    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
}
```

### 🎴 Integración TCG

Botón "Ver Cartas":

```swift
NavigationLink(destination: PokemonTCGCardsView(pokemonName: name)) {
    Label("Ver Cartas TCG", systemImage: "square.stack")
}
```

### 🔌 APIs Utilizadas

```
GET /pokemon/{id}
├─ Stats, Types, Abilities
└─ Mapeo a: PokemonEntity

GET /pokemon-species/{id}
├─ Description, Flavor text
└─ Mapeo a: PokemonSpeciesEntity

GET /pokemon/{id}/encounters
└─ Ubicación en juegos
```

---

## ❤️ FeatureFavourites - Favoritos

**Ubicación**: `PokeDex/Subfeatures/FeatureFavourites/`

**Propósito**: Mostrar Pokémon guardados como favoritos.

### 📊 Pantalla de Favoritos

```
┌────────────────────────────┐
│  MIS FAVORITOS             │
├────────────────────────────┤
│  [Pokémon #1]  [Pokémon #2]│
│                            │
│  [Pokémon #3]  [Pokémon #4]│
│  ...                       │
│                            │
│  (vacío si no hay)         │
│  "Aún no tienes favoritos" │
└────────────────────────────┘
```

### 🏗️ Arquitectura

```
FeatureFavoritesView
        ↓
FeatureFavoritesViewModel
├─ loadFavorites()
├─ removeFavorite(id)
└─ state management
        ↓
FetchAllFavoritePokemonsUseCase
        ↓
FavoritesRepository
        ↓
FavouritesDataSource (SwiftData)
        ↓
Local Database
```

### 💾 Persistencia Local

Usa SwiftData (no requiere setup adicional):

```swift
// En PokeDexApp.swift
let schema = Schema([PokemonModel.self])
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false
)
let modelContainer = ModelContainer(
    for: schema,
    configurations: [modelConfiguration]
)
```

### 📤 Usar Favoritos en otra Feature

```swift
// En cualquier ViewModel
let fetchFavoritesUseCase = FetchAllFavoritePokemonsUseCase(...)

Task {
    let favorites = try await fetchFavoritesUseCase.execute()
    // favorites: [PokemonEntity]
}
```

### 🗑️ Eliminar Favoritos

```swift
// ViewModel
func removeFavorite(pokemonId: Int) {
    Task {
        try await removeFavoriteUseCase.execute(pokemonId: pokemonId)
        loadFavorites() // Recargar lista
    }
}
```

### 🔄 Sincronización

Los favoritos se sincronizan automáticamente:
- Al agregar en DetailView → aparece en FavoritesView
- Al eliminar en FavoritesView → se actualiza DetailView
- Persistencia automática con SwiftData

---

## 🎴 FeatureCards - Cartas TCG

**Ubicación**: `PokeDex/Subfeatures/FeatureCards/`

**Propósito**: Mostrar cartas Pokémon Trading Card Game.

### 📊 Pantalla de Cartas

```
┌────────────────────────────┐
│ CARTAS CHARIZARD           │
├────────────────────────────┤
│ ┌──────────┐  ┌──────────┐ │
│ │  [Img1]  │  │  [Img2]  │ │
│ │ Charizard│  │ Charizard│ │
│ │ Base Set │  │ Classic  │ │
│ └──────────┘  └──────────┘ │
│ ┌──────────┐  ┌──────────┐ │
│ │  [Img3]  │  │  [Img4]  │ │
│ │ Charizard│  │ Charizard│ │
│ │ Shadow   │  │ Promo    │ │
│ └──────────┘  └──────────┘ │
└────────────────────────────┘
```

### 🏗️ Arquitectura

```
PokemonTCGCardsView
        ↓
PokemonTCGViewModel
└─ loadCards(named: String)
        ↓
FetchPokemonTCGCardsUseCase
        ↓
PokemonTCGRepository
        ↓
PokemonTCGRemoteDataSource
        ↓
PokeTCG API
```

### 🔌 API TCG (PokéTCG)

```
GET https://api.pokemontcg.io/v2/cards?q=name:Charizard
├─ Response:
│  {
│    "data": [
│      {
│        "id": "...",
│        "name": "Charizard",
│        "images": {
│          "small": "https://...",
│          "large": "https://..."
│        },
│        "set": { "name": "Base Set" }
│      },
│      ...
│    ]
│  }
└─ Mapeo a: PokemonTCGCardDomainModel
```

### 💾 Modelos

```swift
// Respuesta de API (DTO)
struct PokemonTCGCardServiceModel: Codable {
    let id: String
    let name: String
    let images: TCGImages
    let set: TCGSet
}

// Dominio
struct PokemonTCGCardDomainModel {
    let id: String
    let name: String
    let imageURL: URL
    let setName: String
}

// Presentación
struct PokemonTCGCardModelView: Identifiable {
    let id: String
    let name: String
    let imageURL: URL
    let setName: String
}
```

### 🖼️ Visualización

Usa `AsyncImage` para cargar desde URL:

```swift
AsyncImage(url: card.imageURL) { image in
    image.resizable()
        .scaledToFit()
} placeholder: {
    ProgressView()
}
.frame(height: 200)
```

### 🔍 Búsqueda

Parámetro dinámico:

```swift
// En ViewModel
func loadCards(named pokemonName: String) {
    // GET /cards?q=name:Charizard
    remoteDataSource.searchCards(named: pokemonName)
}
```

---

## 🧭 TabBar - Navegación

**Ubicación**: `PokeDex/Subfeatures/Tabview/`

### 📊 Estructura de Navegación

```
FloatingTabBar
├── Tab 1: Explore (Home)
│   └─ PokemonExploreView
│
├── Tab 2: Details (Detail)
│   └─ PokemonDetailView
│
└── Tab 3: Favorites
    └─ FeatureFavoritesView
```

### 🎨 FloatingTabBar

Tab bar flotante personalizado (no usa UITabBarController):

```swift
struct FloatingTabBar: View {
    @EnvironmentObject var tabBarState: TabBarState
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Contenido de tabs
            TabView(selection: $selectedTab) {
                PokemonExploreView(...)
                    .tag(0)
                PokemonDetailView(...)
                    .tag(1)
                FeatureFavoritesView(...)
                    .tag(2)
            }

            // Tab bar flotante en fondo
            VStack {
                Spacer()
                HStack {
                    TabBarButton(icon: "magnifyingglass", tag: 0)
                    Spacer()
                    TabBarButton(icon: "info.circle", tag: 1)
                    Spacer()
                    TabBarButton(icon: "heart.fill", tag: 2)
                }
                .padding()
            }
        }
    }
}
```

### 🎯 TabBarState

Gestiona visibilidad y estado:

```swift
class TabBarState: ObservableObject {
    @Published var isTabBarVisible = true
    @Published var selectedTab = 0
}
```

### 🎨 Iconos por Tab

| Tab | Ícono | Descripción |
|-----|-------|------------|
| 1 | 🔍 | Exploración |
| 2 | ℹ️ | Detalles |
| 3 | ❤️ | Favoritos |

---

## 🔧 Core Components - Componentes Reutilizables

**Ubicación**: `PokeDex/Core/Components/`

### LoaderView

Animación de carga:

```swift
LoaderView()
    .frame(height: 100)
```

### CustomErrorView

Ventana de error con acciones:

```swift
CustomErrorView { action in
    switch action {
    case .retry:
        viewModel.loadPokemonList()
    case .exit:
        dismiss()
    }
}
```

### PokemonStatsChartView

Gráfico de estadísticas:

```swift
PokemonStatsChartView(stats: pokemon.stats)
```

### CardView

Contenedor con estilos:

```swift
CardView {
    VStack {
        Text("Contenido")
    }
}
.padding()
```

### CapsuleView

Etiqueta de tipo:

```swift
CapsuleView(
    text: pokemon.types.first?.name ?? "Unknown",
    backgroundColor: pokemon.types.first?.getColor() ?? .gray
)
```

### LikeAnimationView

Animación de favorito:

```swift
LikeAnimationView(isFavorite: $isFavorite)
    .onTapGesture {
        isFavorite.toggle()
    }
```

---

## 🎨 Colores y Temas

**Ubicación**: `Resources/Colors.xcassets/`

### Colores por Tipo de Pokémon

```swift
enum PokemonTypes: String {
    case fire = "fire"
    case water = "water"
    case grass = "grass"
    case electric = "electric"
    // ... más tipos

    func getColor() -> Color {
        switch self {
        case .fire: return Color(red: 1.0, green: 0.5, blue: 0.2)
        case .water: return Color(red: 0.2, green: 0.6, blue: 1.0)
        // ... más
        }
    }
}
```

### Colores de Estadísticas

```
HP:        Rojo (#FF5959)
ATK:       Naranja (#F08030)
DEF:       Amarillo (#F8D030)
SP.ATK:    Azul (#7038F8)
SP.DEF:    Verde (#78C850)
SPD:       Rosa (#F85888)
```

---

## 🚀 Flujo Completo de Usuario

```
1. INICIAL
   App abre → FloatingTabBar

2. TAB 1: EXPLORACIÓN
   PokemonExploreView
   ├─ LoadPokemonList (155)
   ├─ LoadPokemonDetail (paralelo)
   └─ Muestra Grid de Pokémon

3. TAB POKÉMON
   Tap en Pokémon → PokemonDetailView
   ├─ Cargar detalles
   ├─ Cargar especie
   ├─ Cargar cartas TCG
   └─ Mostrar estadísticas

4. AGREGAR FAVORITO
   Tap ❤️ → AddFavoriteUseCase
   ├─ Guardar en SwiftData
   └─ Actualizar isFavorite

5. TAB 3: FAVORITOS
   FeatureFavoritesView
   ├─ Cargar favoritos
   └─ Mostrar Grid de favoritos

6. ELIMINAR FAVORITO
   Tap X → RemoveFavoriteUseCase
   ├─ Eliminar de SwiftData
   └─ Refrescar lista
```

---

## 📝 Checklist de Feature Implementation

Para agregar nueva feature:

- [ ] Crear estructura `Feature*/Data`, `Domain`, `Presentation`
- [ ] Definir Entity en Domain
- [ ] Crear ResponseModel en Data
- [ ] Implementar DataSource
- [ ] Crear Repository & Protocol
- [ ] Crear UseCase(s)
- [ ] Crear ViewModel (BaseViewModel)
- [ ] Crear View (SwiftUI)
- [ ] Crear Assembly (DI)
- [ ] Escribir tests
- [ ] Integrar en TabBar o navegación
- [ ] Actualizar documentación

---

**Última actualización**: Febrero 2025

# 🏗️ Arquitectura PokéDex

Documentación completa de la arquitectura Clean Architecture implementada en PokéDex.

## 📋 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Capas Arquitectónicas](#capas-arquitectónicas)
3. [Patrones Utilizados](#patrones-utilizados)
4. [Flujo de Datos](#flujo-de-datos)
5. [Módulos Detallados](#módulos-detallados)
6. [Decisiones de Diseño](#decisiones-de-diseño)

---

## 🎯 Visión General

PokéDex implementa **Clean Architecture** (Arquitectura Limpia) para lograr:

✅ **Separación de Responsabilidades** - Cada capa tiene un propósito específico
✅ **Testabilidad** - Fácil de escribir tests unitarios
✅ **Mantenibilidad** - Código organizado y escalable
✅ **Independencia de Frameworks** - La lógica de negocio no depende de SwiftUI
✅ **Reutilización** - Componentes modulares

### Diagrama de Capas

```
┌─────────────────────────────────────────────────────┐
│           PRESENTATION LAYER (UI)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │  SwiftUI     │  │  ViewModels  │  │ Assembly  │  │
│  │  Views       │  │              │  │  (DI)     │  │
│  └──────────────┘  └──────────────┘  └───────────┘  │
└──────────────────────┬────────────────────────────────┘
                       │
┌──────────────────────┴────────────────────────────────┐
│           DOMAIN LAYER (Lógica de Negocio)           │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐   │
│  │  Entities    │  │  UseCases    │  │  Repos    │   │
│  │  (Modelos)   │  │  (Lógica)    │  │ Protocols │   │
│  └──────────────┘  └──────────────┘  └───────────┘   │
└──────────────────────┬────────────────────────────────┘
                       │
┌──────────────────────┴────────────────────────────────┐
│           DATA LAYER (Fuentes de Datos)              │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐   │
│  │  Models      │  │  Repositories│  │DataSources│   │
│  │  (API DTOs)  │  │  (Impl)      │  │(Network,  │   │
│  │              │  │              │  │ Local DB) │   │
│  └──────────────┘  └──────────────┘  └───────────┘   │
└──────────────────────┬────────────────────────────────┘
                       │
┌──────────────────────┴────────────────────────────────┐
│           EXTERNAL SERVICES                          │
│  ┌──────────────┐  ┌──────────────┐                   │
│  │  PokeAPI     │  │  SwiftData   │                   │
│  │  (Network)   │  │  (LocalDB)   │                   │
│  └──────────────┘  └──────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

---

## 🏢 Capas Arquitectónicas

### 1️⃣ PRESENTATION LAYER (Capa de Presentación)

**Ubicación**: `PokeDex/Subfeatures/*/Presentation/`

**Responsabilidad**: Manejar la UI y la interacción con el usuario.

#### Componentes:

##### Views (SwiftUI)
```
FeatureExplore/Presentation/VIews/
└── PokemonExploreView.swift       # ListaView principal
```

- Mostrar datos
- Capturar interacciones del usuario
- NO contienen lógica de negocio
- Observan cambios del ViewModel

##### ViewModels
```
FeatureExplore/Presentation/ViewModels/
└── PokemonExploreViewModel.swift
    ├── Propiedades @Published
    ├── Métodos de negocio
    └── Manejo de estados
```

**Responsabilidades del ViewModel**:
```swift
public class PokemonExploreViewModel: BaseViewModel, ObservableObject {
    // 1. Estado UI
    @Published var pokemons = [PokemonModel]()
    @Published var state: ViewModelState

    // 2. Inyección de dependencias
    private let getUseCase = GetPokemonListUseCase(...)

    // 3. Métodos de negocio
    func loadPokemonList() { ... }

    // 4. Manejo de errores
    func errorViewAction(action: CustomErrorAction) { ... }
}
```

##### Assembly (Inyección de Dependencias)
```
FeatureExplore/Presentation/Assemblies/
└── PokemonExploreAssembly.swift
```

Configura las dependencias del módulo:
```swift
class PokemonExploreAssembly {
    static func assembleExploreFeature() -> PokemonExploreView {
        let viewModel = PokemonExploreViewModel(dto: nil)
        return PokemonExploreView(viewModel: viewModel)
    }
}
```

---

### 2️⃣ DOMAIN LAYER (Capa de Dominio)

**Ubicación**: `PokeDex/Subfeatures/*/Domain/`

**Responsabilidad**: Contener la lógica de negocio pura, independiente de frameworks.

#### Entidades
```
FeatureExplore/Domain/Entities/
├── PokemonEntity.swift        # Datos puros del dominio
├── PokemonTypes.swift
└── PokemonStats.swift
```

Las entidades representan objetos del mundo real:
```swift
struct PokemonEntity {
    let id: Int
    let name: String
    let types: [PokemonTypes]
    let stats: PokemonStats
}
```

#### Casos de Uso (UseCases)
```
FeatureExplore/Domain/UseCases/
└── GetPokemonListUseCase.swift
```

Representan acciones específicas del negocio:
```swift
class GetPokemonListUseCase {
    func execute(limit: Int) async throws -> [PokemonEntity] {
        // Lógica de negocio pura
        return try await repository.fetchPokemons(limit: limit)
    }
}
```

**Un UseCase = Una responsabilidad** (Single Responsibility Principle)

#### Protocolos de Repositorio
```
FeatureExplore/Domain/Repositories/
└── ExploreRepositoryProtocol.swift
```

Define interfaces (contratos) que deben cumplir los repositorios:
```swift
protocol ExploreRepositoryProtocol {
    func fetchPokemons(limit: Int) async throws -> [PokemonEntity]
}
```

**Ventaja**: El Domain no conoce detalles de implementación (HTTP, BD, etc.)

---

### 3️⃣ DATA LAYER (Capa de Datos)

**Ubicación**: `PokeDex/Subfeatures/*/Data/`

**Responsabilidad**: Implementar las fuentes de datos (API, BD local, etc.)

#### Modelos de Respuesta (DTOs)
```
FeatureExplore/Data/Models/
├── PokemonListResponseModel.swift    # JSON → Decodable
├── PokemonResponseModel.swift
└── PokemonDetailResponseModel.swift
```

Son estructuras Codable que mapean exactamente la respuesta de la API:
```swift
struct PokemonListResponseModel: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonResponseModel]
}
```

#### DataSources
```
FeatureExplore/Data/DataSource/
└── ExploreDataSource.swift
```

Hacen las llamadas HTTP reales:
```swift
class ExploreDataSource {
    func fetchPokemons(limit: Int) async throws -> PokemonListResponseModel {
        // 1. Construir URL
        // 2. Hacer request HTTP
        // 3. Decodificar respuesta
        // 4. Retornar modelo
    }
}
```

#### Repositories (Implementación)
```
FeatureExplore/Data/Repositories/
└── ExploreRepository.swift
```

Implementan los protocolos del Domain:
```swift
class ExploreRepository: ExploreRepositoryProtocol {
    private let exploreDataSource = ExploreDataSource()

    func fetchPokemons(limit: Int) async throws -> [PokemonEntity] {
        // 1. Obtener datos de DataSource (DTOs)
        let response = try await exploreDataSource.fetchPokemons(limit: limit)

        // 2. Mapear de DTO → Entity
        let entities = response.results.compactMap { dto in
            PokemonEntity(pokemonResponse: dto)
        }

        // 3. Retornar entidades del dominio
        return entities
    }
}
```

**Transformación de Datos**:
```
API JSON → DTO (Model) → Entity → ViewModel → View
```

---

## 🔄 Flujo de Datos

### Ejemplo: Cargar lista de Pokémon

```
1. User Action
   └─ View: "Tap load button"

2. ViewModel
   └─ loadPokemonList() activado
   └─ State = .loading
   └─ Llama al UseCase

3. Domain (UseCase)
   └─ GetPokemonListUseCase.execute(limit: 155)
   └─ Llama al Repository

4. Data (Repository)
   └─ ExploreRepository.fetchPokemons()
   └─ Solicita a DataSource

5. DataSource (Network)
   └─ ExploreDataSource.fetchPokemons()
   └─ HTTP GET a PokeAPI
   └─ Retorna PokemonListResponseModel (DTO)

6. Mapeo DTOs → Entities
   └─ Repository convierte Models → PokemonEntity

7. ViewModel recibe [PokemonEntity]
   └─ Convierte a PokemonModel (Presentation)
   └─ @Published pokemons = [...]
   └─ State = .okey

8. SwiftUI reactivo
   └─ View observa cambios
   └─ UI se actualiza automáticamente
```

### Diagrama de Secuencia

```
View → ViewModel → UseCase → Repository → DataSource → API
                                ↓
                        Mapeo DTO → Entity
                                ↓
                   [Entity] → ViewModel
                                ↓
                    @Published pokemons
                                ↓
                          View re-renders
```

---

## 📦 Módulos Detallados

### FeatureExplore: Exploración de Pokémon

```
FeatureExplore/
├── Data/
│   ├── Models/
│   │   ├── PokemonListResponseModel.swift    (API)
│   │   ├── PokemonResponseModel.swift        (API)
│   │   └── PokemonDetailResponseModel.swift  (API)
│   ├── DataSource/
│   │   └── ExploreDataSource.swift           (HTTP calls)
│   └── Repositories/
│       └── ExploreRepository.swift           (DTO → Entity)
│
├── Domain/
│   ├── Entities/
│   │   ├── PokemonEntity.swift               (Dominio puro)
│   │   ├── PokemonTypes.swift
│   │   └── PokemonStats.swift
│   ├── UseCases/
│   │   └── GetPokemonListUseCase.swift       (Lógica)
│   └── Repositories/
│       └── ExploreRepositoryProtocol.swift   (Interfaz)
│
└── Presentation/
    ├── Models/
    │   ├── PokemonModel.swift                (Presentation)
    │   └── PokemonSpecieModel.swift
    ├── ViewModels/
    │   └── PokemonExploreViewModel.swift     (UI Logic)
    ├── Views/
    │   └── PokemonExploreView.swift          (SwiftUI)
    └── Assemblies/
        └── PokemonExploreAssembly.swift      (DI)
```

**Flujo en FeatureExplore**:
1. Usuario ve lista de Pokémon
2. ViewModel carga con `GetPokemonListUseCase`
3. UseCase consulta `ExploreRepository`
4. Repository obtiene datos de `ExploreDataSource`
5. DataSource hace HTTP a PokeAPI
6. Repository mapea DTO → Entity
7. ViewModel convierte Entity → PokemonModel
8. View observa @Published y renderiza

---

### FeatureDetail: Detalles de Pokémon

Similar a FeatureExplore pero para información detallada:
- Estadísticas avanzadas
- Información de especies
- Gráficos interactivos

---

### FeatureFavourites: Sistema de Favoritos

**Diferencia**: Usa persistencia local (SwiftData) en lugar de API:

```
View → ViewModel → UseCase → Repository → FavoritesDataSource (SwiftData)
```

---

## 🎨 Patrones Utilizados

### 1. **Dependency Injection (DI)**
```swift
// Assembly inyecta dependencias
let viewModel = PokemonExploreViewModel(dto: nil)
```

### 2. **Repository Pattern**
```swift
protocol ExploreRepositoryProtocol { ... }
class ExploreRepository: ExploreRepositoryProtocol { ... }
```

Abstrae la fuente de datos (podría cambiar HTTP por BD local)

### 3. **UseCase Pattern**
```swift
class GetPokemonListUseCase {
    func execute(limit: Int) -> [PokemonEntity]
}
```

Encapsula una acción de negocio

### 4. **DTO (Data Transfer Object)**
```swift
struct PokemonListResponseModel: Codable { ... }  // DTO (API)
struct PokemonEntity { ... }                       // Entity (Domain)
struct PokemonModel { ... }                        // Presentation Model
```

### 5. **MVVM (Model-View-ViewModel)**
```
View (SwiftUI)
  ↓ observa
ViewModel (@Published)
  ↓ contiene
Models (Presentation)
```

### 6. **Protocol-Oriented Design**
```swift
protocol ExploreRepositoryProtocol { ... }  // Contrato
class ExploreRepository: ExploreRepositoryProtocol { ... }  // Implementación
```

### 7. **Observer Pattern (SwiftUI Reactive)**
```swift
@Published var pokemons = [PokemonModel]()  // Notifica cambios
```

---

## 🎯 Decisiones de Diseño

### ✅ Por qué Clean Architecture

| Beneficio | Explicación |
|-----------|------------|
| **Testeable** | Domain puede testearse sin UI ni Network |
| **Mantenible** | Cambios localizados, bajo acoplamiento |
| **Escalable** | Fácil agregar features sin afectar existentes |
| **Flexible** | Cambiar API o BD sin afectar lógica |

### ✅ Por qué tres modelos (DTO, Entity, Presentation)

```
PokemonListResponseModel (DTO)
    ↓ mapeo
PokemonEntity (Domain)
    ↓ mapeo
PokemonModel (Presentation)
    ↓
SwiftUI View
```

**Razones**:
1. **API puede cambiar** - Solo afecta DTO
2. **Dominio independiente** - Entity no sabe de Codable
3. **UI específica** - PokemonModel puede tener propiedades solo para UI

### ✅ Por qué Protocolos en Domain

```swift
protocol ExploreRepositoryProtocol {
    func fetchPokemons(limit: Int) async throws -> [PokemonEntity]
}
```

- Domain no depende de detalles de implementación
- Fácil escribir mocks para tests
- Cambiar implementación sin tocar Domain

### ✅ Por qué Assembly para DI

```swift
class PokemonExploreAssembly {
    static func assemble() -> PokemonExploreView { ... }
}
```

- Centraliza creación de dependencias
- Fácil cambiar implementaciones
- Escalable para proyectos grandes

---

## 🧪 Testabilidad

### Ejemplo: Test del UseCase

```swift
class GetPokemonListUseCaseTests: XCTestCase {
    func testExecuteReturnsPokemonEntities() async throws {
        // 1. Mock del Repository
        let mockRepository = MockExploreRepository()
        mockRepository.pokemonsToReturn = [...]

        // 2. Crear UseCase con mock
        let useCase = GetPokemonListUseCase(
            pokeDexRepository: mockRepository
        )

        // 3. Ejecutar
        let result = try await useCase.execute(limit: 10)

        // 4. Verificar
        XCTAssertEqual(result.count, 1)
    }
}
```

**Fácil porque**: UseCase solo depende de protocolos, no de implementaciones

---

## 🚀 Mejoras Futuras

1. **Caching** - Agregar caché HTTP
2. **Offline Mode** - Sincronización local
3. **Pagination** - Cargar más Pokémon bajo demanda
4. **Filters** - Filtrar por tipo, generación
5. **Search** - Búsqueda por nombre
6. **Unit Tests** - Cobertura completa
7. **Integration Tests** - Tests E2E

---

## 📚 Referencias

- [Clean Architecture - Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [SwiftUI Documentation](https://developer.apple.com/xcode/swiftui/)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)

---

**Documento actualizado**: Febrero 2025

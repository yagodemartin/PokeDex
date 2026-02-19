# 🎮 PokéDex

Una aplicación iOS moderna que explora el mundo Pokémon usando **Clean Architecture** y **SwiftUI**. Diseñada como referencia educativa para implementar patrones arquitectónicos profesionales en proyectos iOS.

## 📸 Demo

![PokéDex Preview](blob/preview.gif)

## ✨ Características

- 🔍 **Exploración de Pokémon** - Navega por 155 Pokémon de la generación Kanto
- 📊 **Estadísticas Detalladas** - Visualiza HP, Ataque, Defensa, etc. con gráficos interactivos
- ❤️ **Sistema de Favoritos** - Guarda tus Pokémon favoritos localmente
- 🎴 **Cartas TCG** - Integración con PokéAPI Trading Card Game
- 🎨 **UI/UX Moderna** - Diseño limpio con animaciones y colores por tipo
- 🌐 **Caché Inteligente** - Carga de datos paralela y eficiente

## 🏗️ Arquitectura

El proyecto implementa **Clean Architecture** en tres capas:

```
Presentation Layer (UI)
        ↓
Domain Layer (Lógica de negocio)
        ↓
Data Layer (Fuentes de datos)
```

Consulta [ARCHITECTURE.md](ARCHITECTURE.md) para una documentación detallada.

## 🛠️ Requisitos

- **iOS 16.0+**
- **Xcode 15.0+**
- **Swift 5.9+**

## 📦 Dependencias

- SwiftUI (nativa)
- SwiftData (persistencia)
- URLSession (networking)

## 🚀 Quick Start

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd PokeDex
```

### 2. Abrir en Xcode

```bash
open PokeDex.xcodeproj
```

### 3. Seleccionar target y ejecutar

- **PokeDex**: Aplicación principal
- **PokeDexPruebas**: Tests unitarios

### 4. Compilar y ejecutar

```
⌘ + R
```

## 📁 Estructura del Proyecto

```
PokeDex/
├── Core/                          # Componentes compartidos
│   ├── BaseClasses/              # BaseViewModel reutilizable
│   ├── Components/               # Vistas y modificadores comunes
│   ├── Extensions/               # Extensiones de Color, Logger
│   └── Utils/                    # Constants, NetworkUtils, JSONUtils
│
├── Subfeatures/                  # Módulos funcionales
│   ├── FeatureExplore/          # Listado y exploración de Pokémon
│   │   ├── Data/                # Modelos API, DataSource, Repository
│   │   ├── Domain/              # Entidades, Casos de Uso, Protocolos
│   │   └── Presentation/        # ViewModel, Views, Assembly
│   │
│   ├── FeatureDetail/           # Detalle de Pokémon
│   ├── FeatureFavourites/       # Gestión de favoritos
│   ├── FeatureCards/            # Integración TCG
│   └── Tabview/                 # Navegación y TabBar flotante
│
├── App/                          # Punto de entrada
└── Resources/                    # Assets, colores, animaciones
```

## 🎯 Módulos Principales

### FeatureExplore
Módulo responsable de listar y explorar Pokémon.
- Carga lista inicial desde PokeAPI
- Fetch paralelo de detalles (optimización con TaskGroups)
- Caché local de datos

### FeatureDetail
Visualización detallada de cada Pokémon.
- Estadísticas y gráficos
- Información de especies
- Integración con favoritos

### FeatureFavourites
Sistema de favoritos persistente.
- Almacenamiento con SwiftData
- CRUD operations
- Sincronización en tiempo real

### FeatureCards
Integración con PokéAPI TCG.
- Búsqueda de cartas
- Galería con imágenes

## 🧪 Testing

El proyecto incluye tests unitarios en `PokeDexPruebas`:

```bash
# Ejecutar tests
⌘ + U
```

Archivos de test:
- `PokemonListResponseModelTests.swift` - Tests de modelos

## 🔌 APIs Externas

### PokeAPI
- **Base URL**: `https://pokeapi.co/api/v2/`
- **Endpoints utilizados**:
  - `GET /pokemon?limit=155` - Listado de Pokémon
  - `GET /pokemon/{id}` - Detalles de Pokémon
  - `GET /pokemon-species/{id}` - Información de especies
  - `GET /pokemon-species/{id}/flavor-text-entries` - Descripción

### Artwork
- **Source**: Official Pokémon artwork en GitHub
- **URL**: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/{id}.png`

## 🎨 Design System

- **Colores**: Por tipo de Pokémon (Fire, Water, Grass, etc.)
- **Tipografía**: System fonts (San Francisco)
- **Componentes**: CardView, CapsuleView, PokemonCellView
- **Animaciones**: LoaderView, LikeAnimationView

## 📝 Notas Importantes

1. **Carga de Datos**: Los 155 primeros Pokémon se cargan con sus detalles en paralelo para optimizar tiempo
2. **Persistencia**: SwiftData maneja automáticamente el almacenamiento de favoritos
3. **Manejo de Estados**: BaseViewModel proporciona estados comunes (loading, error, success)
4. **Thread Safety**: Todas las actualizaciones de UI corren en MainThread con `@MainActor`


## 📄 Licencia

Este proyecto es de código abierto para propósitos educativos.

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## ❓ Preguntas y Soporte

Si tienes preguntas o encuentras problemas, abre un [Issue](https://github.com/yourusername/PokeDex/issues).

---

**Última actualización**: Febrero 2025

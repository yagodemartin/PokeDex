# 📖 DocC - Guía de Documentación en Xcode

Guía para acceder y navegar la documentación DocC (Documentation Compiler) de Apple en el proyecto PokéDex.

## 🎯 ¿Qué es DocC?

DocC es el compilador de documentación oficial de Apple para Swift. Permite:
- ✅ Escribir documentación en comentarios del código
- ✅ Verla directamente en Xcode
- ✅ Generar sitios web con documentación
- ✅ Crear guías y tutoriales

---

## 🚀 Acceder a la Documentación en Xcode

### Opción 1: Quick Help (La más fácil)

**Para ver documentación de cualquier clase/función:**

1. **⌘ + Click** en el nombre de la clase/función
2. Quick Help aparecerá en un panel

**Ejemplo:**
```swift
// En tu código
let pokemon = PokemonEntity(pokemonResponse: response)
                ↓
// ⌘ + Click en PokemonEntity
// Se abre Quick Help con documentación
```

### Opción 2: Inspector de Documentación

**Para ver documentación detallada:**

1. Selecciona una clase/función en el editor
2. Abre **Inspector** (derecha) → **Documentation** tab
3. Ver documentación completa con ejemplos

**Acceso:**
- **Keyboard**: ⌘ + ⌥ + 1
- **Menu**: View → Inspectors → Show Documentation Inspector

### Opción 3: Symbol Documentation

**Para ver toda la documentación de un archivo:**

1. **Option + Click** en el nombre de la clase
2. O selecciona en el código → **Shift + Control + Option + ?**
3. Abre Symbol Documentation en nueva ventana

---

## 📚 Archivos Documentados

### Core (Componentes Base)

#### BaseViewModel
**Ubicación**: `PokeDex/Core/BaseClasses/BaseViewModel.swift`

**Documentado**:
- Clase `BaseViewModel` (propósito y uso)
- Enum `ViewModelState` (todos los estados)
- Propiedad `state` (qué es)
- Propiedad `showWarningError` (cuándo usarla)
- Método `onAppear()` (ciclo de vida)

**Acceder**: ⌘ + Click en `BaseViewModel`

---

### Domain Layer (Lógica de Negocio)

#### GetPokemonListUseCase
**Ubicación**: `PokeDex/Subfeatures/FeatureExplore/Domain/UseCases/GetPokemonListUseCase.swift`

**Documentado**:
- Responsabilidades del use case
- Cómo funciona (flujo)
- Ejemplo de uso
- Performance notes
- Parámetros y retorno

**Acceder**: ⌘ + Click en `GetPokemonListUseCase`

#### GetPokemonDetailUseCase
**Ubicación**: `PokeDex/Subfeatures/FeatureDetail/Domain/UseCases/GetPokemonDetailUseCase.swift`

**Documentado**:
- Diferencia con GetPokemonListUseCase
- Performance optimization (TaskGroups)
- Detalles incluidos en respuesta

**Acceder**: ⌘ + Click en `GetPokemonDetailUseCase`

#### PokemonEntity
**Ubicación**: `PokeDex/Subfeatures/FeatureExplore/Domain/Entities/PokemonEntity.swift`

**Documentado**:
- Descripción de la entidad
- Cada propiedad con su significado
- Unidades (altura en dm, peso en hg)
- Formas de inicialización

**Acceder**: ⌘ + Click en `PokemonEntity`

---

### Data Layer (Acceso a Datos)

#### ExploreRepository
**Ubicación**: `PokeDex/Subfeatures/FeatureExplore/Data/Repositories/ExploreRepository.swift`

**Documentado**:
- Arquitectura (diagrama de capas)
- Transformación de datos (DTO → Entity)
- Patrón Singleton
- Performance esperado

**Acceder**: ⌘ + Click en `ExploreRepository`

---

### Presentation Layer (Vista)

#### PokemonExploreViewModel
**Ubicación**: `PokeDex/Subfeatures/FeatureExplore/Presentation/ViewModels/PokemonExploreViewModel.swift`

**Documentado**:
- Responsabilidades (qué hace)
- Flujo de datos (diagram)
- Método `loadPokemonList()` (entrada principal)
- Método `loadPokemonDetail()` (optimización con TaskGroups)
- Método `errorViewAction()` (manejo de errores)
- Performance optimization details

**Acceder**: ⌘ + Click en `PokemonExploreViewModel`

---

## 💡 Cómo está Estructurada la Documentación

Cada comentario DocC sigue este formato:

```swift
/// Una línea de resumen breve
///
/// Una descripción más detallada que explica qué hace,
/// por qué existe, y cuándo se usa.
///
/// ## Overview
/// Una sección que explica el propósito general
///
/// ## Usage
/// ```swift
/// Código de ejemplo
/// ```
///
/// ## Parameters
/// - Parameter1: Descripción
/// - Parameter2: Descripción
///
/// ## Returns
/// Descripción del retorno
///
/// ## Throws
/// Errores que puede lanzar
public class MyClass { }
```

---

## 🎯 Patrones de Documentación Usados

### 1. Clase Documentada

```swift
/// Una descripción clara de qué es la clase
///
/// Explicación detallada incluyendo:
/// - Responsabilidades
/// - Cuándo usarla
/// - Patrones que implementa
///
/// ## Usage
/// ```swift
/// let instance = MyClass()
/// ```
public class MyClass { }
```

**Acceder**: ⌘ + Click en `MyClass`

---

### 2. Método Documentado

```swift
/// Descripción de qué hace el método
///
/// Explicación más detallada incluyendo
/// casos de uso y comportamiento.
///
/// - Parameter param1: Descripción del parámetro
/// - Parameter param2: Descripción del parámetro
/// - Returns: Descripción del valor retornado
/// - Throws: Errores posibles
///
/// ## Performance
/// Notas sobre performance
func myMethod(param1: String, param2: Int) throws -> String { }
```

**Acceder**: ⌘ + Click en `myMethod`

---

### 3. Propiedad Documentada

```swift
/// Descripción de la propiedad
/// Qué representa, qué valores puede tener, unidades, etc.
@Published var myProperty: String = ""
```

**Acceder**: ⌘ + Click en `myProperty`

---

### 4. Enum Documentada

```swift
/// Los estados posibles de la aplicación
enum ViewModelState: String {
    /// Indica que todo está bien y los datos se cargaron
    case okey

    /// Datos se están cargando de la red
    case loading

    /// Ocurrió un error
    case error
}
```

**Acceder**: ⌘ + Click en `ViewModelState`

---

## 🔍 Ejemplos de Uso

### Ejemplo 1: Entender GetPokemonListUseCase

```swift
// En tu código
let useCase = GetPokemonListUseCase(...)

// ⌘ + Click en GetPokemonListUseCase
// Se abre Quick Help mostrando:
// - Qué hace
// - Cómo se usa
// - Ejemplo de código
// - Notas de performance
```

### Ejemplo 2: Ver parámetro de PokemonEntity

```swift
// En tu código
let pokemon = PokemonEntity(...)
print(pokemon.height)  // ← ⌘ + Click aquí

// Se abre Quick Help con:
// - Descripción: "height: Int?"
// - Significado: "La altura del Pokémon en decímetros (dm)"
// - Ejemplo: "17 means 1.7 metros"
```

### Ejemplo 3: Entender loadPokemonDetail()

```swift
// En ViewModel
await viewModel.loadPokemonDetail()
                         ↓
// ⌘ + Click en loadPokemonDetail

// Se abre documentación con:
// - Qué hace (carga en paralelo)
// - Cómo funciona (TaskGroup)
// - Performance (15-30s vs 8 minutos)
// - Manejo de errores
```

---

## 🛠️ Keyboard Shortcuts

| Atajo | Función |
|-------|---------|
| **⌘ + Click** | Quick Help (más rápido) |
| **⌘ + ⌥ + 1** | Documentation Inspector |
| **Option + Click** | Symbol Documentation (detallado) |
| **Shift + Control + Option + ?** | Help con símbolo |

---

## 📖 Navegar la Documentación

### Quick Help

```
┌─────────────────────────────────────┐
│ GetPokemonListUseCase               │
├─────────────────────────────────────┤
│ A use case that fetches a list of   │
│ Pokémon from the API.               │
│                                      │
│ >> Open in Documentation Viewer     │
│ >> Jump to Definition               │
└─────────────────────────────────────┘
```

Haz click en "Open in Documentation Viewer" para ver todo.

---

### Documentation Inspector

```
Lado derecho de Xcode

┌─ Documentation
│
├─ Declaration
│  └─ class GetPokemonListUseCase { }
│
├─ Overview
│  └─ A use case that fetches...
│
├─ Method
│  └─ execute(limit: Int) -> [PokemonEntity]
│
└─ Parameters
   └─ limit: The maximum number...
```

---

## 🎨 Elementos Especiales en la Documentación

### Emphasis (Énfasis)

```swift
/// Use this method to **load** data
///
/// This is _important_ to understand
```

Renderiza como:
- `**load**` → **load** (negrita)
- `_important_` → *important* (itálica)

### Code Highlighting

```swift
/// The method uses `withThrowingTaskGroup`
/// to parallelize requests
```

Renderiza `withThrowingTaskGroup` como código monoespaciado.

### Links

```swift
/// See also ``PokemonEntity`` and ``GetPokemonDetailUseCase``
```

Crea links a otras clases documentadas.

### Secciones

```swift
/// ## Overview
/// Explanation here
///
/// ## Usage
/// ```swift
/// code example
/// ```
///
/// ## Performance
/// Notes here
```

---

## 🔗 Enlaces Cruzados

La documentación puede referenciar otras clases documentadas:

```swift
/// Implementa ``ExploreRepositoryProtocol``
/// y usa ``ExploreDataSource``
```

En Xcode, puedes hacer ⌘ + Click en estos enlaces.

---

## 🚀 Generar Sitio Web (Avanzado)

Si quieres generar documentación en formato sitio web:

```bash
cd PokeDex

# Generar documentación
xcodebuild docbuild \
    -project PokeDex.xcodeproj \
    -scheme PokeDex \
    -derivedDataPath .build

# Sitio web en: .build/Build/Products/Debug/PokeDex.doccarchive
```

---

## ✅ Checklist de Documentación

Archivos con documentación DocC:

- [x] `BaseViewModel.swift` - Clase base
- [x] `GetPokemonListUseCase.swift` - Cargar lista
- [x] `GetPokemonDetailUseCase.swift` - Cargar detalles
- [x] `PokemonEntity.swift` - Entidad del dominio
- [x] `ExploreRepository.swift` - Data access
- [x] `PokemonExploreViewModel.swift` - Presentation logic

**Próximos a documentar**:
- [ ] Otros ViewModels
- [ ] DataSource clases
- [ ] Componentes de UI
- [ ] Protocolos

---

## 💡 Tips

1. **Mientras desarrollas**: Usa ⌘ + Click frecuentemente para verificar qué dice la documentación
2. **Al escribir código nuevo**: Escribe comentarios DocC primero, luego el código
3. **Para colaboradores**: La documentación en código es la mejor forma de compartir conocimiento
4. **Mantén actualizado**: Si cambias código, actualiza su documentación

---

## 📚 Referencias

- [Apple DocC Documentation](https://developer.apple.com/documentation/docc)
- [Writing Symbol Documentation in Your Code](https://developer.apple.com/documentation/docc/writing-symbol-documentation-in-your-code)
- [Formatting Your Documentation](https://developer.apple.com/documentation/docc/formatting-your-documentation)

---

**Última actualización**: Febrero 2025

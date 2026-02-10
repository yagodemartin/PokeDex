# 🔧 Setup y Configuración

Guía completa para configurar el proyecto PokéDex en tu entorno de desarrollo.

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Instalación](#instalación)
3. [Configuración de Xcode](#configuración-de-xcode)
4. [Variables de Entorno](#variables-de-entorno)
5. [Ejecución](#ejecución)
6. [Troubleshooting](#troubleshooting)
7. [Desarrollo](#desarrollo)

---

## ✅ Requisitos Previos

### Software Requerido

| Componente | Versión | Descripción |
|-----------|---------|------------|
| **macOS** | 12.0+ | Sistema operativo |
| **Xcode** | 15.0+ | IDE de desarrollo |
| **Swift** | 5.9+ | Lenguaje de programación |
| **iOS Deployment Target** | 16.0+ | Versión mínima de iOS |
| **Git** | 2.30+ | Control de versiones |

### Requisitos de Hardware

- **Mac**: MacBook Air M1 o superior (o Intel de última generación)
- **RAM**: 8GB mínimo (16GB recomendado)
- **Espacio**: 10GB libre para Xcode + proyecto

### Herramientas Opcionales

- **Homebrew**: Gestor de paquetes (opcional)
- **CocoaPods**: No necesario (proyecto usa solo dependencias nativas)
- **Swiftlint**: Linting (ya configurado en `.swiftlint.yml`)

---

## 📥 Instalación

### 1. Instalar Xcode (si no lo tienes)

```bash
# Opción A: Desde App Store (recomendado)
# Abre App Store y busca "Xcode"

# Opción B: Desde línea de comandos
xcode-select --install
```

**Verificar instalación:**
```bash
xcode-select -p
# Debe retornar: /Applications/Xcode.app/Contents/Developer
```

### 2. Clonar el Repositorio

```bash
# HTTPS (recomendado si no tienes SSH configurado)
git clone https://github.com/yourusername/PokeDex.git

# O con SSH (si tienes SSH configurado)
git clone git@github.com:yourusername/PokeDex.git

# Entrar al directorio
cd PokeDex
```

### 3. Verificar la Estructura

```bash
# Listar archivos principales
ls -la

# Debería mostrar:
# - PokeDex/              (app source code)
# - PokeDexPruebas/       (tests)
# - PokeDex.xcodeproj/    (project file)
# - README.md
# - ARCHITECTURE.md
# - SETUP.md
```

### 4. Verificar Git

```bash
# Confirmar que estás en la rama correcta
git status

# Debería mostrar: "On branch main"
```

---

## ⚙️ Configuración de Xcode

### 1. Abrir el Proyecto

```bash
# Opción A: Desde terminal
open PokeDex.xcodeproj

# Opción B: Abrir Xcode y File → Open → PokeDex.xcodeproj
```

### 2. Seleccionar Team Signing (si necesario)

Si aparece un aviso sobre "Signing":

1. Selecciona el proyecto en el navegador izquierdo
2. Ve a **Build Settings** → **Signing & Capabilities**
3. En **Team**, selecciona tu equipo o "None" para desarrollo local

### 3. Verificar Target Deployment

```
Target: PokeDex
├── General
│   ├── Minimum Deployment: iOS 16.0+
│   ├── Device: iPhone
│   └── Orientations: Portrait
└── Build Settings
    ├── Swift Language: 5.9+
    └── iOS SDK: Latest
```

### 4. Build Settings Importantes

**En `PokeDex.xcodeproj` → Build Settings:**

```
SWIFT_VERSION = 5.9
IPHONEOS_DEPLOYMENT_TARGET = 16.0
ENABLE_TESTABILITY = YES (para tests)
```

### 5. Verificar Modelos de Datos

SwiftData usa el modelo en `PokeDex/Pokemon_Clean_Architecture.xcdatamodeld/`:

```
└── Pokemon_Clean_Architecture.xcdatamodel
    └── Entidad: PokemonModel
        ├── Atributos
        ├── Relaciones
        └── Configuración
```

---

## 🔑 Variables de Entorno

### Constants Principales

Archivo: `PokeDex/Core/Utils/Constants.swift`

```swift
struct Constants {
    // URLs de API
    static let pokeApiURL = "https://pokeapi.co/api/v2/"
    static let pokeApiArtworkURL = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/%d.png"

    // Configuración de red
    static let pokeApiTimeoutInterval = 15.0

    // Datos
    static let pokeApiPokemonListlimit = 155
}
```

### Modificar Configuración

Para cambiar límite de Pokémon o timeout:

```swift
// En Constants.swift
static let pokeApiPokemonListlimit = 250  // Aumentar a 250
static let pokeApiTimeoutInterval = 30.0   // Aumentar timeout
```

### Logger Configuration

Archivo: `PokeDex/Core/Extensions/Logger_extension.swift`

```swift
extension Logger {
    static let api = Logger(subsystem: "com.pokedex.api", category: "api")
}
```

Para ver logs en Xcode:

```
Product → Scheme → Edit Scheme → Run → Console
```

---

## 🚀 Ejecución

### Opción 1: Ejecutar desde Xcode (Recomendado)

```bash
# 1. Seleccionar simulator o device
# 2. Product → Run (⌘ + R)
# 3. Esperar compilación y apertura de app
```

### Opción 2: Ejecutar desde Terminal

```bash
# Compilar
xcodebuild -project PokeDex.xcodeproj -scheme PokeDex -configuration Debug

# Compilar y ejecutar en simulator
xcodebuild -project PokeDex.xcodeproj \
  -scheme PokeDex \
  -configuration Debug \
  -simulator "iPhone 15 Pro"
```

### Opción 3: Seleccionar Simulator Específico

En Xcode:
```
Product → Destination → iPhone 15 Pro
```

**Simulators disponibles:**
- iPhone 15 Pro (recomendado para testing)
- iPhone 15
- iPhone 14 Pro
- iPad Pro 12.9"

### Verificar Ejecución

1. App debe abrir con tab bar flotante
2. Primera tab muestra lista de Pokémon (loading state)
3. Después carga 155 Pokémon
4. Puedes navegar entre tabs

---

## 🧪 Ejecutar Tests

### Opción 1: Desde Xcode

```
Product → Test (⌘ + U)
```

### Opción 2: Desde Terminal

```bash
# Ejecutar todos los tests
xcodebuild test -project PokeDex.xcodeproj -scheme PokeDex

# Ejecutar tests específicos
xcodebuild test \
  -project PokeDex.xcodeproj \
  -scheme PokeDex \
  -testPlan "PokeDexPruebas"
```

### Cobertura de Tests

```bash
# Generar reporte de cobertura
xcodebuild test \
  -project PokeDex.xcodeproj \
  -scheme PokeDex \
  -enableCodeCoverage YES
```

---

## 🐛 Troubleshooting

### Problema: "Module not found"

```
Error: 'PokeDex' module not found
```

**Solución:**
```bash
# Limpiar build
Cmd + Shift + K

# Eliminar derivados
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Rebuild
Cmd + B
```

### Problema: "Swift version mismatch"

```
Error: Swift 5.8 required but 5.9 found
```

**Solución:**
1. Verificar Xcode version: `xcode-select -p`
2. En Xcode: Build Settings → SWIFT_VERSION = 5.9

### Problema: "API not reachable"

```
Error: URLError(.badServerResponse)
```

**Soluciones:**
```bash
# Verificar conexión
ping pokeapi.co

# Aumentar timeout en Constants.swift
static let pokeApiTimeoutInterval = 30.0
```

### Problema: "SwiftData model error"

```
Error: Schema validation failed
```

**Solución:**
```bash
# Resetear datos locales
# En iOS Simulator: Device → Erase All Content and Settings...

# O en código (temporal):
try? modelContext.delete(model: PokemonModel.self)
```

### Problema: "Signing error"

```
Error: No signing identity found
```

**Solución:**
1. Project Settings → Signing & Capabilities
2. Team: None (para desarrollo local)
3. O selecciona tu Apple ID

### Limpieza Completa

Si todo falla, hacer reset completo:

```bash
# 1. Limpiar derivados
rm -rf ~/Library/Developer/Xcode/DerivedData/

# 2. Limpiar build folder
cd PokeDex
xcodebuild clean

# 3. Reinstalar pods (si usara CocoaPods)
# pod deintegrate && pod install

# 4. Resetear git a última versión limpia
git reset --hard HEAD
git clean -fd
```

---

## 👨‍💻 Desarrollo

### Agregar Nueva Feature

```bash
# 1. Crear rama
git checkout -b feature/MiNuevaFeature

# 2. Crear estructura de carpetas
PokeDex/Subfeatures/FeatureMiFeature/
├── Data/
│   ├── Models/
│   ├── DataSources/
│   └── Repositories/
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   └── Repositories/
└── Presentation/
    ├── ViewModels/
    ├── Views/
    └── Assemblies/

# 3. Implementar según Clean Architecture
# 4. Tests en PokeDexPruebas/Subfeatures/FeatureMiFeature/

# 5. Commit y push
git add .
git commit -m "feat: Add MiNuevaFeature"
git push origin feature/MiNuevaFeature
```

### Ejecutar Linting

```bash
# Instalar swiftlint (si no lo tienes)
brew install swiftlint

# Ejecutar linter
swiftlint

# Fijar problemas automáticamente
swiftlint --fix
```

### Ver Logs de Red

En cualquier vista:
```swift
import OSLog

let logger = Logger(subsystem: "com.pokedex.api", category: "api")
logger.debug("Request: \(url)")
logger.info("Response: \(response)")
```

Ver en: Xcode → Console (⌘ + Shift + C)

### Preview en Xcode

Para previsualizaciones en Xcode:

```swift
#Preview {
    PokemonExploreView(viewModel: PokemonExploreViewModel(dto: nil))
}
```

Luego: Editor → Canvas (⌘ + ⌥ + Return)

---

## 📱 Dispositivos Reales

### Conectar iPhone

1. Conectar iPhone via USB
2. Xcode detectará automáticamente
3. Confiar en computadora en iPhone
4. Seleccionar device en Xcode
5. Build & Run (⌘ + R)

### Requerimientos para Device

- iOS 16.0+
- Apple ID configurado
- Developer Mode activado (Settings → Developer)

---

## 🔄 Actualizar Dependencias

### SwiftUI/SwiftData (Built-in)

No necesita actualización manual, incluidas en Swift.

### Verificar Versiones

```bash
# Swift version
swift --version

# iOS SDK version
xcrun --show-sdk-version --sdk iphoneos
```

---

## ✅ Checklist Final

Antes de empezar a desarrollar:

- [ ] Xcode 15.0+ instalado
- [ ] Proyecto clonado sin errores
- [ ] `git status` muestra rama `main`
- [ ] Proyecto abre sin errores
- [ ] Build successful (⌘ + B)
- [ ] Tests ejecutan sin errores (⌘ + U)
- [ ] App ejecuta en simulator (⌘ + R)
- [ ] API accesible (carga Pokémon)
- [ ] Swiftlint sin errores críticos
- [ ] Documentación leída

---

## 🆘 Obtener Ayuda

- **Documentación**: Ver [README.md](README.md) y [ARCHITECTURE.md](ARCHITECTURE.md)
- **Errores de Build**: Consultar Output en Xcode
- **Errores de Runtime**: Ver Console (⌘ + Shift + C)
- **Preguntas**: Abrir Issue en GitHub

---

**Última actualización**: Febrero 2025

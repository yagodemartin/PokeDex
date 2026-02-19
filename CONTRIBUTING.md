# Contributing to PokéDex

First off, thank you for considering contributing to PokéDex! It's people like you that make PokéDex such a great reference project for learning Clean Architecture in Swift.

## Code of Conduct

This project adheres to the Contributor Covenant [code of conduct](https://www.contributor-covenant.org/). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [issue list](https://github.com/yagodemartin/PokeDex/issues) as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps which reproduce the problem** in as much detail as possible
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps**
* **Explain which behavior you expected to see instead and why**
* **Include screenshots or animated GIFs** if possible
* **Include your iOS version, device type, and Xcode version**

### Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub issues](https://github.com/yagodemartin/PokeDex/issues).

When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a step-by-step description of the suggested enhancement**
* **Provide specific examples to demonstrate the steps**
* **Describe the current behavior** and **the expected behavior**
* **Explain why this enhancement would be useful**

### Pull Requests

* Fill in the required PR template
* Follow the Swift style guide (see below)
* Include appropriate test cases
* Update documentation as needed
* End all files with a newline

---

## Git Workflow: GitFlow Light

PokéDex uses a simplified GitFlow strategy for managing branches and releases.

### Branch Strategy

```
main (production-ready releases)
  ↑
  ├─ develop (integration branch)
        ↑
        ├─ feature/feature-name (your work)
        ├─ feature/bugfix-name
        └─ feature/enhancement-name
```

### Main Branches

- **`main`**: Production-ready code. Only updated during releases.
- **`develop`**: Integration branch. Contains the latest development changes.

### Feature Branches

Feature branches are created from `develop` and named descriptively:

- `feature/add-search-functionality`
- `feature/fix-favorites-persistence`
- `feature/refactor-network-layer`
- `feature/add-pokemon-filtering`

### Step-by-Step Contribution Process

#### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/PokeDex.git
cd PokeDex

# Add upstream remote
git remote add upstream https://github.com/yagodemartin/PokeDex.git
```

#### 2. Create a Feature Branch

Always create branches from `develop`, never from `main`:

```bash
# Fetch latest changes
git fetch upstream

# Create your feature branch from develop
git checkout -b feature/your-feature-name upstream/develop
```

**Branch Naming Convention**:
- `feature/` - New features
- `feature/fix-` - Bug fixes
- `feature/refactor-` - Code refactoring
- `feature/docs-` - Documentation
- `feature/test-` - Tests

#### 3. Make Your Changes

Write clean, well-documented code following Swift best practices:

```swift
/// Brief description of what this function does.
///
/// More detailed description if needed. Explain the purpose,
/// parameters, return value, and any throws or side effects.
///
/// - Parameter name: Description of parameter
/// - Returns: Description of return value
/// - Throws: Description of errors that might be thrown
public func functionName(parameter: String) async throws -> Result {
    // Implementation
}
```

#### 4. Commit with Clear Messages

Each commit should represent one logical unit of work:

**✅ GOOD Commit Messages:**
```
Add Pokemon search functionality

Add search bar to PokemonExploreView
Implement SearchUseCase in FeatureExplore
Add filtering logic to PokemonExploreViewModel
```

**❌ BAD Commit Messages:**
```
fix stuff
update code
changes
```

**Commit Message Format**:
```
<type>: <subject>

<body>

<footer>
```

**Types**:
- `feat`: A new feature
- `fix`: A bug fix
- `refactor`: Code refactoring without feature changes
- `docs`: Documentation changes
- `test`: Test additions or changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `chore`: Build process, dependency updates

**Example**:
```
feat: add Pokemon search functionality

Implement search bar in PokemonExploreView that filters
the Pokemon list by name in real-time.

Add SearchUseCase to Domain layer with filter logic.
Update PokemonExploreViewModel to handle search state.

Closes #123
```

#### 5. Keep Your Branch Updated

```bash
# Fetch latest changes from upstream
git fetch upstream

# Rebase your branch on develop
git rebase upstream/develop
```

#### 6. Test Your Changes

```bash
# Build the project
⌘ + B

# Run the app
⌘ + R

# Run unit tests
⌘ + U
```

Ensure:
- ✅ Project compiles without warnings
- ✅ All existing tests pass
- ✅ Your changes work as expected
- ✅ No new warnings introduced

#### 7. Push and Create Pull Request

```bash
# Push your branch to your fork
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub:

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Set base to `develop` (not `main`)
4. Fill in the PR template with:
   - Clear description of changes
   - Why these changes are needed
   - How to test the changes
   - Related issues (use `Closes #123`)

#### 8. Code Review

A maintainer will review your PR. Be ready to:
- Respond to feedback and questions
- Make requested changes
- Push additional commits to the same PR

#### 9. Merge

Once approved, your PR will be merged into `develop`. Your feature branch will be deleted.

---

## Swift Style Guide

### Code Organization

```swift
// MARK: - Imports
import Foundation
import SwiftUI

// MARK: - Type Definition
@MainActor
final class MyViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var state: ViewState = .idle

    // MARK: - Private Properties
    private let useCase: MyUseCase

    // MARK: - Initialization
    init(useCase: MyUseCase) {
        self.useCase = useCase
    }

    // MARK: - Public Methods
    func loadData() async {
        // ...
    }

    // MARK: - Private Methods
    private func handleError(_ error: Error) {
        // ...
    }
}
```

### Naming Conventions

```swift
// ✅ GOOD: Descriptive names
struct PokemonDetailViewModel { }
func fetchPokemonDetails(id: Int) async throws { }
let pokemonList: [Pokemon] = []

// ❌ BAD: Cryptic abbreviations
struct PDViewModel { }
func fetch(id: Int) async throws { }
let pl: [Pokemon] = []
```

### Async/Await & Error Handling

```swift
// ✅ GOOD: Use async throws
func fetchData(id: Int) async throws -> Data {
    // Propagate errors properly
}

// Handle errors in ViewModel
do {
    let data = try await useCase.fetchData(id: 1)
    self.state = .loaded(data)
} catch {
    self.state = .error(error)
}

// ❌ BAD: Avoid force-try and fatalError
func fetchData() -> Data {
    try! someThrowingFunction()  // ❌ Never
}
```

### SwiftUI Best Practices

```swift
// ✅ GOOD: View hierarchy is clear
var body: some View {
    VStack {
        headerView
        contentView
        footerView
    }
}

private var headerView: some View {
    Text("Title")
        .font(.title)
}

// ❌ BAD: Huge body closure
var body: some View {
    VStack {
        VStack { ... }.padding()
        ForEach { ... }
        // 200 lines of code...
    }
}
```

### Documentation

All public types and functions must have documentation:

```swift
/// Brief description (one line).
///
/// More detailed explanation if needed. Can include:
/// - Lists of important points
/// - Examples of usage
/// - Related methods or properties
///
/// - Parameters:
///   - parameter1: Description
///   - parameter2: Description
/// - Returns: Description of return value
/// - Throws: CustomError if something goes wrong
///
/// Example usage:
/// ```swift
/// let result = try await fetch(id: 1)
/// ```
public func fetch(id: Int, name: String) async throws -> Result {
    // Implementation
}
```

---

## Architecture Guidelines

### Clean Architecture Principles

When adding new features, follow Clean Architecture:

```
Presentation → Domain → Data
     ↓           ↓       ↓
   Views    UseCases  DataSource
 ViewModels Entities  Repository
            Protocols
```

### Adding a New Feature

1. **Create feature directory** under `Subfeatures/`

```
Subfeatures/FeatureNewModule/
├── Presentation/
│   ├── Views/
│   ├── ViewModels/
│   └── Assemblies/
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   └── Repositories/
└── Data/
    ├── Models/
    ├── DataSource/
    └── Repositories/
```

2. **Define Domain Entities** (business logic, framework-independent)
3. **Create Domain UseCases** (business rules)
4. **Define Repository Protocols** (contracts in Domain)
5. **Implement Data Layer** (DTOs, DataSources, Repositories)
6. **Create Presentation Layer** (ViewModels, Views)
7. **Add Tests** (at least for UseCases)

---

## Testing Requirements

- New features should include unit tests
- Bug fixes should include a test that reproduces the bug
- Aim for 70%+ code coverage on critical paths
- Use mock objects for external dependencies

Example test:

```swift
@MainActor
class GetPokemonDetailsUseCaseTests: XCTestCase {

    func testExecuteReturnsPokemonDetails() async throws {
        // Arrange: Set up mocks
        let mockRepository = MockPokemonRepository()
        mockRepository.mockPokemon = PokemonEntity(id: 1, name: "Bulbasaur")

        let useCase = GetPokemonDetailsUseCase(repository: mockRepository)

        // Act: Execute
        let result = try await useCase.execute(id: 1)

        // Assert: Verify
        XCTAssertEqual(result.name, "Bulbasaur")
        XCTAssertTrue(mockRepository.fetchPokemonWasCalled)
    }
}
```

---

## Documentation Requirements

- Update README.md if adding visible features
- Update ARCHITECTURE.md for major architectural changes
- Add inline comments for complex logic
- Update CHANGELOG.md in your PR
- Add DocC comments to public APIs

---

## Before Submitting

- [ ] Code compiles without warnings
- [ ] All tests pass (`⌘ + U`)
- [ ] No new compiler warnings introduced
- [ ] Code follows Swift style guide
- [ ] Documentation is updated
- [ ] Commit messages are clear and descriptive
- [ ] PR is against `develop` branch
- [ ] PR description is clear and complete

---

## Questions or Need Help?

- 📧 Open an [issue](https://github.com/yagodemartin/PokeDex/issues) for questions
- 📖 Read [ARCHITECTURE.md](ARCHITECTURE.md) for architectural details
- 💬 Check existing PRs for examples

---

## License

By contributing to PokéDex, you agree that your contributions will be licensed under the same license as the project.

---

**Thank you for contributing to PokéDex! 🎮**

Last Updated: February 2026

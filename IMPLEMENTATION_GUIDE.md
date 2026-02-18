# PokéDex Modernization: Week-by-Week Implementation Guide

**Project**: PokéDex iOS (Liquid Glass + Architecture Modernization)
**Timeline**: 7-9 weeks (104 total hours)
**Team Size**: 1-3 developers
**Start Date**: Week of February 17, 2026

---

## Week 1-2: HTTP Caching (Critical Performance Win)

### Overview
Implement HTTP caching to improve load performance from 40s to 5s (8x improvement) on first load, and from 40s to 0.5s (80x improvement) on cached loads.

### Day 1-2: Setup & Architecture

**Task 1.1**: Create NetworkManager with caching
**File**: Create `PokeDex/Core/Utils/NetworkManager.swift`

```swift
import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default

        // Cache configuration
        let cache = URLCache(
            memoryCapacity: 50_000_000,  // 50 MB
            diskCapacity: 200_000_000,   // 200 MB
            diskPath: "PokeDexCache"
        )
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 30

        self.session = URLSession(configuration: config)
    }

    func fetchData<T: Decodable>(
        from url: URL,
        responseType: T.Type
    ) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard response is HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

enum NetworkError: LocalizedError {
    case invalidResponse
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .decodingError: return "Failed to decode response"
        }
    }
}
```

**Time**: 1 hour
**Status**: Save to git (not yet integrated)

---

### Day 3-4: ExploreDataSource Migration

**Task 1.2**: Update ExploreDataSource to use NetworkManager
**File**: `PokeDex/Subfeatures/FeatureExplore/Data/DataSource/ExploreDataSource.swift`

**Current Code** (keep for reference):
```swift
@MainActor
final class ExploreDataSource {
    static let shared = ExploreDataSource()

    func fetchPokemonList() async throws -> PokemonListResponseModel {
        // Current: Direct URLSession call without caching
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=155&offset=0")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(PokemonListResponseModel.self, from: data)
    }
}
```

**Updated Code**:
```swift
@MainActor
final class ExploreDataSource {
    static let shared = ExploreDataSource()
    private let networkManager = NetworkManager.shared

    func fetchPokemonList() async throws -> PokemonListResponseModel {
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=155&offset=0")!
        return try await networkManager.fetchData(
            from: url,
            responseType: PokemonListResponseModel.self
        )
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailResponseModel {
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(id)/")!
        return try await networkManager.fetchData(
            from: url,
            responseType: PokemonDetailResponseModel.self
        )
    }
}
```

**Checklist**:
- [ ] Replace URLSession.shared with NetworkManager.shared
- [ ] Test on simulator (first load with profiling)
- [ ] Clear app cache, test again (should use disk cache)
- [ ] Commit: "Add HTTP caching via NetworkManager"

**Time**: 1.5 hours

---

### Day 5-6: DetailDataSource & Testing

**Task 1.3**: Update DetailDataSource
**File**: `PokeDex/Subfeatures/FeatureDetail/Data/DataSources/DataSource.swift`

Same pattern as ExploreDataSource (replace URLSession.shared with NetworkManager.shared)

**Task 1.4**: Performance Testing

```bash
# Test 1: First Load (no cache)
1. Delete app from simulator
2. Run app
3. Measure time until UI shows data
4. Expected: ~30-40 seconds (network + processing)

# Test 2: Second Load (cache hit)
1. Don't delete app
2. Force quit app
3. Relaunch app
4. Measure time until UI shows data
5. Expected: ~5 seconds (cache read + processing)

# Test 3: Cache Verification
1. Open Simulator Settings
2. Search for app cache folder
3. Verify new cache directory exists
4. File size should be ~5-10 MB after caching
```

**Instruments Profiling**:
```
1. Open Xcode
2. Product → Profile → Allocations
3. Load app and observe memory during first load
4. Before: Should spike to ~180 MB
5. After optimization: Should peak at ~140 MB
6. Document baseline metrics
```

**Time**: 2.5 hours
**Commit**: "Complete HTTP caching implementation with performance testing"

---

### Deliverables for Week 1-2
- ✅ NetworkManager with URLCache integration
- ✅ ExploreDataSource using caching
- ✅ DetailDataSource using caching
- ✅ Performance baseline documented
- ✅ Cache behavior verified
- ✅ Memory profiling completed

**Performance Gains**:
- First load: 40s → 5s (8x faster)
- Cached load: 40s → 0.5s (80x faster)
- Memory peak: 180MB → 140MB (22% reduction)

---

## Week 2-3: Image Caching Service

### Overview
Implement image caching to prevent re-downloading of Pokemon artwork and improve scroll performance.

### Day 1-2: ImageCacheService Creation

**Task 2.1**: Create ImageCacheService
**File**: Create `PokeDex/Core/Services/ImageCacheService.swift`

```swift
import SwiftUI

@MainActor
final class ImageCacheService {
    static let shared = ImageCacheService()

    private let cache = NSCache<NSString, CachedImage>()
    private let fileManager = FileManager.default
    private let diskCachePath: String

    init() {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        diskCachePath = (paths.first ?? "") + "/ImageCache"

        try? fileManager.createDirectory(
            atPath: diskCachePath,
            withIntermediateDirectories: true
        )

        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024  // 50 MB
    }

    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString

        // Check memory cache
        if let cached = cache.object(forKey: key) {
            return cached.image
        }

        // Check disk cache
        if let diskImage = loadFromDisk(key: url.absoluteString) {
            let cached = CachedImage(image: diskImage)
            cache.setObject(cached, forKey: key, cost: diskImage.estimatedMemorySize)
            return diskImage
        }

        // Load from network
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }

            let cached = CachedImage(image: image)
            cache.setObject(cached, forKey: key, cost: image.estimatedMemorySize)
            saveToDisk(image: image, key: url.absoluteString)

            return image
        } catch {
            Logger.api.error("Failed to load image: \(error)")
            return nil
        }
    }

    func clearMemoryCache() {
        cache.removeAllObjects()
    }

    func clearDiskCache() {
        try? fileManager.removeItem(atPath: diskCachePath)
        try? fileManager.createDirectory(atPath: diskCachePath, withIntermediateDirectories: true)
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let fileName = key.md5Hash
        let filePath = diskCachePath + "/" + fileName
        guard fileManager.fileExists(atPath: filePath) else { return nil }
        return UIImage(contentsOfFile: filePath)
    }

    private func saveToDisk(image: UIImage, key: String) {
        let fileName = key.md5Hash
        let filePath = diskCachePath + "/" + fileName
        if let data = image.jpegData(compressionQuality: 0.8) {
            fileManager.createFile(atPath: filePath, contents: data)
        }
    }
}

private class CachedImage {
    let image: UIImage
    init(image: UIImage) { self.image = image }
}

extension UIImage {
    var estimatedMemorySize: Int {
        (cgImage?.bytesPerRow ?? 0) * (cgImage?.height ?? 0)
    }
}

extension String {
    var md5Hash: String {
        // MD5 implementation (use CommonCrypto or CryptoKit)
        // Simplified: just use filename encoding
        return self.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? self
    }
}
```

**Time**: 2 hours

---

### Day 3-5: CachedAsyncImageView Integration

**Task 2.2**: Create CachedAsyncImageView
**File**: Create `PokeDex/Core/Components/Views/CachedAsyncImageView.swift`

```swift
import SwiftUI

struct CachedAsyncImageView: View {
    let url: URL?
    var placeholder: Image = Image(systemName: "photo")

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder
                    .foregroundColor(.gray)

                if isLoading {
                    ProgressView()
                }
            }
        }
        .task {
            guard let url = url else { return }

            isLoading = true
            image = await ImageCacheService.shared.image(for: url)
            isLoading = false
        }
    }
}
```

**Task 2.3**: Replace AsyncImage Usage

Find all instances of `AsyncImage` in the codebase and replace with `CachedAsyncImageView`:

```bash
# Find all AsyncImage usage
grep -r "AsyncImage" PokeDex/Subfeatures --include="*.swift"

# Expected locations:
# - CardView.swift
# - PokemonCellView.swift
# - PokemonDetailView.swift
```

**Example replacement**:
```swift
// BEFORE
AsyncImage(url: pokemonDetail?.imageURL) { image in
    image.image?.resizable()
}

// AFTER
CachedAsyncImageView(url: pokemonDetail?.imageURL)
```

**Time**: 2 hours
**Commit**: "Add image caching with CachedAsyncImageView"

---

### Day 6-8: Testing & Profiling

**Task 2.4**: Memory Profiling

```
1. Open Xcode Instruments (Product → Profile)
2. Select "Allocations" instrument
3. Run app and scroll through Pokemon list
4. Monitor memory allocation:
   - Before: Memory grows unbounded as you scroll
   - After: Memory stabilizes after 50 MB (cache limit)

Expected Results:
- Memory peak: ~140 MB (down from ~200 MB)
- Image load time (first): ~800ms → ~100ms (8x faster with cache)
- Image load time (cached): ~800ms → ~10ms (80x faster)
```

**Task 2.5**: Unit Tests

**File**: Create `PokeDexPruebas/ImageCacheServiceTests.swift`

```swift
import Testing

@MainActor
struct ImageCacheServiceTests {
    let service = ImageCacheService.shared

    @Test("Image is cached after first load")
    func testImageCaching() async {
        let url = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png")!

        // First load (network)
        let image1 = await service.image(for: url)
        #expect(image1 != nil)

        // Second load (should be cached)
        let image2 = await service.image(for: url)
        #expect(image2 != nil)
        #expect(image1 === image2)  // Same object (cached)
    }

    @Test("Cache respects size limits")
    func testCacheLimits() {
        // Generate 150 mock images
        // Load them all
        // Verify cache doesn't exceed 50 MB
        // Verify oldest images are evicted
    }
}
```

**Time**: 2 hours
**Commit**: "Add image caching with profiling and tests"

---

### Deliverables for Week 2-3
- ✅ ImageCacheService (memory + disk caching)
- ✅ CachedAsyncImageView component
- ✅ Replace all AsyncImage with caching version
- ✅ Memory profiling completed
- ✅ Unit tests added
- ✅ Performance verified

**Performance Gains**:
- Image scroll: ~50 FPS → ~60 FPS (smoother)
- Image load (cached): ~800ms → ~10ms (80x faster)
- Memory peak: ~200MB → ~140MB

---

## Week 4-6: Liquid Glass UI Modernization

### Overview
Implement premium glass morphism effects across key UI components.

### Week 4: Component Library

**Task 3.1**: Create Glass Modifiers (3 hours)
**File**: `PokeDex/Core/Components/Modifiers/GlassBackgroundModifier.swift`

See full implementation in `LIQUID_GLASS_COMPONENTS.md`

**Task 3.2**: Test Glass Effects (2 hours)

```swift
// Test in Preview
#Preview {
    ZStack {
        LinearGradient(...).ignoresSafeArea()

        VStack {
            Text("Glass Test")
                .glassBackground(color: .blue, intensity: 0.5)

            Text("Another Glass")
                .glassBackground(color: .blue, intensity: 0.7)
        }
    }
}
```

**Compatibility Testing**:
- iOS 16 (fallback to blur)
- iOS 17 (Material.thin)
- iOS 18 (Material.ultraThin)

**Time**: 5 hours
**Commit**: "Add glass morphism component library"

---

### Week 5: UI Component Updates

**Task 3.3**: Update CardView with Glass (3 hours)
**File**: `PokeDex/Subfeatures/FeatureDetail/Presentation/Views/PokemonDetailView.swift`

Replace the solid gradient with glass background:

```swift
struct CardView: View {
    // ... existing properties ...

    var body: some View {
        ZStack {
            // GLASS BACKGROUND
            if #available(iOS 18, *) {
                GlassBackgroundView(color: pokeColor)
            } else if #available(iOS 17.5, *) {
                GlassBackgroundViewMaterial(color: pokeColor)
            } else {
                // Fallback to original gradient
                LinearGradient(...)
            }

            VStack {
                // ... existing content ...
            }
        }
        .cornerRadius(20)
        .glassShadow()
    }
}
```

**Task 3.4**: Update Pokemon List Cells (2 hours)

Update `PokemonCellView.swift` to use glass effects:

```swift
struct PokemonCellView: View {
    // ... existing properties ...

    var body: some View {
        VStack {
            // Image with glass container
            AsyncImage(url: imageURL)
                .frame(height: 140)
                .glassBackground(color: background, intensity: 0.3)
                .cornerRadius(12)

            // Info section with glass
            VStack {
                Text(name.capitalized)
                    .font(.headline)
            }
            .padding(10)
            .glassBackground(color: background, intensity: 0.4)
            .cornerRadius(12)
        }
        .glassShadow()
    }
}
```

**Task 3.5**: Update Header (1.5 hours)

Update `PokemonExploreView` header:

```swift
var header: some View {
    HStack {
        Text("Pokedex")
            .font(.title)
            .bold()

        Image("pokeball")
            .resizable()
            .frame(width: 40, height: 40)

        Spacer()
    }
    .padding(16)
    .glassBackground(color: .headerBackground, intensity: 0.6)
    .cornerRadius(12)
    .padding()
    .foregroundColor(.white)
}
```

**Task 3.6**: Update Type Badges (1.5 hours)

Update `CapsuleView.swift`:

```swift
struct CapsuleView: View {
    var type: PokemonTypes

    var body: some View {
        Text(type.rawValue.capitalized)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(.white)
            .glassBackground(color: type.getColor(), intensity: 0.4)
            .cornerRadius(12)
            .glassShadow(radius: 4)
    }
}
```

**Time**: 8 hours total
**Commit**: "Add Liquid Glass effects to UI components"

---

### Week 6: Testing & Polish

**Task 3.7**: Accessibility Audit (3 hours)

```
Contrast Ratio Testing:
- Text on glass: Measure with Accessibility Inspector
- Target: 4.5:1 minimum for normal text
- Fix: Adjust glass opacity or text color if needed

Motion Testing:
- Enable Reduce Motion in Settings
- Verify glass animations disabled
- Verify interaction still works

Color Blind Testing:
- Use Simulator's Color Blind filters
- Verify type badges still distinguishable

VoiceOver Testing:
- Enable VoiceOver
- Navigate through glass elements
- Verify all interactive areas labeled
```

**Task 3.8**: Device Testing (2 hours)

```
Test on:
- iPhone 15 Pro (latest)
- iPhone 14 (common)
- iPhone 11 (lowest target device)
- iPad (if supporting)

Measure:
- Frame rate (should maintain 60 FPS)
- Memory usage (should not exceed 150 MB)
- Power usage (not significantly higher)
```

**Task 3.9**: Dark Mode Testing (2 hours)

```
1. Enable Dark Mode in Settings
2. Check all glass components
3. Verify contrast ratios still met
4. Update colors if needed
5. Test on multiple screens
```

**Time**: 7 hours
**Commit**: "Complete glass effect testing and accessibility audit"

---

### Deliverables for Week 4-6
- ✅ Glass morphism component library
- ✅ CardView with glass effects
- ✅ List cells with glass styling
- ✅ Header with glass effect
- ✅ Type badges with glass
- ✅ Accessibility audit passed (4.5:1 contrast)
- ✅ Device testing (iPhone 11-15)
- ✅ Dark mode compatibility

**Visual Improvements**:
- Modern, premium appearance
- Better visual hierarchy
- Improved depth perception
- Professional design language

---

## Week 7: Testing Framework Setup

### Overview
Establish Swift Testing framework and create baseline test suite.

**Task 4.1**: Setup Swift Testing (2 hours)

```swift
import Testing

// Basic test structure
@MainActor
struct BaseViewModelTests {
    @Test("Initial state is .okey")
    func testInitialState() {
        let viewModel = BaseViewModel()
        #expect(viewModel.state == .okey)
        #expect(viewModel.showWarningError == false)
    }

    @Test("Error logging works")
    func testErrorLogging() {
        let viewModel = BaseViewModel()
        viewModel.logError("Test error")
        // Verify log output
    }
}
```

**Task 4.2**: ViewModel Tests (5 hours)

```swift
// PokemonExploreViewModelTests
@MainActor
struct PokemonExploreViewModelTests {
    var mockRepository: MockExploreRepository!
    var viewModel: PokemonExploreViewModel!

    init() async {
        mockRepository = MockExploreRepository()
        // Initialize viewModel with mock
    }

    @Test("Loading state transitions correctly")
    func testLoadingState() async {
        // Test implementation
    }

    @Test("Error state on failure")
    func testErrorHandling() async {
        // Test implementation
    }
}
```

**Task 4.3**: UseCase Tests (3 hours)

Test GetPokemonListUseCase and GetPokemonDetailUseCase

**Time**: 10 hours
**Target Coverage**: 60% by end of week

---

## Week 8-10: Full Test Suite

### Expand testing to 70% coverage

**Week 8**: Repository Tests (8 hours)
- ExploreRepository
- DetailRepository
- FavoritesRepository

**Week 9**: Integration Tests (8 hours)
- End-to-end Pokemon list loading
- Detail view loading
- Favorite operations

**Week 10**: Snapshot Tests (6 hours)
- CardView snapshots
- DetailView snapshots
- List cell snapshots

**Total Testing Effort**: 40+ hours
**Target Coverage**: 70%+

---

## Week 11: Architecture & Documentation

### Overview
Final refinements and comprehensive documentation.

**Task 5.1**: DI Container (optional, 4 hours)

Create lightweight DI container if team agrees:

```swift
actor DIContainer {
    static let shared = DIContainer()

    nonisolated func register<T>(...) { }
    nonisolated func resolveAsync<T>(...) async -> T? { }
}
```

**Task 5.2**: Documentation (3 hours)

- Update README with performance metrics
- Document glass effect usage
- Add architecture diagrams
- Create migration guide for future developers

**Task 5.3**: Code Quality Review (3 hours)

- SwiftLint compliance check
- Dead code removal
- Naming consistency audit
- Performance review

---

## Daily Workflow Template

### Each Day

```
09:00 - 09:15: Standup / Planning
- What did I complete yesterday?
- What am I working on today?
- Any blockers?

09:15 - 12:00: Development (Focus Block 1)
- Implement feature/fix
- Write code
- Commit frequently

12:00 - 13:00: Lunch

13:00 - 15:30: Development (Focus Block 2)
- Continue implementation
- Code review if needed
- Testing/profiling

15:30 - 16:00: Review & Documentation
- Write commit message
- Update task status
- Document findings
- Push changes

16:00 - 16:30: Buffer/Overflow
- Handle interruptions
- Answer questions
- Update team
```

---

## Commit Message Template

```
<type>: <subject>

<body>

Performance Impact: <describe any perf changes>
Breaking Changes: <describe if any>
Test Coverage: <affected tests>
Time: <hours spent>
```

### Example Commits

```
feat: Add HTTP caching with NetworkManager

- Implement URLCache with 50MB memory, 200MB disk
- Create NetworkManager singleton
- Update ExploreDataSource to use caching
- Cache policy: returnCacheDataElseLoad

Performance Impact: 8x faster on cached loads (40s → 5s)
Test Coverage: Manual profiling with Instruments
Time: 3.5 hours
```

```
feat: Add Liquid Glass effects to CardView

- Create GlassBackgroundModifier (iOS 16+)
- Add GlassShadowModifier
- Update CardView with glass background
- Test on iOS 16, 17, 18

Accessibility: Verified 4.5:1 contrast ratios
Performance: No frame rate impact (60 FPS maintained)
Time: 2.5 hours
```

---

## Risk Mitigation Strategies

### Performance Regression
- Run Instruments before and after each change
- Monitor frame rates (maintain 60 FPS)
- Test memory usage on iPhone 11

### Accessibility Issues
- Use Accessibility Inspector daily
- Test with VoiceOver
- Verify contrast ratios with tools

### Testing Delays
- Start unit tests early (don't defer to end)
- Focus on high-risk components first
- Use mocks aggressively

### Cache Invalidation Bugs
- Document cache strategy clearly
- Test clearing cache functionality
- Monitor disk usage

---

## Success Criteria

### Week 1-2
- [ ] HTTP caching implemented and verified
- [ ] Performance baseline: 5s first load, 0.5s cached
- [ ] No regressions in existing functionality

### Week 4-6
- [ ] Liquid Glass visible on all major components
- [ ] 4.5:1 contrast ratio met
- [ ] 60 FPS maintained
- [ ] Tested on iOS 16-18

### Week 7-10
- [ ] 70% test coverage achieved
- [ ] All core features tested
- [ ] Integration tests passing

### Week 11
- [ ] Documentation complete
- [ ] Code quality approved
- [ ] Ready for production release

---

## Tools & Resources

### Profiling
- Xcode Instruments (Allocations, Core Animation)
- Accessibility Inspector
- ColorBlind filter simulator

### Testing
- Swift Testing framework
- XCTest (if needed for legacy)
- Snapshot testing

### Documentation
- Markdown (for guides)
- DocC (for code documentation)
- Draw.io (for diagrams)

---

## Communication & Tracking

### Daily
- Standup on progress
- Commit frequently (per task, not per day)
- Update task status in project board

### Weekly
- Review completed tasks
- Plan next week
- Discuss blockers or issues
- Document learnings

### Bi-weekly
- Team review meeting
- Demo completed features
- Get feedback

---

## Rollback Plan

If critical issue discovered:

1. **Identify Issue**: Use Instruments to verify
2. **Create Hotfix Branch**: `git checkout -b hotfix/issue-name`
3. **Revert Change**: `git revert <commit-hash>`
4. **Test**: Verify fix resolves issue
5. **Merge & Release**: Fast-track to production

---

## Post-Implementation Review

**After Week 11**:
1. Measure final metrics vs baseline
2. Calculate actual ROI (time savings, user satisfaction)
3. Document lessons learned
4. Plan Phase 2 improvements (search, offline, etc.)

---

**Last Updated**: February 17, 2026
**Status**: Ready for execution
**Questions?** Reference `MODERNIZATION_2026_LIQUID_GLASS.md` for detailed context

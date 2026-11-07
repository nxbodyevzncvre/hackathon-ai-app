import SwiftUI
import SwiftData

/// Owns the app's object graph: settings, store, repository. Screens read it
/// via `@Environment(AppEnvironment.self)`. Grows further in later milestones.
@MainActor
@Observable
final class AppEnvironment {
    let settings: SettingsStore
    /// Kept alive for the lifetime of the environment: releasing the
    /// container while contexts exist crashes SwiftData.
    private let container: ModelContainer?
    /// `nil` only if SwiftData could not be created at all; UI degrades to an
    /// honest message instead of crashing.
    let repository: ActionRepository?
    /// Set when storage fell back to memory-only (nothing survives launch).
    private(set) var storageNotice: String?

    init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
        if let storage = Self.makeStorage() {
            self.container = storage.container
            repository = ActionRepository(container: storage.container)
            if !storage.persistedOnDisk {
                storageNotice = "Local database unavailable in this session. "
                    + "Anything you save now is kept in memory only and won't survive a relaunch."
            }
        } else {
            container = nil
            repository = nil
        }
        seedDebugFixturesIfNeeded()
    }

    // MARK: - Storage

    private struct StorageResult {
        let container: ModelContainer
        let persistedOnDisk: Bool
    }

    static var databaseURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Autopilot.store")
    }

    private static func makeStorage() -> StorageResult? {
        let schema = Schema(versionedSchema: SchemaV1.self)

        let onDisk = ModelConfiguration(schema: schema, url: databaseURL)
        if let container = try? ModelContainer(
            for: schema,
            migrationPlan: AutopilotMigrationPlan.self,
            configurations: [onDisk]
        ) {
            return StorageResult(container: container, persistedOnDisk: true)
        }

        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(
            for: schema,
            migrationPlan: AutopilotMigrationPlan.self,
            configurations: [inMemory]
        ) {
            return StorageResult(container: container, persistedOnDisk: false)
        }
        return nil
    }

    /// Debug/demo fixtures seed exactly once, only in DEBUG builds.
    private func seedDebugFixturesIfNeeded() {
        guard let repository else { return }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-autopilot-no-seed") { return }
        do {
            _ = try FixtureSeeder.seedIfNeeded(in: repository, fixtures: Fixtures.all())
        } catch {
            storageNotice = "Fixtures could not be seeded: \(type(of: error))."
        }
        #endif
    }
}

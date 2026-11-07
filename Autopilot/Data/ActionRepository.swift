import Foundation
import SwiftData
import Observation

/// The only gateway between views and SwiftData. Views see `Action` value
/// types exclusively. Mutations call `context.save()` explicitly so nothing
/// depends on implicit autosave semantics. `@Observable` lets screens read
/// it via `@Environment(ActionRepository.self)`.
@MainActor
@Observable
final class ActionRepository {
    /// Kept alive: releasing the SwiftData container while contexts reference
    /// it crashes (reports store with EXC_BREAKPOINT).
    private let container: ModelContainer
    private let context: ModelContext

    init(container: ModelContainer, context: ModelContext? = nil) {
        self.container = container
        self.context = context ?? container.mainContext
    }

    // MARK: - Queries

    func actions() throws -> [Action] {
        let descriptor = FetchDescriptor<ActionRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.actionValue)
    }

    func action(id: UUID) throws -> Action? {
        try firstRecord(id: id)?.actionValue
    }

    /// Number of stored actions; used by seeding and empty states.
    func count() throws -> Int {
        try context.fetchCount(FetchDescriptor<ActionRecord>())
    }

    func isEmpty() throws -> Bool {
        try count() == 0
    }

    // MARK: - Mutations

    func create(_ action: Action) throws {
        context.insert(ActionRecord(from: action))
        try context.save()
    }

    func update(_ action: Action) throws {
        guard let record = try firstRecord(id: action.id) else { return }
        record.apply(action)
        try context.save()
    }

    func delete(id: UUID) throws {
        if let record = try firstRecord(id: id) {
            context.delete(record)
            try context.save()
        }
    }

    /// Marks every matching record cancelled without touching others.
    func cancelAll(ids: [UUID]) throws {
        for id in ids {
            if let record = try firstRecord(id: id) {
                record.statusRaw = ActionStatus.cancelled.rawValue
            }
        }
        try context.save()
    }

    // MARK: - Private

    private func firstRecord(id: UUID) throws -> ActionRecord? {
        var descriptor = FetchDescriptor<ActionRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

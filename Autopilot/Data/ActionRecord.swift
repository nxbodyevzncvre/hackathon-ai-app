import Foundation
import SwiftData

/// SwiftData storage for one action. `due` is flattened into four primitive
/// columns so predicates and sorts stay queryable (§6 of the brief).
/// Only `ActionRepository` may touch this type.
@Model
final class ActionRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var kindRaw: String
    var categoryRaw: String
    var priorityRaw: Int
    var statusRaw: String
    var dueDate: Date?
    var dueTime: Date?
    var duePrecisionRaw: String
    var dueIsExplicit: Bool
    var estimateMinutes: Int?
    var reminderOffsetsText: String?
    var reminderEnabled: Bool
    var sourceQuote: String
    var confidence: Double
    var createdAt: Date
    var completedAt: Date?

    init(from action: Action) {
        id = action.id
        title = action.title
        notes = action.notes
        kindRaw = action.kind.rawValue
        categoryRaw = action.category
        priorityRaw = action.priority.rawValue
        statusRaw = action.status.rawValue
        dueDate = action.due?.date
        dueTime = action.due?.time
        duePrecisionRaw = action.due?.precision.rawValue ?? DueDate.Precision.unknown.rawValue
        dueIsExplicit = action.due?.isExplicit ?? false
        estimateMinutes = action.estimateMinutes
        reminderOffsetsText = Self.encodeOffsets(action.reminder.offsets)
        reminderEnabled = action.reminder.isEnabled
        sourceQuote = action.sourceQuote
        confidence = action.confidence
        createdAt = action.createdAt
        completedAt = action.completedAt
    }

    func apply(_ action: Action) {
        title = action.title
        notes = action.notes
        kindRaw = action.kind.rawValue
        categoryRaw = action.category
        priorityRaw = action.priority.rawValue
        statusRaw = action.status.rawValue
        dueDate = action.due?.date
        dueTime = action.due?.time
        duePrecisionRaw = action.due?.precision.rawValue ?? DueDate.Precision.unknown.rawValue
        dueIsExplicit = action.due?.isExplicit ?? false
        estimateMinutes = action.estimateMinutes
        reminderOffsetsText = Self.encodeOffsets(action.reminder.offsets)
        reminderEnabled = action.reminder.isEnabled
        sourceQuote = action.sourceQuote
        confidence = action.confidence
        createdAt = action.createdAt
        completedAt = action.completedAt
    }

    /// Rebuilds the domain value type. A stored date keeps its explicitness so
    /// a later capture flow can store suggested (non-explicit) dates too.
    var actionValue: Action {
        let due: DueDate?
        if let storedDate = dueDate {
            due = DueDate(
                date: storedDate,
                time: dueTime,
                precision: DueDate.Precision(rawValue: duePrecisionRaw) ?? .day,
                isExplicit: dueIsExplicit
            )
        } else {
            due = nil
        }
        var rebuilt = Action(
            id: id,
            title: title,
            notes: notes,
            kind: ActionKind(rawValue: kindRaw) ?? .task,
            category: categoryRaw,
            priority: Priority(rawValue: priorityRaw) ?? .normal,
            due: due,
            status: ActionStatus(rawValue: statusRaw) ?? .inbox,
            estimateMinutes: estimateMinutes,
            reminder: ReminderRule(
                offsets: Self.decodeOffsets(reminderOffsetsText),
                isEnabled: reminderEnabled
            ),
            sourceQuote: sourceQuote,
            confidence: min(max(confidence, 0), 1),
            createdAt: createdAt,
            completedAt: completedAt
        )
        return rebuilt
    }

    /// SwiftData cannot materialize `Array<Double>` attributes on this SDK
    /// (CoreData "Could not materialize Array"), so offsets are CSV text.
    private static func encodeOffsets(_ offsets: [TimeInterval]) -> String {
        offsets.map { String($0) }.joined(separator: ",")
    }

    private static func decodeOffsets(_ text: String?) -> [TimeInterval] {
        text?
            .split(separator: ",")
            .compactMap { Double($0) }
            ?? []
    }
}

/// SwiftData schema history. Version 1 is the only version today; later
/// versions append here plus explicit migration stages.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ActionRecord.self] }
}

enum AutopilotMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

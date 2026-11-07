import Foundation

/// Fixed category list the extraction prompt must choose from. Stored on
/// `Action` as the raw string so unknown values degrade to `.other`.
enum ActionCategory: String, Codable, CaseIterable, Hashable {
    case university, work, personal, health, finance, admin, other

    static let fixed: [ActionCategory] = allCases

    var displayName: String {
        switch self {
        case .university: "University"
        case .work: "Work"
        case .personal: "Personal"
        case .health: "Health"
        case .finance: "Finance"
        case .admin: "Admin"
        case .other: "Other"
        }
    }

    static func normalized(_ raw: String) -> ActionCategory {
        ActionCategory(rawValue: raw.lowercased()) ?? .other
    }
}

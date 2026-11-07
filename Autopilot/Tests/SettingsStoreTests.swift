import XCTest
@testable import Autopilot

@MainActor
final class SettingsStoreTests: XCTestCase {
    private func makeDefaults(name: String) throws -> UserDefaults {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name), "solo test suite must exist")
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testDefaultsMatchTheBrief() throws {
        let store = SettingsStore(defaults: try makeDefaults(name: "defaults-check"))
        XCTAssertEqual(store.workdayStartMinutes, 540)
        XCTAssertEqual(store.workdayEndMinutes, 1020)
        XCTAssertEqual(store.dailyCapacityMinutes, 180)
        XCTAssertEqual(store.briefingMinutes, 480)
        XCTAssertEqual(store.quietStartMinutes, 1320)
        XCTAssertEqual(store.quietEndMinutes, 480)
        XCTAssertEqual(store.notificationsEnabled, false)
    }

    func testValuesPersistAcrossInstances() throws {
        let defaults = try makeDefaults(name: "persistence-check")
        let store = SettingsStore(defaults: defaults)
        store.dailyCapacityMinutes = 240
        store.workdayStartMinutes = 480
        store.briefingMinutes = 540
        store.notificationsEnabled = true
        store.persist()

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.dailyCapacityMinutes, 240)
        XCTAssertEqual(reloaded.workdayStartMinutes, 480)
        XCTAssertEqual(reloaded.briefingMinutes, 540)
        XCTAssertTrue(reloaded.notificationsEnabled)
    }
}

import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackerTests: XCTestCase {

    func testTabBarController() {
        let vc = TabBarController()

        assertSnapshot(matching: vc, as: .image)
    }

    func testTrackersListViewController() {
        let vc = TrackersListViewController()
        assertSnapshot(matching: vc, as: .image(on: .iPhone13Mini(.landscape)))
    }
}

import UIKit

final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let trackersListViewController = TrackersListViewController()
        let statisticsViewController = StatisticsViewController()

        trackersListViewController.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(resource: .tabTrackers),
            selectedImage: nil
        )
        statisticsViewController.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(resource: .tabStats),
            selectedImage: nil
        )
        self.viewControllers = [trackersListViewController, statisticsViewController]
    }
}

import UIKit

final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let trackersVC = TrackersListViewController()
        let statsVC = StatisticsViewController()

        let trackersNav = UINavigationController(rootViewController: trackersVC)
        let statsNav = UINavigationController(rootViewController: statsVC)

        trackersNav.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(resource: .tabTrackers),
            selectedImage: nil
        )
        statsNav.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(resource: .tabStats),
            selectedImage: nil
        )
        viewControllers = [trackersNav, statsNav]
    }
}

import UIKit

final class TabBarController: UITabBarController {

    private var onboardIsShowed = false

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

        configureUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !onboardIsShowed {
            let onboardVC = OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
            onboardVC.modalPresentationStyle = .fullScreen
            present(onboardVC, animated: true)
            onboardIsShowed.toggle()
        }
    }

    private func configureUI() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowColor = .separator
        tabBar.scrollEdgeAppearance = appearance
    }
}

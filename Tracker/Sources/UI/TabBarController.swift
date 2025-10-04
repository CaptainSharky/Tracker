import UIKit

final class TabBarController: UITabBarController {

    private var onboardingStorage = AppLaunchStorage()

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

        //UserDefaults.standard.removeObject(forKey: "onboarding.hasCompleted")

        guard !onboardingStorage.hasCompletedOnboarding,
              presentedViewController == nil else { return }

        let onboardVC = OnboardingViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        onboardVC.modalPresentationStyle = .fullScreen
        onboardVC.onFinish = { [weak self] in
            self?.onboardingStorage.hasCompletedOnboarding = true
        }

        present(onboardVC, animated: true)
    }

    private func configureUI() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowColor = .separator
        tabBar.scrollEdgeAppearance = appearance
    }
}

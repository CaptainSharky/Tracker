import UIKit

final class TabBarController: UITabBarController {

    // MARK: - Private propeties
    private var onboardingStorage = AppLaunchStorage()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabs()
        configureUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showOnboardingIfNeeded()
    }

    // MARK: - Private methods

    private func setupTabs() {
        let trackersVC = TrackersListViewController()
        let statsVC = StatisticsViewController()

        let trackersNav = UINavigationController(rootViewController: trackersVC)
        let statsNav = UINavigationController(rootViewController: statsVC)

        trackersNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("trackers", comment: "TabBar trackers tab"),
            image: UIImage(resource: .tabTrackers),
            selectedImage: nil
        )
        statsNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("statistics", comment: "TabBar statistics tab"),
            image: UIImage(resource: .tabStats),
            selectedImage: nil
        )
        viewControllers = [trackersNav, statsNav]
    }

    private func configureUI() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowColor = .separator
        appearance.backgroundColor = UIColor(resource: .ypWhiteDay)
        tabBar.scrollEdgeAppearance = appearance
    }

    private func showOnboardingIfNeeded() {
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
}

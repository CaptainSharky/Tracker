import UIKit

final class OnboardingViewController: UIPageViewController {

    // MARK: - UI Properties

    lazy var pages: [PageViewController] = {
        let blue = PageViewController()
        let red = PageViewController()
        blue.configurePage(text: Constants.blueOnboardText, image: UIImage(resource: .onboardBlue))
        red.configurePage(text: Constants.redOnboardText, image: UIImage(resource: .onboardRed))
        return [blue, red]
    }()

    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = .systemBackground
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        pageControl.allowsContinuousInteraction = true
        return pageControl
    }()

    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle(Constants.buttonText, for: .normal)
        button.titleLabel?.font = Constants.font
        button.layer.cornerRadius = Constants.cornerRadius
        button.backgroundColor = UIColor(resource: .ypBlackDay)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }

        layoutUI()
    }

    // MARK: - Private methods

    private func layoutUI() {
        view.addSubview(pageControl)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            button.heightAnchor.constraint(equalToConstant: 60),
            pageControl.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -24),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Actions
    @objc
    private func pageControlChanged(_ sender: UIPageControl) {
        let newIndex = sender.currentPage

        guard
            let current = viewControllers?.first as? PageViewController,
            let currentIndex = pages.firstIndex(of: current),
            pages.indices.contains(newIndex)
        else { return }

        let direction: UIPageViewController.NavigationDirection = newIndex >= currentIndex ? .forward : .reverse

        setViewControllers([pages[newIndex]], direction: direction, animated: false, completion: nil)
    }

    @objc
    private func buttonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UIPageViewControllerDataSource protocol

extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? PageViewController,
              let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else {
            return nil
        }

        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? PageViewController,
              let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }

        let nextIndex = viewControllerIndex + 1

        guard nextIndex < pages.count else {
            return nil
        }

        return pages[nextIndex]
    }
}

// MARK: - UIPageViewControllerDelegate protocol

extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentViewController = pageViewController.viewControllers?.first as? PageViewController,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
        }
    }
}

extension OnboardingViewController {
    private enum Constants {
        static let font: UIFont = .systemFont(ofSize: 16)
        static let cornerRadius: CGFloat = 16
        static let blueOnboardText: String = "Отслеживайте только то, что хотите"
        static let redOnboardText: String = "Даже если это не литры воды и йога"
        static let buttonText: String = "Вот это технологии!"
    }
}

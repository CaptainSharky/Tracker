import UIKit

final class StatisticsViewController: UIViewController {

    private let statsProvider = StatisticsProvider()
    private var stats: Statistics = .zero {
        didSet {
            isStatisticsEmpty = stats.isEmpty
            statisticsTableView.reloadData()
        }
    }
    private var isStatisticsEmpty: Bool = true {
        didSet {
            stubImage.isHidden = !isStatisticsEmpty
            stubLabel.isHidden = !isStatisticsEmpty
            statisticsTableView.isHidden = isStatisticsEmpty
            if isStatisticsEmpty {
                view.bringSubviewToFront(stubImage)
                view.bringSubviewToFront(stubLabel)
            }
        }
    }

    // MARK: - UI properties
    private let stubImage: UIImageView = {
        let image = UIImageView(image: UIImage(resource: .stubStats))
        image.contentMode = .scaleAspectFit
        return image
    }()

    private let stubLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.stubLabelText
        label.font = .systemFont(ofSize: Constants.stubLabelFontSize)
        label.textAlignment = .center
        return label
    }()

    private lazy var statisticsTableView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(StatisticsViewCell.self, forCellWithReuseIdentifier: "statisticsCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.layer.cornerRadius = Constants.cornerRadius
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = UIColor(resource: .ypWhiteDay)
        return collectionView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("statistics", comment: "Statistic view title")
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = UIColor(resource: .ypWhiteDay)

        layoutUI()
        reloadStats()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidChange),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadStats()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private methods
    private func reloadStats() {
        stats = (try? statsProvider.compute()) ?? .zero
    }

    private func layoutUI() {
        [stubImage, stubLabel, statisticsTableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            stubImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stubImage.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stubImage.heightAnchor.constraint(equalToConstant: 80),
            stubImage.widthAnchor.constraint(equalToConstant: 80),

            stubLabel.topAnchor.constraint(equalTo: stubImage.bottomAnchor, constant: 8),
            stubLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            statisticsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statisticsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statisticsTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            statisticsTableView.heightAnchor.constraint(equalToConstant: 396)
        ])
    }

    @objc
    private func contextDidChange() {
        reloadStats()
    }
}

// MARK: - UICollectionViewDataSource protocol
extension StatisticsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        StatisticsRow.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "statisticsCell",
                for: indexPath
            ) as? StatisticsViewCell,
            let row = StatisticsRow(rawValue: indexPath.row)
        else {
            return UICollectionViewCell()
        }

        let number: Int
        switch row {
        case .bestStreak:
            number = stats.bestStreak
        case .perfectDays:
            number = stats.perfectDays
        case .trackersCompleted:
            number = stats.totalCompletions
        case .average:
            number = stats.averagePerDay
        }

        cell.configureCell(number: number, title: row.title)

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout protocol
extension StatisticsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: Constants.cvRowHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.cvInteritemSpace
    }
}

extension StatisticsViewController {
    private enum Constants {
        static let stubLabelText: String = "Анализировать пока нечего"
        static let stubLabelFontSize: CGFloat = 12
        static let cornerRadius: CGFloat = 16
        static let cvRowHeight: CGFloat = 90
        static let cvInteritemSpace: CGFloat = 12
    }

    private enum StatisticsRow: Int, CaseIterable {
        case bestStreak
        case perfectDays
        case trackersCompleted
        case average

        var title: String {
            switch self {
            case .bestStreak:
                return "Лучший период"
            case .perfectDays:
                return "Идеальные дни"
            case .trackersCompleted:
                return "Трекеров завершено"
            case .average:
                return "Среднее значение"
            }
        }
    }
}

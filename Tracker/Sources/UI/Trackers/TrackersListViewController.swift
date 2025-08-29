import UIKit

final class TrackersListViewController: UIViewController {
    private var categories: [TrackerCategory] = [] {
        didSet {
            isTrackersEmpty = categories.isEmpty
        }
    }
    private var completedTrackers: [TrackerRecord] = []
    private var isTrackersEmpty: Bool = true {
        didSet {
            stubImage.isHidden = !isTrackersEmpty
            stubLabel.isHidden = !isTrackersEmpty
            if isTrackersEmpty {
                view.bringSubviewToFront(stubImage)
                view.bringSubviewToFront(stubLabel)
            }
        }
    }

    // MARK: - UI properties
    private var selectedDate: Date {
        Calendar.current.startOfDay(for: datePicker.date)
    }
    private let searchField = UISearchTextField()
    private let stubImage = UIImageView(image: UIImage(resource: .stubStar))
    private let stubLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()

    private let datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        return datePicker
    }()

    private lazy var datePickerButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: datePicker)
    }()

    private lazy var addButton: UIBarButtonItem = {
        let plusButton = UIBarButtonItem(
            image: UIImage(resource: .addTracker),
            style: .plain,
            target: self,
            action: #selector(addTrackerTapped)
        )
        return plusButton
    }()

    private lazy var trackersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TrackerViewCell.self, forCellWithReuseIdentifier: TrackerViewCell.cellIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavBar()
        configureUI()
        layoutUI()

        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        isTrackersEmpty = true

        addTracker(Tracker(title: "Поливать растения", color: UIColor(resource: .CS_18), emoji: "😪"), to: "Test")
        addTracker(Tracker(title: "Бокс", color: UIColor(resource: .CS_8), emoji: "🥊"), to: "Test")
        addTracker(Tracker(title: "Программировать", color: UIColor(resource: .CS_10), emoji: "💻"), to: "Test")
    }

    // MARK: - Public methods
    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        var newCategories = categories

        if let index = newCategories.firstIndex(where: { $0.title == categoryTitle }) {
            var trackers = newCategories[index].trackers
            trackers.append(tracker)
            newCategories[index] = TrackerCategory(title: categoryTitle, trackers: trackers)
        } else {
            let newCategory = TrackerCategory(title: categoryTitle, trackers: [tracker])
            newCategories.append(newCategory)
        }
        categories = newCategories

        isTrackersEmpty = categories.isEmpty

    }

    func toggleTracker(_ tracker: Tracker) {
        let record = TrackerRecord(trackerID: tracker.id, date: selectedDate)
        if let index = completedTrackers.firstIndex(of: record) {
            completedTrackers.remove(at: index)
        } else {
            completedTrackers.append(record)
        }

    }

    func isTrackerCompleted(_ tracker: Tracker) -> Bool {
        completedTrackers.contains { $0.trackerID == tracker.id && $0.date == selectedDate }
    }

    // MARK: - Private methods
    @objc
    private func dateChanged() { }

    private func configureNavBar() {
        title = "Трекеры"

        navigationItem.leftBarButtonItem = addButton
        navigationItem.leftBarButtonItem?.tintColor = .ypBlackDay
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = datePickerButton
    }

    private func configureUI() {
        view.backgroundColor = UIColor(resource: .ypWhiteDay)

        searchField.placeholder = "Поиск"
        searchField.backgroundColor = UIColor(resource: .ypSearchFieldBackground)

        stubImage.contentMode = .scaleAspectFit
    }

    private func layoutUI() {
        [searchField, stubImage, stubLabel, trackersCollectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        addButton.imageInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 36),

            stubImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stubImage.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            stubLabel.topAnchor.constraint(equalTo: stubImage.bottomAnchor, constant: 8),
            stubLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            trackersCollectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 24),
            trackersCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            trackersCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            trackersCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Actions
    @objc
    private func addTrackerTapped() {
        let newHabitViewController = NewHabitViewController()
        present(newHabitViewController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource protocol
extension TrackersListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if categories.isEmpty { return 0 }
        return categories[section].trackers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tracker = categories[indexPath.section].trackers[indexPath.row]

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerViewCell.cellIdentifier,
            for: indexPath
        ) as? TrackerViewCell else {
            return UICollectionViewCell()
        }

        cell.configureCell(tracker: tracker, completedDays: 2, isCompleted: isTrackerCompleted(tracker), currentDate: selectedDate)

        cell.onTap = { [weak self] record in
            guard let self else { return }

            if let index = self.completedTrackers.firstIndex(of: record) {
                self.completedTrackers.remove(at: index)
            } else {
                self.completedTrackers.append(record)
            }
            print(completedTrackers)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout protocol
extension TrackersListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.bounds.width - 16 * 2 - 9) / 2, height: 148)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
}

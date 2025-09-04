import UIKit

final class TrackersListViewController: UIViewController {
    private var completedTrackers: [TrackerRecord] = []
    private var completedIndex: [Date: Set<UUID>] = [:]
    private var completionCountByTracker: [UUID: Int] = [:]

    private var categories: [TrackerCategory] = [] {
        didSet {
            isTrackersEmpty = categories.isEmpty
        }
    }

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
    private var selectedDate: Date {
        Calendar.current.startOfDay(for: datePicker.date)
    }
    private var selectedWeekday: Weekday {
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        return Weekday(rawValue: weekday) ?? .monday
    }
    private var filteredCategories: [TrackerCategory] {
        categories.compactMap { category in
            let filtered = category.trackers.filter { $0.schedule.contains(selectedWeekday) }
            return filtered.isEmpty ? nil : TrackerCategory(title: category.title, trackers: filtered)
        }
    }

    // MARK: - UI properties
    private let searchField: UISearchTextField = {
        let searchField = UISearchTextField()
        searchField.placeholder = "Поиск"
        searchField.backgroundColor = UIColor(resource: .ypSearchFieldBackground)
        searchField.returnKeyType = .done
        return searchField
    }()

    private let stubImage: UIImageView = {
        let image = UIImageView(image: UIImage(resource: .stubStar))
        image.contentMode = .scaleAspectFit
        return image
    }()

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
        collectionView.register(CategoryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CategoryView.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavBar()
        layoutUI()

        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        searchField.delegate = self
        view.backgroundColor = UIColor(resource: .ypWhiteDay)
        isTrackersEmpty = true

        addTracker(Tracker(title: "Поливать растения", color: UIColor(resource: .CS_18), emoji: "😪", schedule: Set(arrayLiteral: .monday, .tuesday, .thursday)), to: "Домашний уют")
        addTracker(Tracker(title: "Бокс", color: UIColor(resource: .CS_8), emoji: "🥊", schedule: Set(arrayLiteral: .wednesday, .thursday, .friday)), to: "Спорт")
        addTracker(Tracker(title: "Программировать", color: UIColor(resource: .CS_10), emoji: "💻", schedule: Set(arrayLiteral: .saturday, .sunday)), to: "Хобби")

        dateChanged()
    }

    // MARK: - Private methods
    private func addTracker(_ tracker: Tracker, to categoryTitle: String) {
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
        updateEmptyState()
    }

    private func isTrackerCompleted(_ tracker: Tracker) -> Bool {
        completedIndex[selectedDate]?.contains(tracker.id) ?? false
    }

    private func updateEmptyState() {
        let totalVisible = filteredCategories.reduce(0) { $0 + $1.trackers.count }
        isTrackersEmpty = (totalVisible == 0)
    }

    private func toggleRecord(_ record: TrackerRecord) {
        let day = record.date
        let id  = record.trackerID

        if completedIndex[day]?.contains(id) == true {
            completedIndex[day]?.remove(id)
            if completedIndex[day]?.isEmpty == true {
                completedIndex.removeValue(forKey: day)
            }
            if let index = completedTrackers.firstIndex(of: record) {
                completedTrackers.remove(at: index)
            }
            if let count = completionCountByTracker[id], count > 0 {
                completionCountByTracker[id] = count - 1
            }
        } else {
            completedIndex[day, default: []].insert(id)
            completedTrackers.append(record)
            completionCountByTracker[id, default: 0] += 1
        }
    }

    private func configureNavBar() {
        title = "Трекеры"
        navigationItem.leftBarButtonItem = addButton
        navigationItem.leftBarButtonItem?.tintColor = .ypBlackDay
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = datePickerButton
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
        newHabitViewController.create = { [weak self] tracker in
            self?.addTracker(tracker, to: "Test")
            self?.trackersCollectionView.reloadData()
        }
        present(newHabitViewController, animated: true)
    }

    @objc
    private func dateChanged() {
        updateEmptyState()
        trackersCollectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource protocol
extension TrackersListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredCategories[section].trackers.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        filteredCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tracker = filteredCategories[indexPath.section].trackers[indexPath.row]
        let doneCount = completionCountByTracker[tracker.id] ?? 0

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerViewCell.cellIdentifier,
            for: indexPath
        ) as? TrackerViewCell else {
            return UICollectionViewCell()
        }

        cell.configureCell(
            tracker: tracker,
            completedDays: doneCount,
            isCompleted: isTrackerCompleted(tracker),
            currentDate: selectedDate
        )

        cell.onTap = { [weak self] record in
            guard let self else { return }
            self.toggleRecord(record)
            self.trackersCollectionView.reloadItems(at: [indexPath])
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout protocol
extension TrackersListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.bounds.width - 41) / 2, height: 148)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    // MARK: Supplementary View (Header)
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: CategoryView.identifier,
            for: indexPath
        ) as? CategoryView else {
            return UICollectionReusableView()
        }
        let title = filteredCategories[indexPath.section].title
        view.configure(title: title)
        return view
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 40)
    }
}

extension TrackersListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

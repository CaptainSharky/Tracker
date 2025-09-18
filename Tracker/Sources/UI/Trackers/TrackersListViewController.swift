import UIKit

final class TrackersListViewController: UIViewController {
    private let trackerStore = TrackerStore()
    private let recordStore = TrackerRecordStore()
    private var dataProvider: TrackersDataProviderProtocol = TrackersDataProvider()

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
        label.font = .systemFont(ofSize: Constants.stubLabelFontSize)
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

        dataProvider.onChange = { [weak self] in
            guard let self else { return }
            self.updateEmptyState()
            self.trackersCollectionView.reloadData()
        }

        try? dataProvider.performFetch(filter: .init(weekday: selectedWeekday, search: nil))
        updateEmptyState()
    }

    // MARK: - Private methods
    private func isTrackerCompleted(_ tracker: Tracker) -> Bool {
        (try? recordStore.isCompleted(trackerID: tracker.id, on: selectedDate)) ?? false
    }

    private func updateEmptyState() {
        var total = 0
        let sections = dataProvider.numberOfSections()
        for s in 0..<sections { total += dataProvider.numberOfItems(in: s) }
        isTrackersEmpty = (total == 0)
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

        addButton.imageInsets = Constants.addButtonInsets

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
            try? self?.trackerStore.create(tracker, inCategory: "Test")
        }
        present(newHabitViewController, animated: true)
    }

    @objc
    private func dateChanged() {
        try? dataProvider.performFetch(filter: .init(weekday: selectedWeekday, search: searchField.text))
    }
}

// MARK: - UICollectionViewDataSource protocol
extension TrackersListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataProvider.numberOfItems(in: section)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        dataProvider.numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tracker = dataProvider.tracker(at: indexPath)
        let doneCount = (try? recordStore.completionCount(trackerID: tracker.id)) ?? 0

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
            try? self.recordStore.toggle(trackerID: record.trackerID, on: self.selectedDate)
            self.trackersCollectionView.reloadItems(at: [indexPath])
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout protocol
extension TrackersListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.bounds.width - Constants.cvInsets * 2 - Constants.cvInteritemSpacing) / 2, height: Constants.cvSizeHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Constants.cvInteritemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        Constants.cvSectionInsets
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
        let title = dataProvider.sectionTitle(at: indexPath.section) ?? ""
        view.configure(title: title)
        return view
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: Constants.cvHeaderHeight)
    }
}

extension TrackersListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension TrackersListViewController {
    private enum Constants {
        static let stubLabelFontSize: CGFloat = 12
        static let addButtonInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        static let cvInteritemSpacing: CGFloat = 9
        static let cvInsets: CGFloat = 16
        static let cvSizeHeight: CGFloat = 148
        static let cvSectionInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: Constants.cvInsets, bottom: Constants.cvInsets, right: Constants.cvInsets)
        static let cvHeaderHeight: CGFloat = 40
    }
}

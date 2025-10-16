import UIKit

final class TrackersListViewController: UIViewController {
    private let trackerStore = TrackerStore()
    private let recordStore = TrackerRecordStore()
    private var dataProvider: TrackersDataProviderProtocol = TrackersDataProvider()
    private let analyticsService = AnalyticsService()

    private var isTrackersEmpty: Bool = true {
        didSet {
            stubImage.isHidden = !isTrackersEmpty
            stubLabel.isHidden = !isTrackersEmpty
            if isTrackersEmpty {
                updateStubAppearance()
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
    private var isSearching: Bool {
        let q = (searchField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !q.isEmpty
    }
    private var currentFilter: FilterKind = .none {
        didSet { updateStubAppearance() }
    }

    // MARK: - UI properties
    private let searchField: UISearchTextField = {
        let searchField = UISearchTextField()
        searchField.placeholder = NSLocalizedString("search", comment: "searchField placeholder")
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
        label.text = Constants.stubLabelText
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
        collectionView.backgroundColor = UIColor(resource: .ypWhiteDay)
        return collectionView
    }()

    private lazy var filtersButton: UIButton = {
        let button = UIButton()
        let title = NSLocalizedString("filters", comment: "Filters button title")
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Constants.filtersButtonFont
        button.titleLabel?.textColor = .white
        button.layer.cornerRadius = Constants.cornerRadius
        button.backgroundColor = UIColor(resource: .ypBlue)
        button.addTarget(self, action: #selector(filtersButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavBar()
        layoutUI()
        applyDatePickerTheme()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.applyDatePickerTheme()
        }

        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        view.backgroundColor = UIColor(resource: .ypWhiteDay)
        isTrackersEmpty = true

        dataProvider.onChange = { [weak self] in
            guard let self else { return }
            self.updateEmptyState()
            self.updateFiltersButton()
            self.trackersCollectionView.reloadData()
        }

        try? dataProvider.performFetch(filter: .init(weekday: selectedWeekday, search: nil))
        updateEmptyState()
        updateFiltersButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // analyticsService.report(event: "open", params: ["screen" : "Main"])
        analyticsService.report(.open(screen: .main))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // analyticsService.report(event: "close", params: ["screen" : "Main"])
        analyticsService.report(.close(screen: .main))
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

    private func updateFiltersButton() {
        let hasAny = (try? trackerStore.hasAny(weekday: selectedWeekday)) ?? false
        filtersButton.isHidden = !hasAny
    }

    private func updateStubAppearance() {
        if isSearching || currentFilter != .none {
            stubImage.image = UIImage(resource: .stubSearch)
            stubLabel.text = NSLocalizedString("nothing_found", comment: "Empty search results label")
        } else {
            stubImage.image = UIImage(resource: .stubStar)
            stubLabel.text = Constants.stubLabelText
        }
    }

    private func configureNavBar() {
        title = NSLocalizedString("trackers", comment: "NavBar title")
        navigationItem.leftBarButtonItem = addButton
        navigationItem.leftBarButtonItem?.tintColor = .ypBlackDay
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = datePickerButton
    }

    private func applyDatePickerTheme() {
        if traitCollection.userInterfaceStyle == .dark {
            datePicker.overrideUserInterfaceStyle = .light
            datePicker.backgroundColor = .white
            datePicker.layer.cornerRadius = 8
            datePicker.layer.masksToBounds = true
        } else {
            datePicker.overrideUserInterfaceStyle = .unspecified
            datePicker.backgroundColor = .clear
            datePicker.layer.cornerRadius = 0
            datePicker.layer.masksToBounds = false
        }
    }

    private func applyFetchForCurrentState() {
        let q = searchField.text
        switch currentFilter {
        case .none:
            try? dataProvider.performFetch(filter: .init(weekday: selectedWeekday, search: q, completion: nil))
        case .completed:
            try? dataProvider.performFetch(filter: .init(weekday: selectedWeekday, search: q, completion: .completed(selectedDate)))
        case .notCompleted:
            try? dataProvider.performFetch(filter: .init(weekday: selectedWeekday, search: q, completion: .notCompleted(selectedDate)))
        }
    }

    private func showDeletionAlert(trackerID: UUID) {
        let alert = UIAlertController(
            title: Constants.alertText,
            message: nil,
            preferredStyle: .actionSheet
        )

        let delete = UIAlertAction(
            title: "Удалить",
            style: .destructive
        ) { [weak self] _ in
            try? self?.trackerStore.delete(id: trackerID)
        }

        let cancel = UIAlertAction(title: "Отменить", style: .cancel)

        alert.addAction(delete)
        alert.addAction(cancel)
        present(alert, animated: true)
    }

    private func layoutUI() {
        [searchField, stubImage, stubLabel, trackersCollectionView, filtersButton].forEach {
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
            stubImage.heightAnchor.constraint(equalToConstant: 80),
            stubImage.widthAnchor.constraint(equalToConstant: 80),

            stubLabel.topAnchor.constraint(equalTo: stubImage.bottomAnchor, constant: 8),
            stubLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            trackersCollectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 24),
            trackersCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            trackersCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            trackersCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
            filtersButton.widthAnchor.constraint(equalToConstant: 114),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Actions
    @objc
    private func addTrackerTapped() {
        let newHabitViewController = NewHabitViewController()
        newHabitViewController.create = { [weak self] tracker, category in
            try? self?.trackerStore.create(tracker, inCategory: category)
        }
        present(newHabitViewController, animated: true)

        // analyticsService.report(event: "click", params: ["screen" : "Main", "item" : "add_track"])
        analyticsService.report(.click(screen: .main, item: .addTrack))
    }

    @objc
    private func dateChanged() {
        applyFetchForCurrentState()
        updateFiltersButton()
    }

    @objc
    private func searchTextChanged(_ textField: UITextField) {
        applyFetchForCurrentState()
        updateEmptyState()
    }

    @objc
    private func filtersButtonTapped() {
        // analyticsService.report(event: "click", params: ["screen" : "Main", "item" : "filter"])
        analyticsService.report(.click(screen: .main, item: .filter))

        let filtersViewController = FiltersViewController()

        switch currentFilter {
        case .none:
            filtersViewController.selectedRow = nil
        case .completed:
            filtersViewController.selectedRow = .completed
        case .notCompleted:
            filtersViewController.selectedRow = .notCompleted
        }

        filtersViewController.onSelect = { [weak self] selected in
            guard let self else { return }

            switch selected {
            case .allTrackers:
                self.currentFilter = .none
                self.applyFetchForCurrentState()
            case .todayTrackers:
                self.currentFilter = .none
                self.datePicker.date = Date()
                self.applyDatePickerTheme()
                self.applyFetchForCurrentState()
            case .completed:
                self.currentFilter = .completed
                self.applyFetchForCurrentState()
            case .notCompleted:
                self.currentFilter = .notCompleted
                self.applyFetchForCurrentState()
            }

            self.updateEmptyState()
            self.updateFiltersButton()
        }
        present(filtersViewController, animated: true)
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
            //self.analyticsService.report(event: "click", params: ["screen" : "Main", "item" : "track"])
            self.analyticsService.report(.click(screen: .main, item: .track))
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

    // MARK: - Supplementary View (Header)
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

    // MARK: - Context menu
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else { return nil }

        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: nil,
        ) { [weak self] _ in
            let edit = UIAction(title: "Редактировать") { _ in
                guard let self else { return }
                //self.analyticsService.report(event: "click", params: ["screen" : "Main", "item" : "edit"])
                self.analyticsService.report(.click(screen: .main, item: .edit))

                let tracker = self.dataProvider.tracker(at: indexPath)
                let categoryTitle = self.dataProvider.sectionTitle(at: indexPath.section) ?? ""
                let doneCount = (try? self.recordStore.completionCount(trackerID: tracker.id)) ?? 0

                let vc = NewHabitViewController()
                vc.configureForEdit(with: tracker, categoryTitle: categoryTitle, completedDays: doneCount)
                vc.update = { [weak self] updated, newCategory in
                    try? self?.trackerStore.update(updated, inCategory: newCategory)
                }
                self.present(vc, animated: true)
            }

            let delete = UIAction(title: "Удалить", attributes: .destructive) { _ in
                guard let self else { return }
                // self.analyticsService.report(event: "click", params: ["screen" : "Main", "item" : "delete"])
                self.analyticsService.report(.click(screen: .main, item: .delete))

                let tracker = self.dataProvider.tracker(at: indexPath)
                self.showDeletionAlert(trackerID: tracker.id)
            }

            return UIMenu(children: [edit, delete])
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, highlightPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
        targetedPreview(for: indexPath, in: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, dismissalPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
        targetedPreview(for: indexPath, in: collectionView)
    }

    private func targetedPreview(
        for indexPath: IndexPath,
        in collectionView: UICollectionView
    ) -> UITargetedPreview? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TrackerViewCell else { return nil }
        let view = cell.contextMenuPreviewView
        view.layoutIfNeeded()
        
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        let path = UIBezierPath(roundedRect: view.bounds, cornerRadius: cell.contextMenuCornerRadius)
        params.visiblePath = path

        return UITargetedPreview(view: view, parameters: params)
    }
}

// MARK: - UITextFieldDelegate protocol
extension TrackersListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        try? dataProvider.performFetch(filter: .init(weekday: selectedWeekday, search: nil))
        updateEmptyState()
        return true
    }
}

extension TrackersListViewController {
    private enum Constants {
        static let cornerRadius: CGFloat = 16
        static let filtersButtonFont: UIFont = .systemFont(ofSize: 17)
        static let stubLabelFontSize: CGFloat = 12
        static let addButtonInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        static let cvInteritemSpacing: CGFloat = 9
        static let cvInsets: CGFloat = 16
        static let cvSizeHeight: CGFloat = 148
        static let cvSectionInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: Constants.cvInsets, bottom: Constants.cvInsets, right: Constants.cvInsets)
        static let cvHeaderHeight: CGFloat = 40
        static let stubLabelText: String = NSLocalizedString("stub_text", comment: "Stub label text")
        static let alertText: String = "Уверены, что хотите удалить трекер?"
    }

    private enum FilterKind {
        case none
        case completed
        case notCompleted
    }
}

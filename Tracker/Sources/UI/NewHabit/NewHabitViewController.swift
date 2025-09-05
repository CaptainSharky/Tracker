import UIKit

final class NewHabitViewController: UIViewController {
    private var selectedWeekdays = Set<Weekday>()
    private let nameLimit = 38
    var create: ((Tracker) -> Void)?

    // MARK: - UI properties
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.keyboardDismissMode = .interactive
        return view
    }()

    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новая привычка"
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private lazy var nameTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.delegate = self
        textField.font = .systemFont(ofSize: 17)
        textField.placeholder = "Введите название трекера"
        textField.backgroundColor = UIColor(resource: .ypBackground)
        textField.layer.cornerRadius = 16
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(nameEditingChanged), for: .editingChanged)
        return textField
    }()

    private let limitLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.font = .systemFont(ofSize: 17)
        label.textColor = UIColor(resource: .ypRed)
        label.isHidden = true
        return label
    }()

    private lazy var settingsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 75
        tableView.layer.cornerRadius = 16
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.isScrollEnabled = false
        tableView.clipsToBounds = true
        return tableView
    }()

    private lazy var customizationCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(EmojiViewCell.self, forCellWithReuseIdentifier: EmojiViewCell.identifier)
        collectionView.register(ColorViewCell.self, forCellWithReuseIdentifier: ColorViewCell.identifier)
        collectionView.register(CategoryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CategoryView.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        return collectionView
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(UIColor(resource: .ypRed), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(resource: .ypRed).cgColor
        button.addTarget(self, action: #selector(cancelCreating), for: .touchUpInside)
        return button
    }()

    private lazy var createButton: UIButton = {
        let button = UIButton()
        button.setTitle("Создать", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.layer.cornerRadius = 16
        button.backgroundColor = UIColor(resource: .ypGray)
        button.isEnabled = false
        button.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return button
    }()

    private var isCreateButtonEnabled: Bool = false {
        didSet {
            createButton.isEnabled = isCreateButtonEnabled
            let color = isCreateButtonEnabled ? UIColor(resource: .ypBlackDay) : UIColor(resource: .ypGray)
            createButton.backgroundColor = color
        }
    }

    private var tableTopToLabel: NSLayoutConstraint?
    private var tableTopToTextField: NSLayoutConstraint?
    private var selectedEmojiIndex: Int?
    private var selectedColorIndex: Int?

    private let emojies = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱", "😇", "😡", "🥶",
        "🤔", "🙌", "🍔", "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
    ]

    private let colors: [UIColor] = [
        .CS_1, .CS_2, .CS_3, .CS_4, .CS_5, .CS_6, .CS_7, .CS_8, .CS_9,
        .CS_10, .CS_11, .CS_12, .CS_13, .CS_14, .CS_15, .CS_16, .CS_17, .CS_18
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboard(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        layoutUI()
    }

    // MARK: - Private methods
    private func scheduleSummary(days: Set<Weekday>) -> String {
        if days.count == 7 { return "Каждый день" }

        return days.sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortTitle }
            .joined(separator: ", ")
    }

    private func updateCreateButtonState() {
        let hasName = !(nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasDays = !selectedWeekdays.isEmpty
        let hasEmoji = selectedEmojiIndex != nil
        let hasColor = selectedColorIndex != nil
        isCreateButtonEnabled = hasName && hasDays && hasEmoji && hasColor
    }

    private func updateLimitLayout() {
        let show = !limitLabel.isHidden
        tableTopToTextField?.isActive = !show
        tableTopToLabel?.isActive = show
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    private func layoutUI() {
        view.backgroundColor = UIColor(resource: .ypWhiteDay)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        [titleLabel, nameTextField, limitLabel, settingsTableView, customizationCollectionView, cancelButton, createButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        tableTopToLabel = settingsTableView.topAnchor.constraint(equalTo: limitLabel.bottomAnchor, constant: 32)
        tableTopToTextField = settingsTableView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24)
        tableTopToTextField?.isActive = true

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),

            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            limitLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8),
            limitLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            settingsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            settingsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            settingsTableView.heightAnchor.constraint(equalToConstant: 150),

            customizationCollectionView.topAnchor.constraint(equalTo: settingsTableView.bottomAnchor, constant: 28),
            customizationCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            customizationCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            customizationCollectionView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),

            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.trailingAnchor.constraint(equalTo: createButton.leadingAnchor, constant: -8),

            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),
            createButton.topAnchor.constraint(greaterThanOrEqualTo: settingsTableView.bottomAnchor, constant: 24),
            createButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Actions
    @objc
    private func cancelCreating() {
        dismiss(animated: true)
    }

    @objc
    private func nameEditingChanged() {
        let count = nameTextField.text?.count ?? 0
        limitLabel.isHidden = count < nameLimit
        updateCreateButtonState()
        updateLimitLayout()
    }

    @objc
    private func createTapped() {
        guard isCreateButtonEnabled else { return }
        guard let selectedEmojiIndex, let selectedColorIndex else { return }

        let title = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let emoji = emojies[selectedEmojiIndex]
        let color = colors[selectedColorIndex]

        let tracker = Tracker(title: title, color: color, emoji: emoji, schedule: selectedWeekdays)
        create?(tracker)
        dismiss(animated: true)
    }

    @objc
    private func handleKeyboard(_ note: Notification) {
        guard
            let userInfo = note.userInfo,
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect),
            let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double),
            let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt)
        else { return }

        let endInView = view.convert(endFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - endInView.origin.y)
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: overlap, right: 0)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveRaw << 16),
            animations: {
                self.scrollView.contentInset = insets
                self.scrollView.scrollIndicatorInsets = insets
            })
    }
}

// MARK: - UITableViewDelegate protocol
extension NewHabitViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch SettingsRow(rawValue: indexPath.row) {
        case .category:
            // открыть категории
            break
        case .schedule:
            let scheduleViewController = ScheduleViewController(selectedDays: selectedWeekdays)
            scheduleViewController.onDone = { [weak self] days in
                self?.selectedWeekdays = days
                let index = IndexPath(row: SettingsRow.schedule.rawValue, section: 0)
                self?.settingsTableView.reloadRows(at: [index], with: .none)
                self?.updateCreateButtonState()
            }
            present(scheduleViewController, animated: true)
        case .none:
            break
        }
    }
}

// MARK: - UITableViewDataSource protocol
extension NewHabitViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsRow.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        let row = SettingsRow(rawValue: indexPath.row)

        var config = cell.defaultContentConfiguration()
        config.text = row?.title
        config.textProperties.font = .systemFont(ofSize: 17)
        if row == .schedule, !selectedWeekdays.isEmpty {
            config.secondaryText = scheduleSummary(days: selectedWeekdays)
            config.secondaryTextProperties.color = UIColor(resource: .ypGray)
            config.secondaryTextProperties.font = .systemFont(ofSize: 17)
        }
        cell.contentConfiguration = config

        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = UIColor(resource: .ypBackground)

        if indexPath.row == SettingsRow.allCases.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        }
        return cell
    }
}

// MARK: - UICollectionViewDataSource protocol
extension NewHabitViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch CustomizationSection(rawValue: section) {
        case .emojies:
            return emojies.count
        case .colors:
            return colors.count
        case .none:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let stubCell = UICollectionViewCell()

        switch CustomizationSection(rawValue: indexPath.section) {
        case .emojies:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EmojiViewCell.identifier,
                for: indexPath
            ) as? EmojiViewCell else {
                return stubCell
            }
            let emoji = emojies[indexPath.item]
            cell.configure(emoji: emoji)

            if selectedEmojiIndex == indexPath.item {
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            } else {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
            return cell

        case .colors:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ColorViewCell.identifier,
                for: indexPath
            ) as? ColorViewCell else {
                return stubCell
            }
            let color = colors[indexPath.item]
            cell.configure(color: color)

            if selectedColorIndex == indexPath.item {
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            } else {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
            return cell

        case .none:
            break
        }
        return stubCell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        CustomizationSection.allCases.count
    }
}

// MARK: - UICollectionViewDelegateFlowLayout protocol
extension NewHabitViewController: UICollectionViewDelegateFlowLayout {
    // MARK: Размеры ячеек
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let available = collectionView.bounds.width - 18 * 2 - 5 * 5
        let side = floor(available / 6)
        return CGSize(width: side, height: side)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 18, left: 18, bottom: 32, right: 18)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    // MARK: Выделение ячеек
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch CustomizationSection(rawValue: indexPath.section) {

        case .emojies:
            if let prev = selectedEmojiIndex, prev != indexPath.item {
                collectionView.deselectItem(at: IndexPath(item: prev, section: indexPath.section), animated: true)
            }
            selectedEmojiIndex = indexPath.item

        case .colors:
            if let prev = selectedColorIndex, prev != indexPath.item {
                collectionView.deselectItem(at: IndexPath(item: prev, section: indexPath.section), animated: true)
            }
            selectedColorIndex = indexPath.item

        case .none:
            break
        }
        updateCreateButtonState()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        switch CustomizationSection(rawValue: indexPath.section) {
        case .emojies:
            if selectedEmojiIndex == indexPath.item { selectedEmojiIndex = nil }
        case .colors:
            if selectedColorIndex == indexPath.item { selectedColorIndex = nil }
        case .none:
            break
        }
        updateCreateButtonState()
    }

    // MARK: Supplementary View (header)
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: CategoryView.identifier,
            for: indexPath
        ) as? CategoryView else {
            return UICollectionReusableView()
        }

        let title: String
        switch CustomizationSection(rawValue: indexPath.section) {
        case .emojies:
            title = "Emoji"
        case .colors:
            title = "Цвет"
        case .none:
            title = ""
        }

        view.configure(title: title)
        return view
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 30)
    }
}

// MARK: - UITextFieldDelegate protocol
extension NewHabitViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.rangeOfCharacter(from: .newlines) != nil { return false }

        let current = textField.text ?? ""
        guard let range = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: range, with: string)

        if updated.count > nameLimit { return false }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

final class CustomTextField: UITextField {
    var clearPadding: CGFloat = 12
    var textInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: textInsets) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: textInsets) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: textInsets) }
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        super.clearButtonRect(forBounds: bounds).offsetBy(dx: -clearPadding, dy: 0)
    }
}

private enum SettingsRow: Int, CaseIterable {
    case category, schedule
    var title: String {
        switch self {
        case .category:
            return "Категория"
        case .schedule:
            return "Расписание"
        }
    }
}

private enum CustomizationSection: Int, CaseIterable {
    case emojies
    case colors
    var title: String {
        switch self {
        case .emojies:
            return "Emoji"
        case .colors:
            return "Цвет"
        }
    }
}

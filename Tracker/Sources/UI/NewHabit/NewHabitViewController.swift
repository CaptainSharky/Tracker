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

    private let settingsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        tableView.rowHeight = 75
        tableView.layer.cornerRadius = 16
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.isScrollEnabled = false
        tableView.clipsToBounds = true
        return tableView
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        settingsTableView.delegate = self
        settingsTableView.dataSource = self

        nameTextField.delegate = self

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
        isCreateButtonEnabled = hasName && hasDays
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

        [titleLabel, nameTextField, limitLabel, settingsTableView, cancelButton, createButton].forEach {
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
            // settingsTableView.topAnchor.constraint(equalTo: limitLabel.bottomAnchor, constant: 32),
            settingsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            settingsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            settingsTableView.heightAnchor.constraint(equalToConstant: 150),
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

        let title = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let color = UIColor(resource: .CS_1)
        let emoji = "😛"

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

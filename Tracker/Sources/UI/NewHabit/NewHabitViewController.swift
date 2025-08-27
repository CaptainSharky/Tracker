import UIKit

final class NewHabitViewController: UIViewController {
    // MARK: - UI properties
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новая привычка"
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 17)
        textField.placeholder = "Введите название трекера"
        textField.backgroundColor = UIColor(resource: .ypBackground)
        textField.layer.cornerRadius = 16

        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftView = padding
        textField.leftViewMode = .always
        return textField
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        settingsTableView.delegate = self
        settingsTableView.dataSource = self

        layoutUI()
        view.backgroundColor = UIColor(resource: .ypWhiteDay)
    }

    // MARK: - Private methods
    private func layoutUI() {
        [titleLabel, nameTextField, settingsTableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            nameTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            settingsTableView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            settingsTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            settingsTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            settingsTableView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
}

extension NewHabitViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch SettingsRow(rawValue: indexPath.row) {
        case .category:
            // открыть категории
            break
        case .schedule:
            // открыть расписание
            break
        case .none:
            break
        }
    }
}

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
        cell.contentConfiguration = config

        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = UIColor(resource: .ypBackground)

        if indexPath.row == SettingsRow.allCases.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        }
        return cell
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

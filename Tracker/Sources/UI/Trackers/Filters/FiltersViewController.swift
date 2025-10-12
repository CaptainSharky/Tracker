import UIKit

final class FiltersViewController: UIViewController {

    var selectedRow: FiltersRow?
    var onSelect: ((FiltersRow) -> Void)?

    // MARK: - UI properties
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("filters", comment: "Filters view title")
        label.font = Constants.titleFont
        return label
    }()

    private lazy var filtersTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "filtersCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = Constants.tvRowHeight
        tableView.layer.cornerRadius = Constants.cornerRadius
        tableView.separatorInset = Constants.tvSeparatorInsets
        tableView.isScrollEnabled = false
        tableView.clipsToBounds = true
        return tableView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(resource: .ypWhiteDay)
        layoutUI()
    }

    // MARK: - Private methods
    private func layoutUI() {
        [titleLabel, filtersTableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let tableHeight = CGFloat(FiltersRow.allCases.count) * Constants.tvRowHeight

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),

            filtersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filtersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filtersTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            filtersTableView.heightAnchor.constraint(equalToConstant: tableHeight)
        ])
    }
}

// MARK: - UITableViewDataSource protocol
extension FiltersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        FiltersRow.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filtersCell", for: indexPath)
        let row = FiltersRow(rawValue: indexPath.row)

        var config = cell.defaultContentConfiguration()
        config.text = row?.title
        config.textProperties.font = Constants.tvFont
        cell.contentConfiguration = config

        cell.backgroundColor = UIColor(resource: .ypBackground)

        if indexPath.row == FiltersRow.allCases.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = Constants.tvSeparatorInsets
        }

        if let row {
            switch row {
            case .completed, .notCompleted:
                cell.accessoryType = (row == selectedRow) ? .checkmark : .none
            case .allTrackers, .todayTrackers:
                cell.accessoryType = .none
            }
        }
        return cell
    }
}

// MARK: - UITableViewDelegate protocol
extension FiltersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = FiltersRow(rawValue: indexPath.row) else { return }
        onSelect?(row)
        dismiss(animated: true)
    }
}

extension FiltersViewController {
    private enum Constants {
        static let titleFont: UIFont = .systemFont(ofSize: 16, weight: .medium)
        static let cornerRadius: CGFloat = 16
        static let tvFont: UIFont = .systemFont(ofSize: 17)
        static let tvRowHeight: CGFloat = 75
        static let tvSeparatorInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    enum FiltersRow: Int, CaseIterable {
        case allTrackers
        case todayTrackers
        case completed
        case notCompleted

        var title: String {
            switch self {
            case .allTrackers:
                return "Все трекеры"
            case .todayTrackers:
                return "Трекеры на сегодня"
            case .completed:
                return "Завершенные"
            case .notCompleted:
                return "Не завершенные"
            }
        }
    }
}

import UIKit

final class ScheduleViewController: UIViewController {
    private var selectedDays: Set<Weekday>
    var onDone: ((Set<Weekday>) -> Void)?
    // MARK: - UI properties
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Расписание"
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private let scheduleTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "dayCell")
        tableView.rowHeight = 75
        tableView.layer.cornerRadius = 16
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.isScrollEnabled = false
        tableView.clipsToBounds = true
        return tableView
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Готово", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.titleLabel?.textColor = .ypWhiteDay
        button.layer.cornerRadius = 16
        button.backgroundColor = UIColor(resource: .ypBlackDay)
        button.addTarget(self, action: #selector(tapDone), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    init(selectedDays: Set<Weekday> = []) {
        self.selectedDays = selectedDays
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scheduleTableView.dataSource = self
        scheduleTableView.delegate = self

        layoutUI()
    }

    private func layoutUI() {
        view.backgroundColor = UIColor(resource: .ypWhiteDay)

        [titleLabel, scheduleTableView, doneButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scheduleTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            scheduleTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            scheduleTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            scheduleTableView.heightAnchor.constraint(equalToConstant: 525),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc
    private func tapDone() {
        onDone?(selectedDays)
        dismiss(animated: true)
    }

    @objc
    private func switchChanged(_ sender: UISwitch) {
        let day = Weekday.allCases[sender.tag]
        if sender.isOn { selectedDays.insert(day) } else { selectedDays.remove(day) }
    }
}

extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Weekday.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dayCell", for: indexPath)
        let day = Weekday.allCases[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = day.title
        config.textProperties.font = .systemFont(ofSize: 17)
        cell.contentConfiguration = config

        let button: UISwitch
        if let existing = cell.accessoryView as? UISwitch {
            button = existing
        } else {
            button = UISwitch()
            button.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = button
        }
        button.tag = indexPath.row
        button.isOn = selectedDays.contains(day)
        button.onTintColor = UIColor(resource: .ypBlue)

        if indexPath.row == Weekday.allCases.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        }

        cell.backgroundColor = UIColor(resource: .ypBackground)
        cell.selectionStyle = .none

        return cell
    }
}

extension ScheduleViewController: UITableViewDelegate {

}

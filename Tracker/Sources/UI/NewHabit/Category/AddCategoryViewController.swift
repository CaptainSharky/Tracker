import UIKit

final class AddCategoryViewController: UIViewController {

    var onCreate: ((String) -> Void)?
    private var mode: Mode
    private let initialTitle: String?

    // MARK: - UI properties
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = mode == .add ? "Новая категория" : "Редактирование категории"
        label.font = Constants.font
        return label
    }()

    private lazy var nameTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.delegate = self
        textField.font = .systemFont(ofSize: Constants.bigFontSize)
        textField.placeholder = "Введите название категории"
        textField.backgroundColor = UIColor(resource: .ypBackground)
        textField.layer.cornerRadius = Constants.cornerRadius
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(nameEditingChanged), for: .editingChanged)
        return textField
    }()

    private let limitLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.font = .systemFont(ofSize: Constants.bigFontSize)
        label.textColor = UIColor(resource: .ypRed)
        label.isHidden = true
        return label
    }()

    private lazy var createButton: UIButton = {
        let button = UIButton()
        button.setTitle("Готово", for: .normal)
        button.titleLabel?.font = Constants.font
        button.layer.cornerRadius = Constants.cornerRadius
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

    // MARK: - Lifecycle
    init(mode: Mode = .add, initialTitle: String? = nil) {
        self.mode = mode
        self.initialTitle = initialTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(resource: .ypWhiteDay)
        layoutUI()
        setInitialTitle()
    }

    // MARK: - Private methods
    private func setInitialTitle() {
        if let initialTitle, mode == .edit {
            nameTextField.text = initialTitle
            updateCreateButtonState()
        }
    }

    private func updateCreateButtonState() {
        let hasName = !(nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        isCreateButtonEnabled = hasName
    }

    private func layoutUI() {
        [titleLabel, nameTextField, limitLabel, createButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            limitLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8),
            limitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Actions
    @objc
    private func nameEditingChanged() {
        let count = nameTextField.text?.count ?? 0
        limitLabel.isHidden = count < Constants.trackerNameLimit
        updateCreateButtonState()
    }

    @objc
    private func createTapped() {
        guard isCreateButtonEnabled else { return }

        let name = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        onCreate?(name)
        dismiss(animated: true)
    }
}

// MARK: - UITextFieldDelegate protocol
extension AddCategoryViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.rangeOfCharacter(from: .newlines) != nil { return false }

        let current = textField.text ?? ""
        guard let range = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: range, with: string)

        if updated.count > Constants.trackerNameLimit { return false }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AddCategoryViewController {
    private enum Constants {
        static let trackerNameLimit: Int = 38
        static let font: UIFont = .systemFont(ofSize: 16)
        static let bigFontSize: CGFloat = 17
        static let cornerRadius: CGFloat = 16
    }

    enum Mode {
        case add
        case edit
    }
}

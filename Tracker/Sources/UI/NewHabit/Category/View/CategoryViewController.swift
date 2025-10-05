import UIKit

final class CategoryViewController: UIViewController {

    private let viewModel: CategoryViewModel
    var onDone: ((String?) -> Void)?
    private var tableHeightConstraint: NSLayoutConstraint?

    private var isCategoriesEmpty: Bool = true {
        didSet {
            stubImage.isHidden = !isCategoriesEmpty
            stubLabel.isHidden = !isCategoriesEmpty
            if isCategoriesEmpty {
                view.bringSubviewToFront(stubImage)
                view.bringSubviewToFront(stubLabel)
            }
        }
    }

    // MARK: - UI properties
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Категория"
        label.font = Constants.font
        return label
    }()

    private lazy var categoryTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "categoryCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = Constants.tvRowHeight
        tableView.layer.cornerRadius = Constants.cornerRadius
        tableView.separatorInset = Constants.tvSeparatorInsets
        tableView.isScrollEnabled = true
        tableView.clipsToBounds = true
        tableView.separatorStyle = .none
        return tableView
    }()

    private lazy var addCategoryButton: UIButton = {
        let button = UIButton()
        button.setTitle(Constants.buttonText, for: .normal)
        button.layer.cornerRadius = Constants.cornerRadius
        button.backgroundColor = UIColor(resource: .ypBlackDay)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var stubImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(resource: .stubStar)
        image.contentMode = .scaleAspectFit
        return image
    }()

    private lazy var stubLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.stubText
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    init(selectedCategory: String?) {
        self.viewModel = CategoryViewModel(preselectedTitle: selectedCategory)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(resource: .ypWhiteDay)
        isCategoriesEmpty = true
        layoutUI()
        bind()
        viewModel.load()
        presentationController?.delegate = self
    }

    // MARK: - Private methods
    private func bind() {
        viewModel.onCategoriesChanged = { [weak self] _ in
            self?.categoryTableView.reloadData()
            self?.updateTableHeight()
        }
        viewModel.onEmptyStateChanged = { [weak self] isEmpty in
            self?.isCategoriesEmpty = isEmpty
        }
    }

    private func layoutUI() {
        [titleLabel, categoryTableView, addCategoryButton, stubImage, stubLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        tableHeightConstraint = categoryTableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            stubImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stubImage.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stubImage.heightAnchor.constraint(equalToConstant: 80),
            stubImage.widthAnchor.constraint(equalToConstant: 80),

            stubLabel.topAnchor.constraint(equalTo: stubImage.bottomAnchor, constant: 8),
            stubLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stubLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60),


            categoryTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 38),
            categoryTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func updateTableHeight() {
        categoryTableView.layoutIfNeeded()
        tableHeightConstraint?.constant = min(categoryTableView.contentSize.height, 450)
    }

    // MARK: - Actions
    @objc
    private func addButtonTapped() {

    }

    private func finishAndReturn() {
        onDone?(viewModel.selectedTitle)
    }
}

extension CategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)

        var config = cell.defaultContentConfiguration()
        config.text = viewModel.title(at: indexPath.row)
        config.textProperties.font = .systemFont(ofSize: Constants.tvFontSize)
        cell.contentConfiguration = config

        cell.accessoryType = viewModel.isSelected(at: indexPath.row) ? .checkmark : .none
        cell.tintColor = UIColor(resource: .ypBlue)

        if indexPath.row == viewModel.numberOfRows() - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        }

        cell.backgroundColor = UIColor(resource: .ypBackground)
        return cell
    }
}

extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.select(at: indexPath.row)
        tableView.reloadData()
    }
}

extension CategoryViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finishAndReturn()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            finishAndReturn()
        }
    }
}

extension CategoryViewController {
    private enum Constants {
        static let font: UIFont = .systemFont(ofSize: 16)
        static let buttonText: String = "Добавить категорию"
        static let cornerRadius: CGFloat = 16
        static let stubText: String = "Привычки и события можно объединить по смыслу"
        static let tvRowHeight: CGFloat = 75
        static let tvSeparatorInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let tvFontSize: CGFloat = 17
    }
}

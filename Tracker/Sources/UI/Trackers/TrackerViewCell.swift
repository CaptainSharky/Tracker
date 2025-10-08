import UIKit

final class TrackerViewCell: UICollectionViewCell {
    static let cellIdentifier = "trackerCell"
    var onTap: ((TrackerRecord) -> Void)?

    // MARK: - UI properties
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.fontSize, weight: .medium)
        label.textColor = .white
        label.textAlignment = .left
        return label
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.fontSize)
        return label
    }()

    private let emojiBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.emojiCornerRadius
        view.backgroundColor = .white.withAlphaComponent(Constants.backgroundAlpha)
        view.clipsToBounds = true
        return view
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cardCornerRadius
        return view
    }()

    private let daysCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.fontSize, weight: .medium)
        label.textColor = UIColor(resource: .ypBlackDay)
        label.textAlignment = .left
        return label
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = Constants.buttonCornerRadius
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Private properties
    private var trackerId: UUID?
    private var isCompleted = false
    private var completedDays = 0
    private var currentDate = Date()

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods
    func configureCell(tracker: Tracker, completedDays: Int, isCompleted: Bool, currentDate: Date) {
        trackerId = tracker.id
        self.completedDays = completedDays
        self.isCompleted = isCompleted
        self.currentDate = currentDate

        cardView.backgroundColor = tracker.color
        emojiLabel.text = tracker.emoji
        titleLabel.text = tracker.title
        daysCountLabel.text = daysCountFormatted(daysCount: completedDays)

        updateDoneButton()

    }

    // MARK: - Private methods
    private func setupUI() {
        contentView.addSubview(cardView)
        contentView.addSubview(daysCountLabel)
        contentView.addSubview(doneButton)
        cardView.addSubview(emojiBackgroundView)
        cardView.addSubview(titleLabel)
        emojiBackgroundView.addSubview(emojiLabel)

        [cardView, daysCountLabel, doneButton, emojiBackgroundView, titleLabel, emojiLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 90),
            emojiBackgroundView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            emojiBackgroundView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            emojiBackgroundView.heightAnchor.constraint(equalToConstant: 24),
            emojiBackgroundView.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackgroundView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackgroundView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            daysCountLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 16),
            daysCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            daysCountLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            doneButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8),
            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            doneButton.heightAnchor.constraint(equalToConstant: 34),
            doneButton.widthAnchor.constraint(equalToConstant: 34)
        ])
    }

    private func updateDoneButton() {
        let imageName = isCompleted ? "checkmark" : "plus"
        doneButton.setImage(UIImage(systemName: imageName), for: .normal)
        doneButton.backgroundColor = cardView.backgroundColor?.withAlphaComponent(isCompleted ? Constants.backgroundAlpha : 1.0)
        doneButton.tintColor = UIColor(resource: .ypWhiteDay)

        let isNewDay = currentDate > Date()
        doneButton.isEnabled = !isNewDay
        doneButton.alpha = isNewDay ? Constants.backgroundAlpha : 1.0
    }

    private func daysCountFormatted(daysCount: Int) -> String {
        let daysCountString = String.localizedStringWithFormat(
            NSLocalizedString("daysCount", comment: "Days count in Tracker cell"),
            daysCount
        )
        return daysCountString
    }

    // MARK: - Actions
    @objc private func doneButtonTapped() {
        isCompleted.toggle()
        updateDoneButton()

        completedDays += isCompleted ? 1 : -1
        daysCountLabel.text = daysCountFormatted(daysCount: completedDays)

        guard let trackerId else { return }
        let record = TrackerRecord(trackerID: trackerId, date: currentDate)
        onTap?(record)
    }

    private enum Constants {
        static let fontSize: CGFloat = 12
        static let backgroundAlpha: CGFloat = 0.3
        static let emojiCornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 17
    }
}

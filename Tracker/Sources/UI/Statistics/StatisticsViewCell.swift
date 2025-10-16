import UIKit

final class StatisticsViewCell: UICollectionViewCell {

    // MARK: - UI properties
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.numberFont
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.titleFont
        return label
    }()

    private let colorLineView = GradientBorderView(
        lineWidth: 1.5,
        cornerRadius: Constants.cornerRadius,
        colors: [
            Constants.redGradient,
            Constants.greenGradient,
            Constants.blueGradient
        ]
    )

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor(resource: .ypWhiteDay)
        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureCell(number: Int, title: String) {
        numberLabel.text = String(number)
        titleLabel.text = title
    }

    // MARK: - Private methods
    private func layoutUI() {
        [colorLineView, numberLabel, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        contentView.addSubview(colorLineView)
        colorLineView.addSubview(numberLabel)
        colorLineView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            colorLineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorLineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorLineView.topAnchor.constraint(equalTo: contentView.topAnchor),
            colorLineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            numberLabel.leadingAnchor.constraint(equalTo: colorLineView.leadingAnchor, constant: 12),
            numberLabel.topAnchor.constraint(equalTo: colorLineView.topAnchor, constant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: colorLineView.leadingAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: colorLineView.bottomAnchor, constant: -12)
        ])
    }
}

extension StatisticsViewCell {
    private enum Constants {
        static let numberFont: UIFont = .systemFont(ofSize: 34, weight: .bold)
        static let titleFont: UIFont = .systemFont(ofSize: 12, weight: .medium)
        static let cornerRadius: CGFloat = 16
        static let redGradient: UIColor = UIColor(hexRGB: "#FD4C49") ?? .black
        static let greenGradient: UIColor = UIColor(hexRGB: "#46E69D") ?? .black
        static let blueGradient: UIColor = UIColor(hexRGB: "#007BFA") ?? .black
    }
}

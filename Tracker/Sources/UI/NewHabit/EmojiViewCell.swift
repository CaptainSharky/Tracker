import UIKit

final class EmojiViewCell: UICollectionViewCell {
    static let identifier = "emojiCell"

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32)
        return label
    }()

    private lazy var selectionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(resource: .ypLightGray)
        view.layer.cornerRadius = 16
        view.isHidden = true
        return view
    }()

    override var isSelected: Bool {
        didSet { toggleSelection(on: isSelected) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(emoji: String) {
        emojiLabel.text = emoji
    }

    private func toggleSelection(on selected: Bool) {
        selectionView.isHidden = !selected
    }

    private func layoutUI() {
        contentView.addSubview(selectionView)
        contentView.addSubview(emojiLabel)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            selectionView.widthAnchor.constraint(equalToConstant: 52),
            selectionView.heightAnchor.constraint(equalToConstant: 52),
            selectionView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}

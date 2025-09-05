import UIKit

final class ColorViewCell: UICollectionViewCell {
    static let identifier = "colorCell"

    private let colorRect: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        return view
    }()

    private let selectionView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 12
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

    func configure(color: UIColor) {
        colorRect.backgroundColor = color
        selectionView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
    }

    func toggleSelection(on selected: Bool) {
        selectionView.isHidden = !selected
    }

    private func layoutUI() {
        contentView.addSubview(selectionView)
        contentView.addSubview(colorRect)
        colorRect.translatesAutoresizingMaskIntoConstraints = false
        selectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            colorRect.widthAnchor.constraint(equalToConstant: 40),
            colorRect.heightAnchor.constraint(equalToConstant: 40),
            colorRect.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorRect.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            selectionView.widthAnchor.constraint(equalToConstant: 52),
            selectionView.heightAnchor.constraint(equalToConstant: 52),
            selectionView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}

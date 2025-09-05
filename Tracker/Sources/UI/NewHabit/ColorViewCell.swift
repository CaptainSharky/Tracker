import UIKit

final class ColorViewCell: UICollectionViewCell {
    static let identifier = "colorCell"

    private let colorRect: UIView = {
        let rect = UIView()
        rect.layer.cornerRadius = 8
        return rect
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(color: UIColor) {
        colorRect.backgroundColor = color
    }

    private func layoutUI() {
        contentView.addSubview(colorRect)
        colorRect.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            colorRect.widthAnchor.constraint(equalToConstant: 40),
            colorRect.heightAnchor.constraint(equalToConstant: 40),
            colorRect.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorRect.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}

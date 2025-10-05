import UIKit

final class PageViewController: UIViewController {
    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        return label
    }()

    private let backgroundImageView: UIImageView = {
        let image = UIImageView()
        return image
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        layoutUI()
    }

    func configurePage(text: String, image: UIImage) {
        textLabel.text = text
        backgroundImageView.image = image
    }

    private func layoutUI() {
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backgroundImageView)
        view.addSubview(textLabel)

        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textLabel.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 26),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

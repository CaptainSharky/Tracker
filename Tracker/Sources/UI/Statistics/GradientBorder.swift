import UIKit

final class GradientBorderView: UIView {
    var lineWidth: CGFloat
    var corner: CGFloat
    var colors: [UIColor]

    private let gradient = CAGradientLayer()
    private let strokeMask = CAShapeLayer()

    init(lineWidth: CGFloat, cornerRadius: CGFloat, colors: [UIColor]) {
        self.lineWidth = lineWidth
        self.corner = cornerRadius
        self.colors = colors
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        let inset = lineWidth / 2
        let path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: inset, dy: inset),
            cornerRadius: corner
        )
        strokeMask.path = path.cgPath
        strokeMask.lineWidth = lineWidth
    }

    private func setup() {
        backgroundColor = UIColor(resource: .ypWhiteDay)
        layer.cornerRadius = corner
        layer.masksToBounds = true

        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [0, 0.5, 1]
        gradient.colors = colors.map { $0.cgColor }
        layer.addSublayer(gradient)

        strokeMask.fillColor = UIColor.clear.cgColor
        strokeMask.strokeColor = UIColor.black.cgColor
        strokeMask.lineWidth = lineWidth
        gradient.mask = strokeMask
    }
}


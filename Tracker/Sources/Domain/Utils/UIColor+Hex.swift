import UIKit

extension UIColor {
    var hexRGB: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))

        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    convenience init?(hexRGB: String) {
        let s = hexRGB.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard s.hasPrefix("#"), s.count == 7 else { return nil }

        let rStr = String(s.dropFirst().prefix(2))
        let gStr = String(s.dropFirst(3).prefix(2))
        let bStr = String(s.dropFirst(5).prefix(2))
        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0
        guard Scanner(string: rStr).scanHexInt64(&r),
              Scanner(string: gStr).scanHexInt64(&g),
              Scanner(string: bStr).scanHexInt64(&b) else { return nil }

        self.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
    }
}

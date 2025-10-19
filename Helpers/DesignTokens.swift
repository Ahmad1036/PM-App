//
//  DesignTokens.swift
//  PM-App
//
//  Design system tokens for a clean, modern UI
//

import UIKit

// MARK: - Colors

extension UIColor {
    
    // Primary
    static let pmMint = UIColor(hex: "#5AF7D7")
    static let pmMintLight = UIColor(hex: "#B3FFF0")
    static let pmMintDark = UIColor(hex: "#2DDAB8")
    
    // Accents
    static let pmCoral = UIColor(hex: "#FF6B9D")
    static let pmGold = UIColor(hex: "#FFD700")
    
    // Neutrals
    static let pmBlack = UIColor(hex: "#000000")
    static let pmWhite = UIColor(hex: "#FFFFFF")
    static let pmOffWhite = UIColor(hex: "#FAFAFA")
    static let pmSoftGray = UIColor(hex: "#F5F5F7")
    
    // Gradient colors for exciting background
    static let pmGradient1 = UIColor(hex: "#FFE5F0") // Soft pink
    static let pmGradient2 = UIColor(hex: "#E5F0FF") // Soft blue
    static let pmGradient3 = UIColor(hex: "#FFF5E5") // Soft peach
    
    // Adaptive (Light/Dark Mode)
    static var pmBackground: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#0A0A0A") : UIColor(hex: "#F7F7FF") }
    }
    
    static var pmSurface: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#1A1A1A") : pmWhite }
    }
    
    static var pmTextPrimary: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#FFFFFF") : pmBlack }
    }
    
    static var pmTextSecondary: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#CCCCCC") : UIColor(hex: "#666666") }
    }
    
    // Helper
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
    }
}

// MARK: - Typography

struct Typography {
    private static let newKansasName = "NewKansas-Regular"
    private static let newKansasMediumName = "NewKansas-Medium"
    private static let newKansasBoldName = "NewKansas-Bold"
    
    static func largeTitle() -> UIFont { UIFont(name: newKansasBoldName, size: 34) ?? .systemFont(ofSize: 34, weight: .bold) }
    static func title1() -> UIFont { UIFont(name: newKansasBoldName, size: 28) ?? .systemFont(ofSize: 28, weight: .bold) }
    static func title2() -> UIFont { UIFont(name: newKansasMediumName, size: 22) ?? .systemFont(ofSize: 22, weight: .semibold) }
    static func body() -> UIFont { UIFont(name: newKansasName, size: 17) ?? .systemFont(ofSize: 17, weight: .regular) }
    static func bodyMedium() -> UIFont { UIFont(name: newKansasMediumName, size: 17) ?? .systemFont(ofSize: 17, weight: .medium) }
    static func caption() -> UIFont { UIFont(name: newKansasName, size: 12) ?? .systemFont(ofSize: 12, weight: .regular) }
}


// MARK: - Spacing & Corner Radius

struct Spacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
}

struct CornerRadius {
    static let button: CGFloat = 14
    static let card: CGFloat = 20
}


// MARK: - UI Styles

// Style for primary call-to-action buttons
struct PrimaryButtonStyle {
    static func applyTo(_ button: UIButton, backgroundColor: UIColor = .pmCoral) {
        button.backgroundColor = backgroundColor
        button.setTitleColor(.pmWhite, for: .normal)
        button.titleLabel?.font = Typography.bodyMedium()
        button.layer.cornerRadius = CornerRadius.button
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.1
    }
}

// Style for translucent, glass-like card views
struct TranslucentCardStyle {
    static func applyTo(_ view: UIView) {
        view.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = CornerRadius.card
        blurView.clipsToBounds = true
        view.insertSubview(blurView, at: 0)
        
        view.layer.cornerRadius = CornerRadius.card
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.08
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        view.layer.borderWidth = 1.0
    }
}


// MARK: - Gradient Background Helper

extension UIView {
    func addExcitingGradientBackground() {
        layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor.pmGradient1.cgColor,
            UIColor.pmGradient2.cgColor,
            UIColor.pmGradient3.cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

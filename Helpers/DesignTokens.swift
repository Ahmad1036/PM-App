//
//  DesignTokens.swift
//  PM-App
//
//  Design system tokens extracted from Dribbble design
//

import UIKit

// MARK: - Colors

extension UIColor {
    
    // Primary
    static let pmMint = UIColor(hex: "#5AF7D7")
    static let pmMintLight = UIColor(hex: "#B3FFF0")
    static let pmMintDark = UIColor(hex: "#2DDAB8")
    
    static let pmBlack = UIColor(hex: "#000000")
    static let pmWhite = UIColor(hex: "#F8F8F8")
    static let pmOffWhite = UIColor(hex: "#FAFAFA")
    static let pmSoftGray = UIColor(hex: "#F5F5F7")
    
    // Accents
    static let pmCoral = UIColor(hex: "#FF6B9D")
    static let pmGold = UIColor(hex: "#FFD700")
    
    // Adaptive (Light/Dark Mode)
    static var pmBackground: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#0A0A0A") : UIColor(hex: "#FAF8FF") }
    }
    
    // Gradient colors for exciting background
    static let pmGradient1 = UIColor(hex: "#FFE5F0") // Soft pink
    static let pmGradient2 = UIColor(hex: "#E5F0FF") // Soft blue
    static let pmGradient3 = UIColor(hex: "#FFF5E5") // Soft peach
    
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
    // New Kansas Font
    private static let newKansasName = "NewKansas-Regular"
    private static let newKansasMediumName = "NewKansas-Medium"
    private static let newKansasBoldName = "NewKansas-Bold"
    
    static func largeTitle() -> UIFont { 
        UIFont(name: newKansasBoldName, size: 34) ?? .systemFont(ofSize: 34, weight: .bold) 
    }
    static func title1() -> UIFont { 
        UIFont(name: newKansasBoldName, size: 28) ?? .systemFont(ofSize: 28, weight: .bold) 
    }
    static func title2() -> UIFont { 
        UIFont(name: newKansasMediumName, size: 22) ?? .systemFont(ofSize: 22, weight: .semibold) 
    }
    static func body() -> UIFont { 
        UIFont(name: newKansasName, size: 17) ?? .systemFont(ofSize: 17, weight: .regular) 
    }
    static func bodyMedium() -> UIFont { 
        UIFont(name: newKansasMediumName, size: 17) ?? .systemFont(ofSize: 17, weight: .medium) 
    }
    static func caption() -> UIFont { 
        UIFont(name: newKansasName, size: 12) ?? .systemFont(ofSize: 12, weight: .regular) 
    }
}

// MARK: - Spacing

struct Spacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

struct CornerRadius {
    static let button: CGFloat = 12
    static let card: CGFloat = 20
    static let liquidGlass: CGFloat = 16
}

// MARK: - Liquid Glass Effects

struct LiquidGlassStyle {
    static func applyToView(_ view: UIView, tintColor: UIColor = .pmMint.withAlphaComponent(0.15)) {
        // Add blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = view.layer.cornerRadius
        blurView.clipsToBounds = true
        view.insertSubview(blurView, at: 0)
        
        // Add colored tint overlay
        let tintView = UIView(frame: view.bounds)
        tintView.backgroundColor = tintColor
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tintView.layer.cornerRadius = view.layer.cornerRadius
        tintView.clipsToBounds = true
        view.insertSubview(tintView, at: 1)
        
        // Add subtle border
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Add shadow for depth
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.08
    }
    
    static func applyToButton(_ button: UIButton, tintColor: UIColor = .pmCoral.withAlphaComponent(0.15)) {
        button.layer.cornerRadius = CornerRadius.liquidGlass
        button.clipsToBounds = false
        
        // Create container for blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.isUserInteractionEnabled = false
        blurView.layer.cornerRadius = CornerRadius.liquidGlass
        blurView.clipsToBounds = true
        
        // Add tint overlay
        let tintView = UIView()
        tintView.backgroundColor = tintColor
        tintView.isUserInteractionEnabled = false
        
        button.insertSubview(blurView, at: 0)
        button.insertSubview(tintView, at: 1)
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        tintView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: button.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            
            tintView.topAnchor.constraint(equalTo: button.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            tintView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: button.trailingAnchor)
        ])
        
        // Styling
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.1
    }
}

// MARK: - Gradient Background Helper

extension UIView {
    func addExcitingGradientBackground() {
        // Remove any existing gradient layers
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

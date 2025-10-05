//
//  FontHelper.swift
//  PM-App
//
//  Helper to verify and debug New Kansas fonts
//

import UIKit

struct FontHelper {
    /// Print all available font families and their font names
    /// Use this in AppDelegate or SceneDelegate to verify fonts are loaded
    static func printAvailableFonts() {
        print("\n=== Available Font Families ===")
        for family in UIFont.familyNames.sorted() {
            print("\nFamily: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
        print("\n=== End of Fonts ===\n")
    }
    
    /// Check if New Kansas fonts are loaded
    static func verifyNewKansasFonts() -> Bool {
        let newKansasRegular = UIFont(name: "NewKansas-Regular", size: 12)
        let newKansasMedium = UIFont(name: "NewKansas-Medium", size: 12)
        let newKansasBold = UIFont(name: "NewKansas-Bold", size: 12)
        
        if newKansasRegular == nil || newKansasMedium == nil || newKansasBold == nil {
            print("⚠️ New Kansas fonts not loaded properly!")
            print("Regular: \(newKansasRegular != nil ? "✓" : "✗")")
            print("Medium: \(newKansasMedium != nil ? "✓" : "✗")")
            print("Bold: \(newKansasBold != nil ? "✓" : "✗")")
            return false
        }
        
        print("✅ New Kansas fonts loaded successfully!")
        return true
    }
}

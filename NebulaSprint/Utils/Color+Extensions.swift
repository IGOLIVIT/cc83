//
//  Color+Extensions.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Theme colors
    static let nebulaBackground = Color(hex: "190127")
    static let nebulaAccent = Color(hex: "9EE806")
    static let nebulaButton = Color(hex: "A93DF7")
    
    // Neumorphic shadow colors
    var lighten: Color {
        self.adjust(by: 0.3)
    }
    
    var darken: Color {
        self.adjust(by: -0.3)
    }
    
    private func adjust(by percentage: Double) -> Color {
        guard let components = cgColor?.components, components.count >= 3 else {
            return self
        }
        
        return Color(
            .sRGB,
            red: min(max(components[0] + percentage, 0), 1),
            green: min(max(components[1] + percentage, 0), 1),
            blue: min(max(components[2] + percentage, 0), 1),
            opacity: components.count >= 4 ? components[3] : 1
        )
    }
}


//
//  NeumorphismStyle.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI

// MARK: - Neumorphic Button Style
struct NeumorphicButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var isPressed: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(backgroundColor)
                    
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(backgroundColor)
                            .shadow(color: backgroundColor.darken.opacity(0.7), radius: 5, x: 2, y: 2)
                            .shadow(color: backgroundColor.lighten.opacity(0.2), radius: 5, x: -2, y: -2)
                            .blendMode(.multiply)
                    } else {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(backgroundColor)
                            .shadow(color: backgroundColor.darken.opacity(0.5), radius: 10, x: 5, y: 5)
                            .shadow(color: backgroundColor.lighten.opacity(0.3), radius: 10, x: -5, y: -5)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Neumorphic Card Modifier
struct NeumorphicCard: ViewModifier {
    var backgroundColor: Color
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(color: backgroundColor.darken.opacity(0.5), radius: 10, x: 5, y: 5)
                    .shadow(color: backgroundColor.lighten.opacity(0.3), radius: 10, x: -5, y: -5)
            )
    }
}

// MARK: - Pressed Neumorphic Style
struct PressedNeumorphicStyle: ViewModifier {
    var backgroundColor: Color
    var cornerRadius: CGFloat = 15
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(backgroundColor.darken, lineWidth: 2)
                            .blur(radius: 4)
                            .offset(x: 2, y: 2)
                            .mask(RoundedRectangle(cornerRadius: cornerRadius).fill(LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(backgroundColor.lighten, lineWidth: 2)
                            .blur(radius: 4)
                            .offset(x: -2, y: -2)
                            .mask(RoundedRectangle(cornerRadius: cornerRadius).fill(LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .topLeading, endPoint: .bottomTrailing)))
                    )
            )
    }
}

// MARK: - View Extensions
extension View {
    func neumorphicCard(backgroundColor: Color, cornerRadius: CGFloat = 20) -> some View {
        self.modifier(NeumorphicCard(backgroundColor: backgroundColor, cornerRadius: cornerRadius))
    }
    
    func pressedNeumorphic(backgroundColor: Color, cornerRadius: CGFloat = 15) -> some View {
        self.modifier(PressedNeumorphicStyle(backgroundColor: backgroundColor, cornerRadius: cornerRadius))
    }
}



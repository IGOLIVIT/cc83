//
//  GameView.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var dragPosition: CGPoint?
    
    var body: some View {
        ZStack {
            // Background
            viewModel.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            // Animated stars background
            StarsBackgroundView()
            
            if viewModel.gameState == .menu {
                menuView
            } else if viewModel.gameState == .playing || viewModel.gameState == .paused {
                gameplayView
            } else if viewModel.gameState == .gameOver {
                gameOverView
            }
            
            // Lifestyle Challenge Overlay
            if viewModel.showLifestyleChallenge {
                lifestyleChallengeOverlay
            }
        }
    }
    
    // MARK: - Menu View
    private var menuView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Title
            VStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(viewModel.currentTheme.accentColor)
                
                Text("NebulaSprint")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Stats preview
            VStack(spacing: 15) {
                statRow(title: "High Score", value: "\(viewModel.scoreService.currentSession.highScore)")
                statRow(title: "Games Played", value: "\(viewModel.scoreService.currentSession.gamesPlayed)")
                statRow(title: "Cosmic Currency", value: "\(viewModel.scoreService.currentSession.cosmicCurrency)")
            }
            .padding()
            .neumorphicCard(backgroundColor: viewModel.currentTheme.backgroundColor.opacity(0.5))
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Start Button
            Button(action: {
                viewModel.startGame()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Game")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .buttonStyle(NeumorphicButtonStyle(backgroundColor: viewModel.currentTheme.buttonColor))
            .padding(.horizontal, 40)
            
            // Current Difficulty
            Text("Difficulty: \(viewModel.difficulty.rawValue.capitalized)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    // MARK: - Gameplay View
    private var gameplayView: some View {
        GeometryReader { geometry in
            ZStack {
                // Game area
                ForEach(viewModel.gameObjects) { object in
                    GameObjectView(object: object, theme: viewModel.currentTheme)
                }
                
                // Starship
                StarshipView(theme: viewModel.currentTheme)
                    .position(viewModel.starship.position)
                
                // HUD
                VStack {
                    HStack {
                        // Score
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(viewModel.currentTheme.accentColor)
                            Text("\(viewModel.score)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .pressedNeumorphic(backgroundColor: viewModel.currentTheme.backgroundColor.opacity(0.7))
                        
                        Spacer()
                        
                        // Pause button
                        Button(action: {
                            if viewModel.gameState == .playing {
                                viewModel.pauseGame()
                            } else {
                                viewModel.resumeGame()
                            }
                        }) {
                            Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                        }
                        .pressedNeumorphic(backgroundColor: viewModel.currentTheme.backgroundColor.opacity(0.7))
                    }
                    .padding()
                    
                    // Health bar
                    HStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.green, .yellow, .red]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(viewModel.starship.health) / 150)
                            }
                        }
                        .frame(height: 20)
                        
                        Text("\(viewModel.starship.health)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    .padding()
                    .pressedNeumorphic(backgroundColor: viewModel.currentTheme.backgroundColor.opacity(0.7))
                    .padding(.horizontal)
                    
                    Spacer()
                }
                
                // Pause overlay
                if viewModel.isPaused {
                    pauseOverlay
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        viewModel.moveStarship(to: value.location)
                    }
            )
        }
    }
    
    // MARK: - Game Over View
    private var gameOverView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Mission Complete!")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(viewModel.currentTheme.accentColor)
            
            VStack(spacing: 20) {
                resultRow(title: "Final Score", value: "\(viewModel.score)")
                resultRow(title: "High Score", value: "\(viewModel.scoreService.currentSession.highScore)")
                resultRow(title: "Distance", value: String(format: "%.0f", viewModel.distance))
                
                if viewModel.score == viewModel.scoreService.currentSession.highScore && viewModel.score > 0 {
                    Text("🎉 New High Score! 🎉")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.accentColor)
                }
            }
            .padding()
            .neumorphicCard(backgroundColor: viewModel.currentTheme.backgroundColor.opacity(0.5))
            .padding(.horizontal, 40)
            
            // Performance insight
            Text(viewModel.scoreService.getPerformanceInsight())
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Buttons
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.returnToMenu()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Menu")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(NeumorphicButtonStyle(backgroundColor: viewModel.currentTheme.backgroundColor.opacity(0.7)))
                
                Button(action: {
                    viewModel.startGame()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Play Again")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(NeumorphicButtonStyle(backgroundColor: viewModel.currentTheme.buttonColor))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Pause Overlay
    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Paused")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Button(action: {
                    viewModel.resumeGame()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 20)
                }
                .buttonStyle(NeumorphicButtonStyle(backgroundColor: viewModel.currentTheme.buttonColor))
                
                Button(action: {
                    viewModel.returnToMenu()
                }) {
                    Text("Exit to Menu")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Lifestyle Challenge Overlay
    private var lifestyleChallengeOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Image(systemName: viewModel.currentLifestyleChallenge?.category.icon ?? "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(viewModel.currentLifestyleChallenge?.category.color ?? .white)
                
                Text("Lifestyle Challenge!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    Text(viewModel.currentLifestyleChallenge?.title ?? "")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.accentColor)
                    
                    Text(viewModel.currentLifestyleChallenge?.description ?? "")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Reward: +\(viewModel.currentLifestyleChallenge?.reward ?? 0) points")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.buttonColor)
                }
                .padding()
                .neumorphicCard(backgroundColor: viewModel.currentTheme.backgroundColor.opacity(0.5))
                .padding(.horizontal, 40)
                
                VStack(spacing: 15) {
                    Button(action: {
                        viewModel.completeLifestyleChallenge()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(NeumorphicButtonStyle(backgroundColor: viewModel.currentTheme.buttonColor))
                    
                    Button(action: {
                        viewModel.skipLifestyleChallenge()
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.currentTheme.accentColor)
        }
    }
    
    private func resultRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.currentTheme.accentColor)
        }
    }
}

// MARK: - Stars Background View
struct StarsBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { _ in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...900)
                    )
            }
        }
        .offset(y: animate ? 900 : 0)
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

// MARK: - Game Object View
struct GameObjectView: View {
    let object: GameObject
    let theme: GameTheme
    
    var body: some View {
        Circle()
            .fill(object.color)
            .frame(width: 30, height: 30)
            .shadow(color: object.color.opacity(0.6), radius: 10)
            .overlay(
                Image(systemName: iconForObject)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .bold))
            )
            .position(object.position)
            .opacity(object.isCollected ? 0 : 1)
    }
    
    private var iconForObject: String {
        switch object.type {
        case .obstacle: return "xmark"
        case .bonus: return "star.fill"
        case .cosmicBonus: return "sparkles"
        case .healthBonus: return "heart.fill"
        }
    }
}

// MARK: - Starship View
struct StarshipView: View {
    let theme: GameTheme
    
    var body: some View {
        ZStack {
            // Main body
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [theme.buttonColor, theme.accentColor]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 40, height: 50)
            
            // Wings
            HStack(spacing: 30) {
                Triangle()
                    .fill(theme.buttonColor)
                    .frame(width: 15, height: 20)
                Triangle()
                    .fill(theme.buttonColor)
                    .frame(width: 15, height: 20)
            }
            
            // Cockpit
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 15, height: 15)
                .offset(y: -10)
        }
        .shadow(color: theme.accentColor.opacity(0.6), radius: 10)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}


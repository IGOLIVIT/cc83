//
//  GameModel.swift
//  NebulaSprint
//
//  Created on 2025
//

import Foundation
import SwiftUI

// MARK: - Game State
enum GameState {
    case menu
    case playing
    case paused
    case gameOver
}

// MARK: - Difficulty Level
enum DifficultyLevel: String, Codable {
    case easy
    case medium
    case hard
    case cosmic
    
    var speedMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.3
        case .hard: return 1.6
        case .cosmic: return 2.0
        }
    }
    
    var obstacleFrequency: Double {
        switch self {
        case .easy: return 3.5  // Увеличил с 2.5 до 3.5 секунд
        case .medium: return 2.5  // Увеличил с 2.0 до 2.5 секунд
        case .hard: return 2.0  // Увеличил с 1.5 до 2.0 секунд
        case .cosmic: return 1.5  // Увеличил с 1.0 до 1.5 секунд
        }
    }
}

// MARK: - Game Object
struct GameObject: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var type: ObjectType
    var isCollected: Bool = false
    
    enum ObjectType {
        case obstacle
        case bonus
        case cosmicBonus
        case healthBonus
    }
    
    var color: Color {
        switch type {
        case .obstacle: return .red
        case .bonus: return Color(hex: "9EE806")
        case .cosmicBonus: return Color(hex: "A93DF7")
        case .healthBonus: return .blue
        }
    }
    
    var points: Int {
        switch type {
        case .obstacle: return -10
        case .bonus: return 10
        case .cosmicBonus: return 50
        case .healthBonus: return 25
        }
    }
}

// MARK: - Starship
struct Starship {
    var position: CGPoint
    var health: Int = 150  // Увеличил с 100 до 150
    var shield: Bool = false
    var speed: Double = 1.0
    
    mutating func takeDamage(_ amount: Int) {
        if shield {
            shield = false
        } else {
            health = max(0, health - amount)
        }
    }
    
    mutating func heal(_ amount: Int) {
        health = min(150, health + amount)  // Увеличил максимум с 100 до 150
    }
}

// MARK: - Game Session
struct GameSession: Codable {
    var score: Int = 0
    var highScore: Int = 0
    var distance: Double = 0
    var gamesPlayed: Int = 0
    var lifestyleChallengesCompleted: Int = 0
    var currentStreak: Int = 0
    var cosmicCurrency: Int = 0
    var unlockedThemes: [String] = ["default"]
    var selectedTheme: String = "default"
    var difficulty: DifficultyLevel = .easy
    var averageScore: Double = 0.0
    var totalPlayTime: TimeInterval = 0
    var lastPlayDate: Date?
    
    mutating func updateAfterGame(finalScore: Int, playTime: TimeInterval) {
        gamesPlayed += 1
        totalPlayTime += playTime
        lastPlayDate = Date()
        
        // Update high score
        if finalScore > highScore {
            highScore = finalScore
        }
        
        // Calculate average score
        averageScore = ((averageScore * Double(gamesPlayed - 1)) + Double(finalScore)) / Double(gamesPlayed)
        
        // Adaptive difficulty
        if averageScore > 500 && difficulty == .easy {
            difficulty = .medium
        } else if averageScore > 1000 && difficulty == .medium {
            difficulty = .hard
        } else if averageScore > 2000 && difficulty == .hard {
            difficulty = .cosmic
        }
    }
    
    mutating func completeLifestyleChallenge(reward: Int) {
        lifestyleChallengesCompleted += 1
        currentStreak += 1
        cosmicCurrency += reward
    }
    
    mutating func unlockTheme(_ themeName: String) {
        if !unlockedThemes.contains(themeName) {
            unlockedThemes.append(themeName)
        }
    }
    
    mutating func reset() {
        score = 0
        highScore = 0
        distance = 0
        gamesPlayed = 0
        lifestyleChallengesCompleted = 0
        currentStreak = 0
        cosmicCurrency = 0
        unlockedThemes = ["default"]
        selectedTheme = "default"
        difficulty = .easy
        averageScore = 0.0
        totalPlayTime = 0
        lastPlayDate = nil
    }
}

// MARK: - Theme
struct GameTheme: Identifiable {
    let id: String
    let name: String
    let backgroundColor: Color
    let accentColor: Color
    let buttonColor: Color
    let cost: Int
    let description: String
    
    static let themes: [GameTheme] = [
        GameTheme(id: "default", name: "Nebula Night", 
                  backgroundColor: Color(hex: "190127"),
                  accentColor: Color(hex: "9EE806"),
                  buttonColor: Color(hex: "A93DF7"),
                  cost: 0,
                  description: "The classic cosmic experience"),
        GameTheme(id: "solar", name: "Solar Flare",
                  backgroundColor: Color(hex: "1A0B02"),
                  accentColor: Color(hex: "FF6B35"),
                  buttonColor: Color(hex: "F7B731"),
                  cost: 100,
                  description: "Blazing through the sun's corona"),
        GameTheme(id: "aurora", name: "Aurora Borealis",
                  backgroundColor: Color(hex: "001529"),
                  accentColor: Color(hex: "00F5FF"),
                  buttonColor: Color(hex: "52C41A"),
                  cost: 200,
                  description: "Northern lights guide your way"),
        GameTheme(id: "galaxy", name: "Galaxy Core",
                  backgroundColor: Color(hex: "0A0E1A"),
                  accentColor: Color(hex: "B794F4"),
                  buttonColor: Color(hex: "ED64A6"),
                  cost: 300,
                  description: "Journey to the heart of the galaxy"),
        GameTheme(id: "void", name: "Deep Void",
                  backgroundColor: Color(hex: "000000"),
                  accentColor: Color(hex: "FFFFFF"),
                  buttonColor: Color(hex: "4A5568"),
                  cost: 500,
                  description: "The emptiness between stars")
    ]
    
    static func theme(for id: String) -> GameTheme {
        themes.first { $0.id == id } ?? themes[0]
    }
}

// MARK: - Lifestyle Challenge
struct LifestyleChallenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: ChallengeCategory
    let reward: Int
    var isCompleted: Bool = false
    var completionDate: Date?
    
    enum ChallengeCategory: String, Codable {
        case hydration
        case movement
        case mindfulness
        case rest
        case nutrition
        
        var icon: String {
            switch self {
            case .hydration: return "drop.fill"
            case .movement: return "figure.walk"
            case .mindfulness: return "brain.head.profile"
            case .rest: return "moon.stars.fill"
            case .nutrition: return "leaf.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .hydration: return .blue
            case .movement: return Color(hex: "9EE806")
            case .mindfulness: return Color(hex: "A93DF7")
            case .rest: return .indigo
            case .nutrition: return .green
            }
        }
    }
    
    static func dailyChallenges() -> [LifestyleChallenge] {
        [
            LifestyleChallenge(id: "water1", title: "Hydration Boost",
                             description: "Drink a glass of water",
                             category: .hydration, reward: 25),
            LifestyleChallenge(id: "stretch1", title: "Quick Stretch",
                             description: "Do a 2-minute stretch break",
                             category: .movement, reward: 30),
            LifestyleChallenge(id: "breathe1", title: "Deep Breathing",
                             description: "Take 5 deep breaths",
                             category: .mindfulness, reward: 20),
            LifestyleChallenge(id: "walk1", title: "Short Walk",
                             description: "Walk for 5 minutes",
                             category: .movement, reward: 40),
            LifestyleChallenge(id: "posture1", title: "Posture Check",
                             description: "Adjust your sitting posture",
                             category: .movement, reward: 15),
            LifestyleChallenge(id: "eyes1", title: "Eye Rest",
                             description: "Look away from screen for 20 seconds",
                             category: .rest, reward: 20),
            LifestyleChallenge(id: "snack1", title: "Healthy Snack",
                             description: "Eat a fruit or vegetable",
                             category: .nutrition, reward: 35),
            LifestyleChallenge(id: "mindful1", title: "Mindful Moment",
                             description: "Take a 1-minute mindfulness pause",
                             category: .mindfulness, reward: 25)
        ]
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let playerName: String
    let score: Int
    let date: Date
    let gamesPlayed: Int
    let averageScore: Double
    let lifestyleChallenges: Int
    
    var performanceRating: String {
        if averageScore >= 2000 {
            return "Cosmic Legend"
        } else if averageScore >= 1000 {
            return "Star Navigator"
        } else if averageScore >= 500 {
            return "Space Explorer"
        } else {
            return "Nebula Cadet"
        }
    }
}


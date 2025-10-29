//
//  ScoreService.swift
//  NebulaSprint
//
//  Created on 2025
//

import Foundation
import Combine

class ScoreService: ObservableObject {
    @Published var currentSession: GameSession
    @Published var leaderboard: [LeaderboardEntry] = []
    
    private let sessionKey = "gameSession"
    private let leaderboardKey = "leaderboard"
    private let playerNameKey = "playerName"
    
    init() {
        // Load saved session
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let session = try? JSONDecoder().decode(GameSession.self, from: data) {
            self.currentSession = session
        } else {
            self.currentSession = GameSession()
        }
        
        // Load leaderboard
        loadLeaderboard()
    }
    
    // MARK: - Session Management
    func saveSession() {
        if let encoded = try? JSONEncoder().encode(currentSession) {
            UserDefaults.standard.set(encoded, forKey: sessionKey)
        }
    }
    
    func updateScore(_ newScore: Int, playTime: TimeInterval) {
        currentSession.score = newScore
        currentSession.updateAfterGame(finalScore: newScore, playTime: playTime)
        saveSession()
        
        // Add to leaderboard if it's a notable score
        if newScore > 0 {
            addToLeaderboard(score: newScore)
        }
    }
    
    func addCosmicCurrency(_ amount: Int) {
        currentSession.cosmicCurrency += amount
        saveSession()
    }
    
    func spendCosmicCurrency(_ amount: Int) -> Bool {
        guard currentSession.cosmicCurrency >= amount else {
            return false
        }
        currentSession.cosmicCurrency -= amount
        saveSession()
        return true
    }
    
    func completeLifestyleChallenge(_ challenge: LifestyleChallenge) {
        currentSession.completeLifestyleChallenge(reward: challenge.reward)
        saveSession()
    }
    
    func unlockTheme(_ themeId: String) {
        currentSession.unlockTheme(themeId)
        saveSession()
    }
    
    func selectTheme(_ themeId: String) {
        currentSession.selectedTheme = themeId
        saveSession()
    }
    
    func resetAllProgress() {
        currentSession.reset()
        saveSession()
        leaderboard.removeAll()
        saveLeaderboard()
    }
    
    // MARK: - Leaderboard Management
    private func loadLeaderboard() {
        if let data = UserDefaults.standard.data(forKey: leaderboardKey),
           let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) {
            self.leaderboard = entries.sorted { $0.score > $1.score }
        }
    }
    
    private func saveLeaderboard() {
        if let encoded = try? JSONEncoder().encode(leaderboard) {
            UserDefaults.standard.set(encoded, forKey: leaderboardKey)
        }
    }
    
    func addToLeaderboard(score: Int) {
        let playerName = UserDefaults.standard.string(forKey: playerNameKey) ?? "Space Explorer"
        
        let entry = LeaderboardEntry(
            id: UUID().uuidString,
            playerName: playerName,
            score: score,
            date: Date(),
            gamesPlayed: currentSession.gamesPlayed,
            averageScore: currentSession.averageScore,
            lifestyleChallenges: currentSession.lifestyleChallengesCompleted
        )
        
        leaderboard.append(entry)
        leaderboard.sort { $0.score > $1.score }
        
        // Keep only top 100 entries
        if leaderboard.count > 100 {
            leaderboard = Array(leaderboard.prefix(100))
        }
        
        saveLeaderboard()
    }
    
    func getPlayerRank() -> Int? {
        let playerName = UserDefaults.standard.string(forKey: playerNameKey) ?? "Space Explorer"
        return leaderboard.firstIndex { $0.playerName == playerName && $0.score == currentSession.highScore }
    }
    
    func getTopEntries(limit: Int = 10) -> [LeaderboardEntry] {
        Array(leaderboard.prefix(limit))
    }
    
    // MARK: - Analytics & Insights
    func getPerformanceInsight() -> String {
        let avgScore = currentSession.averageScore
        let highScore = currentSession.highScore
        let improvement = highScore > 0 ? (avgScore / Double(highScore)) * 100 : 0
        
        if improvement >= 80 {
            return "🌟 Consistent Excellence! You're performing at \(Int(improvement))% of your best."
        } else if improvement >= 60 {
            return "📈 Strong Progress! You're at \(Int(improvement))% of your peak performance."
        } else if improvement >= 40 {
            return "🚀 Room to Grow! Focus on avoiding obstacles to boost your average."
        } else {
            return "💫 Keep Practicing! Every game makes you better."
        }
    }
    
    func getSuggestedDifficulty() -> DifficultyLevel {
        return currentSession.difficulty
    }
    
    func getPlaytimeFormatted() -> String {
        let hours = Int(currentSession.totalPlayTime) / 3600
        let minutes = (Int(currentSession.totalPlayTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    func setPlayerName(_ name: String) {
        UserDefaults.standard.set(name, forKey: playerNameKey)
    }
    
    func getPlayerName() -> String {
        UserDefaults.standard.string(forKey: playerNameKey) ?? "Space Explorer"
    }
}


//
//  SettingsViewModel.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var showDeleteConfirmation = false
    @Published var showThemeStore = false
    
    var settingsService: SettingsService
    var scoreService: ScoreService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(settingsService: SettingsService, scoreService: ScoreService) {
        self.settingsService = settingsService
        self.scoreService = scoreService
    }
    
    // MARK: - Settings Actions
    func toggleNotifications() {
        settingsService.notificationsEnabled.toggle()
    }
    
    func toggleSound() {
        settingsService.soundEnabled.toggle()
    }
    
    func toggleHaptics() {
        settingsService.hapticsEnabled.toggle()
    }
    
    func toggleLifestyleChallenges() {
        settingsService.lifestyleChallengesEnabled.toggle()
    }
    
    func togglePerformanceStats() {
        settingsService.showPerformanceStats.toggle()
    }
    
    func updateReminderTime(_ time: Date) {
        settingsService.dailyReminderTime = time
    }
    
    // MARK: - Theme Management
    func getAvailableThemes() -> [GameTheme] {
        GameTheme.themes
    }
    
    func isThemeUnlocked(_ themeId: String) -> Bool {
        scoreService.currentSession.unlockedThemes.contains(themeId)
    }
    
    func purchaseTheme(_ theme: GameTheme) -> Bool {
        guard !isThemeUnlocked(theme.id) else { return false }
        
        if scoreService.spendCosmicCurrency(theme.cost) {
            scoreService.unlockTheme(theme.id)
            return true
        }
        return false
    }
    
    func selectTheme(_ themeId: String) {
        guard isThemeUnlocked(themeId) else { return }
        scoreService.selectTheme(themeId)
    }
    
    func getCurrentTheme() -> GameTheme {
        GameTheme.theme(for: scoreService.currentSession.selectedTheme)
    }
    
    // MARK: - Account Management
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        settingsService.deleteAccount { [weak self] success in
            if success {
                self?.scoreService.resetAllProgress()
            }
            completion(success)
        }
    }
    
    func confirmDelete() {
        showDeleteConfirmation = true
    }
    
    // MARK: - Statistics
    func getStats() -> [StatItem] {
        let session = scoreService.currentSession
        return [
            StatItem(title: "High Score", value: "\(session.highScore)", icon: "star.fill", color: .yellow),
            StatItem(title: "Games Played", value: "\(session.gamesPlayed)", icon: "gamecontroller.fill", color: Color.nebulaAccent),
            StatItem(title: "Average Score", value: String(format: "%.0f", session.averageScore), icon: "chart.line.uptrend.xyaxis", color: .blue),
            StatItem(title: "Cosmic Currency", value: "\(session.cosmicCurrency)", icon: "bitcoinsign.circle.fill", color: Color.nebulaButton),
            StatItem(title: "Challenges Completed", value: "\(session.lifestyleChallengesCompleted)", icon: "checkmark.circle.fill", color: .green),
            StatItem(title: "Current Streak", value: "\(session.currentStreak)", icon: "flame.fill", color: .orange),
            StatItem(title: "Total Playtime", value: scoreService.getPlaytimeFormatted(), icon: "clock.fill", color: .purple),
            StatItem(title: "Difficulty", value: session.difficulty.rawValue.capitalized, icon: "gauge.high", color: .red)
        ]
    }
    
    func getPerformanceInsight() -> String {
        scoreService.getPerformanceInsight()
    }
    
    struct StatItem: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
        let color: Color
    }
}


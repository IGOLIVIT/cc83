//
//  SettingsService.swift
//  NebulaSprint
//
//  Created on 2025
//

import Foundation
import Combine
import UserNotifications

class SettingsService: ObservableObject {
    @Published var notificationsEnabled: Bool
    @Published var soundEnabled: Bool
    @Published var hapticsEnabled: Bool
    @Published var lifestyleChallengesEnabled: Bool
    @Published var dailyReminderTime: Date
    @Published var showPerformanceStats: Bool
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        self.lifestyleChallengesEnabled = UserDefaults.standard.object(forKey: "lifestyleChallengesEnabled") as? Bool ?? true
        self.showPerformanceStats = UserDefaults.standard.object(forKey: "showPerformanceStats") as? Bool ?? true
        
        if let savedTime = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date {
            self.dailyReminderTime = savedTime
        } else {
            // Default to 9 AM
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            self.dailyReminderTime = Calendar.current.date(from: components) ?? Date()
        }
        
        // Setup observers
        setupObservers()
    }
    
    private func setupObservers() {
        $notificationsEnabled
            .dropFirst()
            .sink { [weak self] value in
                UserDefaults.standard.set(value, forKey: "notificationsEnabled")
                if value {
                    self?.requestNotificationPermission()
                } else {
                    self?.disableNotifications()
                }
            }
            .store(in: &cancellables)
        
        $soundEnabled
            .dropFirst()
            .sink { value in
                UserDefaults.standard.set(value, forKey: "soundEnabled")
            }
            .store(in: &cancellables)
        
        $hapticsEnabled
            .dropFirst()
            .sink { value in
                UserDefaults.standard.set(value, forKey: "hapticsEnabled")
            }
            .store(in: &cancellables)
        
        $lifestyleChallengesEnabled
            .dropFirst()
            .sink { value in
                UserDefaults.standard.set(value, forKey: "lifestyleChallengesEnabled")
            }
            .store(in: &cancellables)
        
        $dailyReminderTime
            .dropFirst()
            .sink { [weak self] value in
                UserDefaults.standard.set(value, forKey: "dailyReminderTime")
                if self?.notificationsEnabled == true {
                    self?.scheduleDailyReminder()
                }
            }
            .store(in: &cancellables)
        
        $showPerformanceStats
            .dropFirst()
            .sink { value in
                UserDefaults.standard.set(value, forKey: "showPerformanceStats")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notification Management
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.scheduleDailyReminder()
                } else {
                    self.notificationsEnabled = false
                }
            }
        }
    }
    
    private func disableNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleDailyReminder() {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "NebulaSprint Awaits! 🚀"
        content.body = "Ready for another cosmic adventure? Complete your daily challenges!"
        content.sound = soundEnabled ? .default : nil
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: dailyReminderTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func sendLifestyleChallengeNotification(challenge: LifestyleChallenge) {
        guard notificationsEnabled && lifestyleChallengesEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New Lifestyle Challenge! 🌟"
        content.body = challenge.title
        content.sound = soundEnabled ? .default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Account Management
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        // Clear all user defaults related to the app
        let keys = [
            "gameSession",
            "leaderboard",
            "playerName",
            "hasCompletedOnboarding",
            "notificationsEnabled",
            "soundEnabled",
            "hapticsEnabled",
            "lifestyleChallengesEnabled",
            "dailyReminderTime",
            "showPerformanceStats",
            "completedChallenges",
            "lastChallengeDate"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Remove all notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Reset settings to defaults
        DispatchQueue.main.async {
            self.notificationsEnabled = false
            self.soundEnabled = true
            self.hapticsEnabled = true
            self.lifestyleChallengesEnabled = true
            self.showPerformanceStats = true
            
            completion(true)
        }
    }
    
    // MARK: - Data Export
    func exportGameData() -> String {
        var data = "NebulaSprint Game Data Export\n"
        data += "Generated: \(Date())\n\n"
        
        if let sessionData = UserDefaults.standard.data(forKey: "gameSession"),
           let session = try? JSONDecoder().decode(GameSession.self, from: sessionData) {
            data += "High Score: \(session.highScore)\n"
            data += "Games Played: \(session.gamesPlayed)\n"
            data += "Average Score: \(String(format: "%.1f", session.averageScore))\n"
            data += "Cosmic Currency: \(session.cosmicCurrency)\n"
            data += "Lifestyle Challenges: \(session.lifestyleChallengesCompleted)\n"
            data += "Current Streak: \(session.currentStreak)\n"
            data += "Difficulty: \(session.difficulty.rawValue)\n"
            data += "Unlocked Themes: \(session.unlockedThemes.joined(separator: ", "))\n"
        }
        
        return data
    }
    
    func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}


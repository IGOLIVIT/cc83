//
//  OnboardingViewModel.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var playerName: String = ""
    @Published var selectedDifficulty: DifficultyLevel = .easy
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    let totalPages = 4
    let scoreService: ScoreService
    
    init(scoreService: ScoreService) {
        self.scoreService = scoreService
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    var canProceed: Bool {
        switch currentPage {
        case 2:
            return !playerName.isEmpty
        default:
            return true
        }
    }
    
    var progressPercentage: Double {
        Double(currentPage) / Double(totalPages - 1)
    }
    
    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        }
    }
    
    func previousPage() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }
    
    func completeOnboarding() {
        scoreService.setPlayerName(playerName.isEmpty ? "Space Explorer" : playerName)
        scoreService.currentSession.difficulty = selectedDifficulty
        scoreService.saveSession()
        
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
    
    func resetOnboarding() {
        currentPage = 0
        playerName = ""
        selectedDifficulty = .easy
        hasCompletedOnboarding = false
    }
    
    // MARK: - Page Content
    struct OnboardingPage {
        let title: String
        let description: String
        let icon: String
        let color: Color
    }
    
    func getPageContent() -> OnboardingPage {
        switch currentPage {
        case 0:
            return OnboardingPage(
                title: "Welcome to NebulaSprint",
                description: "Embark on an epic cosmic journey through the stars. Navigate your starship, collect bonuses, and avoid obstacles in this dynamic space adventure!",
                icon: "sparkles",
                color: Color.nebulaAccent
            )
        case 1:
            return OnboardingPage(
                title: "Lifestyle Challenges",
                description: "Take breaks with mini wellness challenges! Earn cosmic currency and bonuses by completing real-world health goals during your adventure.",
                icon: "heart.fill",
                color: Color.nebulaButton
            )
        case 2:
            return OnboardingPage(
                title: "Choose Your Identity",
                description: "What shall we call you, space explorer? Your name will appear on leaderboards and track your cosmic achievements.",
                icon: "person.fill",
                color: Color.nebulaAccent
            )
        case 3:
            return OnboardingPage(
                title: "Select Difficulty",
                description: "Choose your starting challenge level. Don't worry - the game adapts to your performance and will adjust difficulty as you improve!",
                icon: "gauge.high",
                color: Color.nebulaButton
            )
        default:
            return OnboardingPage(
                title: "",
                description: "",
                icon: "",
                color: .clear
            )
        }
    }
}


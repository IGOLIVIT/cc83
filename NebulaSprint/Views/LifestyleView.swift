//
//  LifestyleView.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI

struct LifestyleView: View {
    @ObservedObject var scoreService: ScoreService
    @State private var challenges: [LifestyleChallenge] = []
    @State private var completedChallenges: Set<String> = []
    
    var currentTheme: GameTheme {
        GameTheme.theme(for: scoreService.currentSession.selectedTheme)
    }
    
    var body: some View {
        ZStack {
            currentTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(currentTheme.accentColor)
                        
                        Text("Lifestyle Challenges")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Take care of yourself while you play")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Stats
                    HStack(spacing: 20) {
                        statCard(
                            title: "Completed",
                            value: "\(scoreService.currentSession.lifestyleChallengesCompleted)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        statCard(
                            title: "Streak",
                            value: "\(scoreService.currentSession.currentStreak)",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        statCard(
                            title: "Rewards",
                            value: "\(scoreService.currentSession.cosmicCurrency)",
                            icon: "bitcoinsign.circle.fill",
                            color: currentTheme.buttonColor
                        )
                    }
                    .padding(.horizontal)
                    
                    // Categories
                    VStack(spacing: 15) {
                        Text("Daily Challenges")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        ForEach(groupedChallenges.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { category in
                            CategorySection(
                                category: category,
                                challenges: groupedChallenges[category] ?? [],
                                completedChallenges: $completedChallenges,
                                theme: currentTheme,
                                onComplete: { challenge in
                                    completeChallenge(challenge)
                                }
                            )
                        }
                    }
                    
                    // Benefits info
                    VStack(spacing: 15) {
                        Text("Why It Matters")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        benefitCard(
                            icon: "brain.head.profile",
                            title: "Mental Wellness",
                            description: "Regular breaks improve focus and reduce stress"
                        )
                        
                        benefitCard(
                            icon: "figure.walk",
                            title: "Physical Health",
                            description: "Movement prevents strain and boosts energy"
                        )
                        
                        benefitCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Better Performance",
                            description: "Healthier habits lead to better gameplay"
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            loadChallenges()
            loadCompletedChallenges()
        }
    }
    
    // MARK: - Grouped Challenges
    private var groupedChallenges: [LifestyleChallenge.ChallengeCategory: [LifestyleChallenge]] {
        Dictionary(grouping: challenges, by: { $0.category })
    }
    
    // MARK: - Helper Views
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .neumorphicCard(backgroundColor: currentTheme.backgroundColor.opacity(0.5))
    }
    
    private func benefitCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(currentTheme.accentColor)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .neumorphicCard(backgroundColor: currentTheme.backgroundColor.opacity(0.5))
    }
    
    // MARK: - Data Management
    private func loadChallenges() {
        challenges = LifestyleChallenge.dailyChallenges()
    }
    
    private func loadCompletedChallenges() {
        if let data = UserDefaults.standard.data(forKey: "completedChallenges"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            
            // Check if it's a new day
            if let lastDate = UserDefaults.standard.object(forKey: "lastChallengeDate") as? Date {
                if !Calendar.current.isDateInToday(lastDate) {
                    completedChallenges = []
                    saveCompletedChallenges()
                } else {
                    completedChallenges = decoded
                }
            } else {
                completedChallenges = decoded
            }
        }
    }
    
    private func saveCompletedChallenges() {
        if let encoded = try? JSONEncoder().encode(completedChallenges) {
            UserDefaults.standard.set(encoded, forKey: "completedChallenges")
            UserDefaults.standard.set(Date(), forKey: "lastChallengeDate")
        }
    }
    
    private func completeChallenge(_ challenge: LifestyleChallenge) {
        completedChallenges.insert(challenge.id)
        scoreService.completeLifestyleChallenge(challenge)
        saveCompletedChallenges()
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: LifestyleChallenge.ChallengeCategory
    let challenges: [LifestyleChallenge]
    @Binding var completedChallenges: Set<String>
    let theme: GameTheme
    let onComplete: (LifestyleChallenge) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text(category.rawValue.capitalized)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            ForEach(challenges) { challenge in
                ChallengeCard(
                    challenge: challenge,
                    isCompleted: completedChallenges.contains(challenge.id),
                    theme: theme,
                    onComplete: {
                        onComplete(challenge)
                    }
                )
            }
        }
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let challenge: LifestyleChallenge
    let isCompleted: Bool
    let theme: GameTheme
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(challenge.category.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: challenge.category.icon)
                    .foregroundColor(challenge.category.color)
                    .font(.system(size: 24))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 5) {
                Text(challenge.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(challenge.description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("+\(challenge.reward) rewards")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(theme.accentColor)
            }
            
            Spacer()
            
            // Complete button
            Button(action: {
                if !isCompleted {
                    onComplete()
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(isCompleted ? .green : .white.opacity(0.5))
            }
            .disabled(isCompleted)
        }
        .padding()
        .neumorphicCard(backgroundColor: theme.backgroundColor.opacity(0.5))
        .padding(.horizontal)
        .opacity(isCompleted ? 0.6 : 1.0)
    }
}


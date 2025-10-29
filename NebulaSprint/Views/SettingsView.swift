//
//  SettingsView.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showThemeStore = false
    
    var currentTheme: GameTheme {
        viewModel.getCurrentTheme()
    }
    
    var body: some View {
        ZStack {
            currentTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 60))
                            .foregroundColor(currentTheme.accentColor)
                        
                        Text("Settings")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                    
                    // Statistics Section
                    statisticsSection
                    
                    // Game Settings Section
                    gameSettingsSection
                    
                    // Notifications Section
                    notificationsSection
                    
                    // Theme Section
                    themeSection
                    
                    // Danger Zone
                    dangerZoneSection
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showThemeStore) {
            ThemeStoreView(viewModel: viewModel, currentTheme: currentTheme)
        }
        .alert("Delete Account", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteAccount { success in
                    // User will be automatically sent to onboarding
                }
            }
        } message: {
            Text("This will permanently delete all your progress, scores, and data. This action cannot be undone.")
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(spacing: 15) {
            sectionHeader(title: "Your Stats", icon: "chart.bar.fill")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(viewModel.getStats()) { stat in
                    statCard(stat: stat)
                }
            }
            .padding(.horizontal)
            
            // Performance Insight
            Text(viewModel.getPerformanceInsight())
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding()
                .neumorphicCard(backgroundColor: currentTheme.backgroundColor.opacity(0.5))
                .padding(.horizontal)
        }
    }
    
    private func statCard(stat: SettingsViewModel.StatItem) -> some View {
        VStack(spacing: 8) {
            Image(systemName: stat.icon)
                .font(.system(size: 24))
                .foregroundColor(stat.color)
            
            Text(stat.value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(stat.title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .neumorphicCard(backgroundColor: currentTheme.backgroundColor.opacity(0.5))
    }
    
    // MARK: - Game Settings Section
    private var gameSettingsSection: some View {
        VStack(spacing: 15) {
            sectionHeader(title: "Game Settings", icon: "gamecontroller.fill")
            
            settingToggle(
                title: "Haptic Feedback",
                icon: "iphone.radiowaves.left.and.right",
                isOn: Binding(
                    get: { viewModel.settingsService.hapticsEnabled },
                    set: { viewModel.settingsService.hapticsEnabled = $0 }
                )
            )
            
            settingToggle(
                title: "Lifestyle Challenges",
                icon: "heart.fill",
                isOn: Binding(
                    get: { viewModel.settingsService.lifestyleChallengesEnabled },
                    set: { viewModel.settingsService.lifestyleChallengesEnabled = $0 }
                )
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        VStack(spacing: 15) {
            sectionHeader(title: "Notifications", icon: "bell.fill")
            
            settingToggle(
                title: "Enable Notifications",
                icon: "bell.badge.fill",
                isOn: Binding(
                    get: { viewModel.settingsService.notificationsEnabled },
                    set: { viewModel.settingsService.notificationsEnabled = $0 }
                )
            )
            
            if viewModel.settingsService.notificationsEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(currentTheme.accentColor)
                        Text("Daily Reminder")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    DatePicker("Time", selection: Binding(
                        get: { viewModel.settingsService.dailyReminderTime },
                        set: { viewModel.settingsService.dailyReminderTime = $0 }
                    ), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                }
                .padding()
                .neumorphicCard(backgroundColor: currentTheme.backgroundColor.opacity(0.5))
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Theme Section
    private var themeSection: some View {
        VStack(spacing: 15) {
            sectionHeader(title: "Themes", icon: "paintbrush.fill")
            
            Button(action: {
                showThemeStore = true
            }) {
                HStack {
                    Image(systemName: "cart.fill")
                        .foregroundColor(currentTheme.accentColor)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Theme Store")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Current: \(currentTheme.name)")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 5) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundColor(currentTheme.buttonColor)
                        Text("\(viewModel.scoreService.currentSession.cosmicCurrency)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()
                .neumorphicCard(backgroundColor: currentTheme.backgroundColor.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - Danger Zone Section
    private var dangerZoneSection: some View {
        VStack(spacing: 15) {
            sectionHeader(title: "Danger Zone", icon: "exclamationmark.triangle.fill")
            
            Button(action: {
                viewModel.confirmDelete()
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    
                    Text("Delete Account")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding()
                .neumorphicCard(backgroundColor: currentTheme.backgroundColor.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Views
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(currentTheme.accentColor)
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func settingToggle(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(currentTheme.accentColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(currentTheme.accentColor)
        }
        .padding()
        .neumorphicCard(backgroundColor: currentTheme.backgroundColor.opacity(0.5))
    }
}

// MARK: - Theme Store View
struct ThemeStoreView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    let currentTheme: GameTheme
    
    var body: some View {
        ZStack {
            currentTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("Theme Store")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 5) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundColor(currentTheme.buttonColor)
                        Text("\(viewModel.scoreService.currentSession.cosmicCurrency)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(viewModel.getAvailableThemes()) { theme in
                            ThemeCard(
                                theme: theme,
                                isUnlocked: viewModel.isThemeUnlocked(theme.id),
                                isSelected: theme.id == viewModel.scoreService.currentSession.selectedTheme,
                                onSelect: {
                                    viewModel.selectTheme(theme.id)
                                },
                                onPurchase: {
                                    _ = viewModel.purchaseTheme(theme)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Theme Card
struct ThemeCard: View {
    let theme: GameTheme
    let isUnlocked: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // Theme preview
            HStack(spacing: 15) {
                // Color preview
                HStack(spacing: 8) {
                    Circle()
                        .fill(theme.backgroundColor)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    
                    Circle()
                        .fill(theme.accentColor)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .fill(theme.buttonColor)
                        .frame(width: 30, height: 30)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(theme.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(theme.description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Action button
            if isUnlocked {
                if !isSelected {
                    Button(action: onSelect) {
                        Text("Select")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(NeumorphicButtonStyle(backgroundColor: theme.buttonColor))
                }
            } else {
                Button(action: onPurchase) {
                    HStack {
                        Image(systemName: "bitcoinsign.circle.fill")
                        Text("Unlock for \(theme.cost)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(NeumorphicButtonStyle(backgroundColor: theme.buttonColor.opacity(0.7)))
            }
        }
        .padding()
        .neumorphicCard(backgroundColor: theme.backgroundColor.opacity(0.5))
    }
}


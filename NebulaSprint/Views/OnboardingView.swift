//
//  OnboardingView.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void
    
    var currentTheme: GameTheme {
        GameTheme.theme(for: "default")
    }
    
    var body: some View {
        ZStack {
            currentTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index <= viewModel.currentPage ? currentTheme.accentColor : Color.white.opacity(0.3))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 60)
                
                Spacer()
                
                // Page content
                pageContent
                
                Spacer()
                
                // Navigation buttons
                navigationButtons
                    .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Page Content
    @ViewBuilder
    private var pageContent: some View {
        let page = viewModel.getPageContent()
        
        VStack(spacing: 30) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.color)
            
            Text(page.title)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text(page.description)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Special content for specific pages
            if viewModel.currentPage == 2 {
                nameInputSection
            } else if viewModel.currentPage == 3 {
                difficultySelectionSection
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Name Input Section
    private var nameInputSection: some View {
        VStack(spacing: 15) {
            TextField("Enter your name", text: $viewModel.playerName)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(currentTheme.backgroundColor.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(currentTheme.accentColor.opacity(0.5), lineWidth: 2)
                        )
                )
                .padding(.horizontal, 40)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
            
            Text("This will be your cosmic identity")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    // MARK: - Difficulty Selection Section
    private var difficultySelectionSection: some View {
        VStack(spacing: 15) {
            ForEach([DifficultyLevel.easy, .medium, .hard, .cosmic], id: \.self) { difficulty in
                Button(action: {
                    withAnimation {
                        viewModel.selectedDifficulty = difficulty
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(difficulty.rawValue.capitalized)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(difficultyDescription(for: difficulty))
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: viewModel.selectedDifficulty == difficulty ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.selectedDifficulty == difficulty ? currentTheme.accentColor : .white.opacity(0.5))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                viewModel.selectedDifficulty == difficulty ?
                                currentTheme.buttonColor.opacity(0.3) :
                                currentTheme.backgroundColor.opacity(0.5)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                viewModel.selectedDifficulty == difficulty ?
                                currentTheme.accentColor :
                                Color.white.opacity(0.2),
                                lineWidth: 2
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 40)
    }
    
    private func difficultyDescription(for difficulty: DifficultyLevel) -> String {
        switch difficulty {
        case .easy:
            return "Perfect for beginners"
        case .medium:
            return "A balanced challenge"
        case .hard:
            return "For experienced pilots"
        case .cosmic:
            return "Maximum difficulty"
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            // Back button
            if viewModel.currentPage > 0 {
                Button(action: {
                    viewModel.previousPage()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(NeumorphicButtonStyle(backgroundColor: currentTheme.backgroundColor.opacity(0.7)))
            }
            
            Spacer()
            
            // Next/Complete button
            Button(action: {
                if viewModel.currentPage < viewModel.totalPages - 1 {
                    viewModel.nextPage()
                } else {
                    viewModel.completeOnboarding()
                    onComplete()
                }
            }) {
                HStack {
                    Text(viewModel.currentPage < viewModel.totalPages - 1 ? "Next" : "Start Adventure")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    
                    if viewModel.currentPage < viewModel.totalPages - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
            }
            .buttonStyle(NeumorphicButtonStyle(backgroundColor: currentTheme.buttonColor))
            .disabled(!viewModel.canProceed)
            .opacity(viewModel.canProceed ? 1.0 : 0.5)
        }
        .padding(.horizontal, 40)
    }
}


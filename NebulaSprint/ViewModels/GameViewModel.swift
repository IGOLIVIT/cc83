//
//  GameViewModel.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var gameState: GameState = .menu
    @Published var starship: Starship
    @Published var gameObjects: [GameObject] = []
    @Published var score: Int = 0
    @Published var distance: Double = 0
    @Published var isPaused: Bool = false
    @Published var showLifestyleChallenge: Bool = false
    @Published var currentLifestyleChallenge: LifestyleChallenge?
    
    private var timer: Timer?
    private var objectSpawnTimer: Timer?
    private var gameStartTime: Date?
    private var lastChallengeTime: Date?
    
    var scoreService: ScoreService
    var settingsService: SettingsService
    
    var currentTheme: GameTheme {
        GameTheme.theme(for: scoreService.currentSession.selectedTheme)
    }
    
    var difficulty: DifficultyLevel {
        scoreService.currentSession.difficulty
    }
    
    init(scoreService: ScoreService, settingsService: SettingsService) {
        self.scoreService = scoreService
        self.settingsService = settingsService
        self.starship = Starship(position: CGPoint(x: 200, y: 400), health: 150)
    }
    
    // MARK: - Game Control
    func startGame() {
        resetGame()
        gameState = .playing
        gameStartTime = Date()
        score = 0
        distance = 0
        starship = Starship(position: CGPoint(x: 200, y: 400), health: 150)
        
        print("🎮 Game Started - Health: \(starship.health)")
        
        startGameLoop()
        
        // Задержка перед спавном объектов - даем игроку время
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.startObjectSpawning()
        }
    }
    
    func pauseGame() {
        gameState = .paused
        isPaused = true
        timer?.invalidate()
        objectSpawnTimer?.invalidate()
    }
    
    func resumeGame() {
        gameState = .playing
        isPaused = false
        startGameLoop()
        startObjectSpawning()
    }
    
    func endGame() {
        gameState = .gameOver
        timer?.invalidate()
        objectSpawnTimer?.invalidate()
        
        // Calculate play time
        let playTime = Date().timeIntervalSince(gameStartTime ?? Date())
        scoreService.updateScore(score, playTime: playTime)
        
        // Trigger haptic feedback
        if settingsService.hapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    func resetGame() {
        timer?.invalidate()
        objectSpawnTimer?.invalidate()
        gameObjects.removeAll()
        score = 0
        distance = 0
        isPaused = false
        showLifestyleChallenge = false
        currentLifestyleChallenge = nil
    }
    
    func returnToMenu() {
        resetGame()
        gameState = .menu
    }
    
    // MARK: - Game Loop
    private func startGameLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
    }
    
    private func updateGame() {
        guard gameState == .playing else { return }
        
        let speedMultiplier = difficulty.speedMultiplier
        distance += 0.1 * speedMultiplier
        
        // Update game objects
        for i in gameObjects.indices {
            gameObjects[i].position.y += CGFloat(2.0 * speedMultiplier)
            
            // Check collision with starship
            if !gameObjects[i].isCollected && checkCollision(with: gameObjects[i]) {
                handleCollision(with: gameObjects[i])
                gameObjects[i].isCollected = true
            }
        }
        
        // Remove off-screen objects
        gameObjects.removeAll { $0.position.y > 900 || $0.isCollected }
        
        // Check for lifestyle challenge trigger
        if settingsService.lifestyleChallengesEnabled {
            checkForLifestyleChallenge()
        }
        
        // Check game over
        if starship.health <= 0 {
            print("💀 Game Over - Health: \(starship.health), Score: \(score)")
            endGame()
        }
    }
    
    private func startObjectSpawning() {
        let spawnInterval = difficulty.obstacleFrequency
        
        objectSpawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { [weak self] _ in
            self?.spawnRandomObject()
        }
    }
    
    private func spawnRandomObject() {
        let screenWidth: CGFloat = 400
        let randomX = CGFloat.random(in: 50...(screenWidth - 50))
        let randomType = Int.random(in: 0...100)
        
        let objectType: GameObject.ObjectType
        // Изменил баланс: меньше препятствий, больше бонусов
        if randomType < 25 {  // 25% препятствий (было 50%)
            objectType = .obstacle
        } else if randomType < 75 {  // 50% обычных бонусов
            objectType = .bonus
        } else if randomType < 95 {  // 20% космических бонусов
            objectType = .cosmicBonus
        } else {  // 5% бонусов здоровья
            objectType = .healthBonus
        }
        
        let newObject = GameObject(
            position: CGPoint(x: randomX, y: -50),
            velocity: CGPoint(x: 0, y: 2),
            type: objectType
        )
        
        gameObjects.append(newObject)
    }
    
    // MARK: - Collision Detection
    private func checkCollision(with object: GameObject) -> Bool {
        let distance = hypot(
            starship.position.x - object.position.x,
            starship.position.y - object.position.y
        )
        // Уменьшил радиус столкновения с 30 до 25
        return distance < 25
    }
    
    private func handleCollision(with object: GameObject) {
        switch object.type {
        case .obstacle:
            print("💥 Hit obstacle - Health before: \(starship.health)")
            starship.takeDamage(15)  // Уменьшил урон с 20 до 15
            print("💥 Hit obstacle - Health after: \(starship.health)")
            score = max(0, score + object.points)
            triggerHaptic(style: .heavy)
            
        case .bonus:
            score += object.points
            print("⭐ Collected bonus - Score: \(score)")
            triggerHaptic(style: .light)
            
        case .cosmicBonus:
            score += object.points
            scoreService.addCosmicCurrency(5)
            print("✨ Collected cosmic bonus - Score: \(score)")
            triggerHaptic(style: .medium)
            
        case .healthBonus:
            print("❤️ Health bonus - Health before: \(starship.health)")
            starship.heal(25)
            print("❤️ Health bonus - Health after: \(starship.health)")
            score += object.points
            triggerHaptic(style: .light)
        }
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settingsService.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // MARK: - Starship Control
    func moveStarship(to position: CGPoint) {
        guard gameState == .playing else { return }
        
        // Smooth movement with boundaries
        let maxX: CGFloat = 380
        let minX: CGFloat = 20
        let maxY: CGFloat = 800
        let minY: CGFloat = 100
        
        let newX = min(max(position.x, minX), maxX)
        let newY = min(max(position.y, minY), maxY)
        
        withAnimation(.linear(duration: 0.1)) {
            starship.position = CGPoint(x: newX, y: newY)
        }
    }
    
    // MARK: - Lifestyle Challenges
    private func checkForLifestyleChallenge() {
        // Show challenge every 2 minutes of gameplay or every 500 points
        guard currentLifestyleChallenge == nil else { return }
        
        let shouldShowTimeBase = lastChallengeTime == nil || 
            Date().timeIntervalSince(lastChallengeTime ?? Date()) > 120
        let shouldShowScoreBase = score > 0 && score % 500 == 0
        
        if shouldShowTimeBase || shouldShowScoreBase {
            presentRandomLifestyleChallenge()
            lastChallengeTime = Date()
        }
    }
    
    func presentRandomLifestyleChallenge() {
        let challenges = LifestyleChallenge.dailyChallenges()
        if let challenge = challenges.randomElement() {
            currentLifestyleChallenge = challenge
            showLifestyleChallenge = true
            pauseGame()
        }
    }
    
    func completeLifestyleChallenge() {
        guard let challenge = currentLifestyleChallenge else { return }
        
        scoreService.completeLifestyleChallenge(challenge)
        score += challenge.reward
        
        // Heal starship as bonus
        starship.heal(15)
        
        showLifestyleChallenge = false
        currentLifestyleChallenge = nil
        
        triggerHaptic(style: .success)
        
        // Resume after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.resumeGame()
        }
    }
    
    func skipLifestyleChallenge() {
        showLifestyleChallenge = false
        currentLifestyleChallenge = nil
        resumeGame()
    }
    
    // MARK: - Cleanup
    deinit {
        timer?.invalidate()
        objectSpawnTimer?.invalidate()
    }
}

// MARK: - Haptic Extensions
extension UIImpactFeedbackGenerator.FeedbackStyle {
    static let success = UIImpactFeedbackGenerator.FeedbackStyle.medium
}


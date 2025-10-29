//
//  AppEntry.swift
//  NebulaSprint
//
//  Created on 2025
//

import SwiftUI

@main
struct NebulaSprint: App {
    @StateObject private var scoreService = ScoreService()
    @StateObject private var settingsService = SettingsService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scoreService)
                .environmentObject(settingsService)
        }
    }
}



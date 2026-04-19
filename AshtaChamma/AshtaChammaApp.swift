//
//  AshtaChammaApp.swift
//  AshtaChamma
//
//  Created by Shailesh Srigiri on 4/4/26.
//

import SwiftUI
import FirebaseCore

@main
struct AshtaChammaApp: App {
    @StateObject var authViewModel = AuthViewModel()

    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn {
                NavigationStack {
                    HomeView()
                }
            } else {
                NavigationStack {
                    OpeningView()
                }
            }
        }
    }
}

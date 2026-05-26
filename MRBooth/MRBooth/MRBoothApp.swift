//
//  MRBoothApp.swift
//  MRBooth
//

import SwiftUI

@main
struct MRBoothApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    init() {
        AppAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

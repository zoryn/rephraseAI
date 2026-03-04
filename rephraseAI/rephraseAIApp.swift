//
//  rephraseAIApp.swift
//  rephraseAI
//
//  Created by Zoryn, Konstantin on 3/3/26.
//

import SwiftUI

@main
struct rephraseAIApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No scenes needed — menu bar app with no main window.
        // Settings window is managed directly by AppDelegate.
        Settings { EmptyView() }
    }
}

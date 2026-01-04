//
//  CookingTimerApp.swift
//  CookingTimerApp
//
//  Main application entry point
//

import SwiftUI

/// Main application entry point
@main
struct CookingTimerApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .windowStyle(.automatic)
        .commands {
            // Add custom menu commands
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Recipe") {
                Button("New Recipe...") {
                    // TODO: Handle new recipe action
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Button("Import from URL...") {
                    // TODO: Handle import action
                }
                .keyboardShortcut("i", modifiers: .command)
            }

            CommandMenu("Timers") {
                Button("Start All") {
                    // TODO: Handle start all action
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Pause All") {
                    // TODO: Handle pause all action
                }
                .keyboardShortcut("p", modifiers: .command)

                Button("Cancel All") {
                    // TODO: Handle cancel all action
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])
            }
        }
    }
}

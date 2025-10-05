//
//  DynamicHelperApp.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//

import SwiftUI

@main
struct DynamicHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        MenuBarExtra("DynamicHelper", systemImage: "macbook.gen2") {
            Text("動態劉海")
            Button("設定") {
                appDelegate.showSettingsWindow()
            }
            .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            Divider()
            Button("重啟動態劉海") {
                guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }

                let workspace = NSWorkspace.shared

                if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier)
                {

                    let configuration = NSWorkspace.OpenConfiguration()
                    configuration.createsNewApplicationInstance = true

                    workspace.openApplication(at: appURL, configuration: configuration)
                }

                NSApplication.shared.terminate(self)
            }
            .keyboardShortcut(KeyEquivalent("r"), modifiers: [.command,.option])
            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(self)
            }
            .keyboardShortcut(KeyEquivalent("Q"), modifiers: .command)
        }
    }
}

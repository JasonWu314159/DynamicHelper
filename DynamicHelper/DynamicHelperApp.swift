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
        // 不需要 UI scene，因為視窗已在 AppDelegate 中處理
        
        Settings {
            SettingsView()
        } // 避免沒有任何 Scene 警告
        
//        Window("Settings", id: "Settings") {
//            SettingsView()
//        }
////        .windowStyle(.hiddenTitleBar)
//        .windowResizability(.contentSize)
    }
}

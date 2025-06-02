//
//  ScreenMonitor.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/5/29.
//

import AppKit
import Cocoa

class ScreenMonitor {
    var appDelegate: AppDelegate
    
    init(_ app: AppDelegate) {
        appDelegate = app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        print("🔧 螢幕監聽已啟用")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleScreenChange(notification: Notification) {
        print("🖥️ 螢幕設定變更")
        for (index, screen) in NSScreen.screens.enumerated() {
            print("螢幕 \(index): frame = \(screen.frame)")
        }
        DispatchQueue.main.async {
            islandTypeManager.refreshIsland()
        }
        // 你也可以在這裡加上自動調整視窗或通知 AppDelegate 的邏輯
    }
    
    func moveWindowToBuiltInDisplay(
        window: NSWindow,
        winType:IslandTypeManager.IslandType = islandTypeManager.getNowIslandType()
    ) {
        var size = IslandTypeManager.getWindowSize(winType)
        let sizeDelta: CGFloat = IslandTypeManager.getWindowRadius(winType).up*2
        size.height += sizeDelta
        let screen = getNowScreen()
        let frame = NSRect(
            origin: NSPoint(
                x: screen.frame.origin.x + screen.frame.size.width / 2 - size.width / 2,
                y: screen.frame.origin.y + screen.frame.size.height-size.height+IslandTypeManager.EdgeToTop
            ),
            size: size
        )
        window.setFrame(frame, display: true, animate: false)
    }
}

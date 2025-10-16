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
    static var nowScreen:NSScreen = NSScreen()
    
    init(_ app: AppDelegate) {
        appDelegate = app
        ScreenMonitor.nowScreen = ScreenMonitor.getNowScreen()
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
        print(NSScreen.screens)
        ScreenMonitor.nowScreen = ScreenMonitor.getNowScreen()
        for (index, screen) in NSScreen.screens.enumerated() {
            print("螢幕 \(index): frame = \(screen.frame)")
        }
        DispatchQueue.main.async {
            IslandTypeManager.shared.refreshIsland()
        }
        // 你也可以在這裡加上自動調整視窗或通知 AppDelegate 的邏輯
    }
    
    func refreshWindowSize(
        window: NSWindow,
        winType:IslandTypeManager.IslandType = IslandTypeManager.shared.getNowIslandType()
    ) {
        var size = IslandTypeManager.getWindowSize(winType)
        let sizeDelta: CGFloat = IslandTypeManager.getWindowRadius(winType).up*2
        size.height += sizeDelta
        refreshWindowSize(window: window, size:size)
    }
    
    func refreshWindowSize(window: NSWindow,size: CGSize = IslandTypeManager.shared.getNowWindowSize()){
        let screen = ScreenMonitor.getNowScreen()
        let frame = NSRect(
            origin: NSPoint(
                x: screen.frame.origin.x + screen.frame.size.width / 2 - size.width / 2,
                y: screen.frame.origin.y + screen.frame.size.height-size.height+IslandTypeManager.EdgeToTop
            ),
            size: size
        )
        window.setFrame(frame, display: true, animate: false)
    }
    
    
    
    static func getNowScreen() -> NSScreen {
        let Screens = getAllScreenInfo()
        var screen:NSScreen
        if(defaultWindowPos == -1){
            for i in Screens{
                if i.isBuiltin{
                    return i.screen
                }
            }
            screen = Screens[0].screen
        }else if(defaultWindowPos < Screens.count){
            screen = Screens[defaultWindowPos].screen
        }else{
            screen = Screens[Screens.count-1].screen
        }
        return screen
    }
    
}

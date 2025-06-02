//
//  AppDelegate.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var settingsWindow: NSWindow?
    var space = CGSSpace(level: Int(INT_MAX))
    private var settingsWindowDelegate: SettingsWindowDelegate?
    var powerMonitor: PowerMonitor?
    
    var islandView: IslandView!
    let hoverState = HoverState()
    var delegate:SettingsWindowDelegate!
    var keepAliveTimer: Timer?
    var keepAliveActivity: NSObjectProtocol?
    
    var screenMonitor: ScreenMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        getSettings()
        islandView = IslandView(hoverState: hoverState,appDelegate: self)
//            .environmentObject(windowState) as! IslandView as IslandView
        powerMonitor = PowerMonitor()
        screenMonitor = ScreenMonitor(self)
        let hostView = NSHostingView(rootView: islandView)
        let contentSize = hostView.fittingSize // 取得實際尺寸
        
        let screenWidth = NSScreen.main?.frame.width ?? 800
        let windowWidth: CGFloat = contentSize.width
        let windowHeight: CGFloat = contentSize.height
        
        let rect = NSRect(x: (screenWidth - windowWidth) / 2,
                          y: NSScreen.main!.frame.height-windowHeight+IslandTypeManager.EdgeToTop,
                          width: windowWidth,
                          height: windowHeight)
        
        window = DynamicWindow(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered, defer: false
        )
        window.level = NSWindow.Level(rawValue: 200)//min:102 max:500
        window.ignoresMouseEvents = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,.stationary]
        
        window.contentView = hostView
        window.makeKeyAndOrderFront(nil)
        space.windows.insert(window)
        startKeepAliveTimer()
        preventAppNap()
//        powerMonitor = PowerMonitor()
    }
    
    func update(type: IslandTypeManager.IslandType) {
        // 找出內建螢幕（即 MacBook 自帶的螢幕）
        guard let win = self.window else { return }
        screenMonitor.moveWindowToBuiltInDisplay(window:win, winType: type)
    }
    
    
    func preventAppNap() {
        keepAliveActivity = ProcessInfo.processInfo.beginActivity(
            options: [.idleSystemSleepDisabled, .userInitiated],
            reason: "Prevent App Nap for Dynamic Island"
        )
    }
    
    func startKeepAliveTimer() {
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.window?.orderFrontRegardless()
            NSLog("KeepAliveTimer triggered - Window still alive")
        }
    }
    
    func showSettingsWindow() {
        if settingsWindow == nil {
            let size: CGSize = .init(width: 500, height: 200)
            let origin: CGPoint = .init(x: (NSScreen.main?.frame.width ?? 0) / 2 - size.width / 2,
                                        y: (NSScreen.main?.frame.height ?? 0) / 2 - size.height / 2)
            
            let window = NSWindow(
                contentRect: NSRect(origin: origin, size: size),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false)
            
            window.title = "設定"
            window.level = NSWindow.Level(rawValue: 200)//min:102 max:500
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView())
            delegate = SettingsWindowDelegate(appDelegate: self)
            window.delegate = delegate
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,.stationary]
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        screenMonitor = nil // 自動 deinit 時會 removeObserver
    }
}


final class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func windowWillClose(_ notification: Notification) {
        appDelegate?.settingsWindow = nil
        saveSettings()
    }
}

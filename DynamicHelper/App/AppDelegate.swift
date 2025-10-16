//
//  AppDelegate.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//

import SwiftUI
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var settingsWindow: NSWindow?
    var RemoteControlChooseWindow: NSWindow?
    var space = CGSSpace(level: Int(INT_MAX))
    var settingsWindowDelegate: SettingsWindowDelegate!
    var powerMonitor: PowerMonitor?
    
    var islandView: IslandView!
    var remoteControlChooseWindowDelegate:RemoteControlChooseWindowDelegate!
    var isProgrammaticallyClosingRemoteControlWindow = false
    var keepAliveTimer: Timer?
    var keepAliveActivity: NSObjectProtocol?
    
    var screenMonitor: ScreenMonitor!
    
    

    func applicationDidFinishLaunching(_ notification: Notification) {
        getSettings()
        islandView = IslandView(
            hoverState: HoverState.IslandHoverState,
            appDelegate: self
        )
        powerMonitor = PowerMonitor()
        screenMonitor = ScreenMonitor(self)
        SetShortCutKey()
        LoginObserver(notification)
        let _ = CPULoadReader.shared.read()
        
        
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
    }
    
    func update(type: IslandTypeManager.IslandType) {
        guard let win = self.window else { return }
        screenMonitor.refreshWindowSize(window:win, winType: type)
    }
    
    func update(size: CGSize) {
        guard let win = self.window else { return }
        screenMonitor.refreshWindowSize(window:win, size:size)
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
    
    func applicationWillTerminate(_ notification: Notification) {
        screenMonitor = nil // 自動 deinit 時會 removeObserver
        DeleteAllCopyFile()
    }
    
    
}



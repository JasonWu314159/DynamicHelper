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

    func applicationDidFinishLaunching(_ notification: Notification) {
        refreshResize()
        getSettings()
        islandView = IslandView(hoverState: hoverState,appDelegate: self)
//            .environmentObject(windowState) as! IslandView as IslandView
        powerMonitor = PowerMonitor(windowState)
        let hostView = NSHostingView(rootView: islandView)
        let contentSize = hostView.fittingSize // 取得實際尺寸
        
        let screenWidth = NSScreen.main?.frame.width ?? 800
        let windowWidth: CGFloat = contentSize.width
        let windowHeight: CGFloat = contentSize.height
        
        let rect = NSRect(x: (screenWidth - windowWidth) / 2,
                          y: NSScreen.main!.frame.height-windowHeight+EdgeToTop,
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
        
        window.contentView = NSHostingView(rootView: islandView)
        window.makeKeyAndOrderFront(nil)
        space.windows.insert(window)
        
        
//        powerMonitor = PowerMonitor()
    }
    
    func update(type: WindowType) {
        
        guard let win = self.window else { return }
        var size = getWindowSize(type)
        let screen = NSScreen.main?.visibleFrame ?? .zero
        let sizeDelta: CGFloat = getWindowRadius(type).up*2
        size.height += sizeDelta
        let origin = CGPoint(x: (screen.width - size.width) / 2,
                             y: NSScreen.main!.frame.height-size.height+EdgeToTop)
        win.setFrame(NSRect(origin: origin, size: size), display: true, animate: false)
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

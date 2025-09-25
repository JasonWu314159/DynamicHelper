//
//  Setting.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//

import SwiftUI
import AppKit
import CoreGraphics
import LaunchAtLogin

struct ScreenInfo:Identifiable, Hashable {
    let id = UUID()
    let index: Int
    let screen: NSScreen
    let displayID: CGDirectDisplayID
    let isBuiltin: Bool
    var name: String {
        if index == 0{
            return "主要顯示器"
        }
        return "延伸顯示器 \(index)"
    }
}

func getAllScreenInfo() -> [ScreenInfo] {
    NSScreen.screens.enumerated().compactMap { (index, screen) in
        guard let screenID = screen.deviceDescription[.init("NSScreenNumber")] as? CGDirectDisplayID else {
            return nil
        }
        let isBuiltin = CGDisplayIsBuiltin(screenID) != 0
        return ScreenInfo(index: index, screen: screen, displayID: screenID, isBuiltin: isBuiltin)
    }
}

struct SettingsView: View {
    @State private var selectedItem: String = "home"
    
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                NavigationLink(value: "home"){
                    Label("基本", systemImage: "gear")
                }
                NavigationLink(value: "CopyBook"){
                    Label("剪貼簿", systemImage: "document.on.clipboard")
                }
            }
            .listStyle(SidebarListStyle())
            .toolbar(removing: .sidebarToggle)
            .frame(minWidth: 200, maxWidth: 200)
        } detail: {
            Group{
                switch selectedItem{
                case "home":
                    FundationSetting()
                case "CopyBook":
                    CopyBookSetting()
                default:
                    FundationSetting()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        //            .frame(minWidth: 200, maxWidth: 200)
        .onDisappear{
            saveSettings()
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(removing: .sidebarToggle)
        .toolbar {
            Button(action: {
                saveSettings()
                NSApp.terminate(nil)
            })
            {
                Image( systemName: "power.circle.fill")
                    .resizable()
                    .scaledToFit()
            }
        }
        .formStyle(.grouped)
        .frame(width: 700)
        .background(Color(NSColor.windowBackgroundColor))
        
    }
    
}

struct GlassEffectIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content//glassEffect()
        } else {
            content
        }
    }
}




//var defaultWindowType:WindowType = .exten
//var lastWindowType:WindowType = .exten
var shouldSaveCopyBook:Bool = false
var defaultWindowPos:Int = 0


func saveSettings() {
    UserDefaults.standard.set(islandTypeManager.defaultWindowType.rawValue, forKey: "defaultWindowType")
    UserDefaults.standard.set(islandTypeManager.lastWindowType.rawValue, forKey: "lastWindowType")
    UserDefaults.standard.set(shouldSaveCopyBook, forKey: "shouldSaveCopyBook")
    UserDefaults.standard.set(defaultWindowPos, forKey: "defaultWindowPos")
    if(shouldSaveCopyBook){
        UserDefaults.standard.set(StringStorage.shared.Item, forKey: "CopyBook")
    }
    getSettings()
}


func getSettings() {
    
    if let raw = UserDefaults.standard.string(forKey: "lastWindowType"),
       let type = IslandTypeManager.IslandType(rawValue: raw) {
        islandTypeManager.lastWindowType = type
    }
    if let raw = UserDefaults.standard.string(forKey: "defaultWindowPos"),
       let Pos = Int(raw) {
        defaultWindowPos = Pos
    }
    if let raw = UserDefaults.standard.string(forKey: "defaultWindowType"),
       let type = IslandTypeManager.IslandType(rawValue: raw) {
        islandTypeManager.defaultWindowType = type
        if(islandTypeManager.defaultWindowType != .hide){islandTypeManager.lastWindowType = islandTypeManager.defaultWindowType}
    }
    shouldSaveCopyBook = UserDefaults.standard.bool(forKey: "shouldSaveCopyBook")
    if(shouldSaveCopyBook){
        StringStorage.shared.Item = (UserDefaults.standard.array(forKey: "CopyBook") ?? []) as! [(String,Bool)]
    }
    
}


extension AppDelegate {
    func showSettingsWindow() {
        if settingsWindow == nil {
            let size: CGSize = .init(width: 700, height: 400)
            let origin: CGPoint = .init(x: (NSScreen.main?.frame.width ?? 0) / 2 - size.width / 2,
                                        y: (NSScreen.main?.frame.height ?? 0) / 2 - size.height / 2)
            
            let window = NSWindow(
                contentRect: NSRect(origin: origin, size: size),
                styleMask: [.titled,.closable,.fullSizeContentView],
                backing: .buffered,
                defer: false)
            
            window.title = "設定"
            window.level = NSWindow.Level(rawValue: 200)//min:102 max:500
            window.isReleasedWhenClosed = false
//            window.styleMask.remove(.resizable) 
            window.contentView = NSHostingView(rootView: SettingsView())
            settingsWindowDelegate = SettingsWindowDelegate(appDelegate: self)
            window.delegate = settingsWindowDelegate
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,.stationary,.managed, .participatesInCycle]
            window.isMovableByWindowBackground = true
            window.hidesOnDeactivate = false
            window.isExcludedFromWindowsMenu = false
            window.toolbarStyle = .unified
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = true
//            window.windowToolbarSeparator = 
            window.identifier = NSUserInterfaceItemIdentifier("DynamicHelperSettingsWindow")

            
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



#Preview {
    SettingsView()
}

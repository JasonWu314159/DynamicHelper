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
    @State private var selectedItem: String = "基本"
    
    
    var body: some View {
        HStack{
            List(selection: $selectedItem) {
                Text("基本").tag("基本")
                    .font(.subheadline)
                Text("剪貼簿").tag("CopyBook")
                    .font(.subheadline)
            }
            SettingsBody(selectedItem: $selectedItem)
        }
        .onDisappear{
            saveSettings()
        }
    }
}

struct SettingsBody: View {
    @Binding var selectedItem: String
    @State private var homeViewType: IslandTypeManager.IslandType = .exten
    @State private var shouldSaveCopyBook_: Bool = false
    @State private var SelectWindowPos: Int = -1
    
    
    var body: some View{
        
        VStack{
            if(selectedItem == "基本"){
                HStack{
                    Text("初始畫面")
                    Spacer()
                    Picker("", selection: $homeViewType) {
                        Text("上一次打開").tag(IslandTypeManager.IslandType.hide)
                        Text("預設").tag(IslandTypeManager.IslandType.exten)
                        Text("檔案").tag(IslandTypeManager.IslandType.Drop)
                    }.onAppear {
                        saveSettings()
                        homeViewType = islandTypeManager.defaultWindowType
                    }
                    .onChange(of: homeViewType) { _ ,newValue in
                        islandTypeManager.defaultWindowType = newValue
                        saveSettings()
                    }
                    .frame(width: 150)
                }
                HStack{
                    Text("視窗位置")
                    Spacer()
                    Picker("", selection: $SelectWindowPos) {
                        Text("內建顯示器").tag(-1)
                        ForEach(getAllScreenInfo()){item in
                            Text(item.name).tag(item.index)                            
                        }
                    }.onAppear {
                        saveSettings()
                        SelectWindowPos = defaultWindowPos
                    }
                    .onChange(of: SelectWindowPos) { _ ,newValue in
                        defaultWindowPos = newValue
                        saveSettings()
                        islandTypeManager.OutsideChangeIslandType(to: .hide,EnforceChange: true)
                    }
                    .frame(width: 150)
                }
                Spacer()
                HStack{
                    Text("登入時啟動")
                    Spacer()
                    LaunchAtLogin.Toggle("")
                }
                
            }
            else if(selectedItem == "CopyBook"){
                HStack{
                    Text("結束是否儲存剪貼簿")
                    Spacer()
                    Picker("", selection: $shouldSaveCopyBook_) {
                        Text("是").tag(true)
                        Text("否").tag(false)
                    }.onAppear {
                        saveSettings()
                        shouldSaveCopyBook_ = shouldSaveCopyBook
                    }
                    .onChange(of: shouldSaveCopyBook_) { _ ,newValue in
                        shouldSaveCopyBook = newValue
                        saveSettings()
                    }
                    .frame(width: 100)
                }
                
                HStack{
                    Text("清除剪貼簿")
                    Spacer()
                    Button(action: {
                        StringStorage.shared.Item = []
                        saveSettings()
                    }) {
                        Text("清除")
                    }
                }
            }
            
            Spacer()
            Button(action: {
                saveSettings()
                NSApp.terminate(nil)
            }) {
                Label("退出程式", systemImage: "power.circle.fill")
            }
        }.frame(width: 350)
            .padding()
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
            settingsWindowDelegate = SettingsWindowDelegate(appDelegate: self)
            window.delegate = settingsWindowDelegate
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



//#Preview {
//    SettingsView()
//}

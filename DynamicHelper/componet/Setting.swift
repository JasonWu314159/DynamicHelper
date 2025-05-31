//
//  Setting.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//

import SwiftUI
import AppKit
import CoreGraphics

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
    @State private var homeViewType: WindowType = WindowType.exten
    @State private var shouldSaveCopyBook_: Bool = false
    @State private var SelectWindowPos: Int = -1
    
    
    var body: some View{
        
        VStack{
            if(selectedItem == "基本"){
                HStack{
                    Text("初始畫面")
                    Spacer()
                    Picker("", selection: $homeViewType) {
                        Text("上一次打開").tag(WindowType.hide)
                        Text("預設").tag(WindowType.exten)
                        Text("檔案").tag(WindowType.Drop)
                    }.onAppear {
                        saveSettings()
                        homeViewType = defaultWindowType
                    }
                    .onChange(of: homeViewType) { _ ,newValue in
                        defaultWindowType = newValue
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
                        refreshResize()
                        windowState.ousideEnforceChange = true
                        windowState.outsideChange = .hide
                    }
                    .frame(width: 150)
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
                        stringStorage.Item = []
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




var defaultWindowType:WindowType = .exten
var lastWindowType:WindowType = .exten
var shouldSaveCopyBook:Bool = false
var defaultWindowPos:Int = 0


func saveSettings() {
    UserDefaults.standard.set(defaultWindowType.rawValue, forKey: "defaultWindowType")
    UserDefaults.standard.set(lastWindowType.rawValue, forKey: "lastWindowType")
    UserDefaults.standard.set(shouldSaveCopyBook, forKey: "shouldSaveCopyBook")
    UserDefaults.standard.set(defaultWindowPos, forKey: "defaultWindowPos")
    if(shouldSaveCopyBook){
        UserDefaults.standard.set(stringStorage.Item, forKey: "CopyBook")
    }
    getSettings()
}


func getSettings() {
    
    if let raw = UserDefaults.standard.string(forKey: "lastWindowType"),
       let type = WindowType(rawValue: raw) {
        lastWindowType = type
    }
    if let raw = UserDefaults.standard.string(forKey: "defaultWindowPos"),
       let Pos = Int(raw) {
        defaultWindowPos = Pos
    }
    if let raw = UserDefaults.standard.string(forKey: "defaultWindowType"),
       let type = WindowType(rawValue: raw) {
        defaultWindowType = type
        if(defaultWindowType != .hide){lastWindowType = defaultWindowType}
    }
    shouldSaveCopyBook = UserDefaults.standard.bool(forKey: "shouldSaveCopyBook")
    if(shouldSaveCopyBook){
        stringStorage.Item = (UserDefaults.standard.array(forKey: "CopyBook") ?? []) as! [(String,Bool)]
    }
    
}



//#Preview {
//    SettingsView()
//}

//
//  Setting.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//

import SwiftUI

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
                    .frame(width: 100)
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


func saveSettings() {
    UserDefaults.standard.set(defaultWindowType.rawValue, forKey: "defaultWindowType")
    UserDefaults.standard.set(lastWindowType.rawValue, forKey: "lastWindowType")
    UserDefaults.standard.set(shouldSaveCopyBook, forKey: "shouldSaveCopyBook")
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
    if let raw = UserDefaults.standard.string(forKey: "defaultWindowType"),
       let type = WindowType(rawValue: raw) {
        defaultWindowType = type
        if(defaultWindowType != .hide){lastWindowType = defaultWindowType}
    }
    shouldSaveCopyBook = UserDefaults.standard.bool(forKey: "shouldSaveCopyBook")
    if(shouldSaveCopyBook){
        stringStorage.Item = (UserDefaults.standard.array(forKey: "CopyBook") ?? []) as! [String]
    }
    
}



//#Preview {
//    SettingsView()
//}

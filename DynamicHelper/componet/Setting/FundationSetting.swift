//
//  FundationSetting.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/24.
//

import SwiftUI
import LaunchAtLogin


struct FundationSetting:View{
    @State private var homeViewType: IslandTypeManager.IslandType = .exten
    @State private var SelectWindowPos: Int = -1
    var body: some View{
        VStack{
            HStack{
                Text("初始畫面")
                Spacer()
                Picker("", selection: $homeViewType) {
                    Text("上一次打開").tag(IslandTypeManager.IslandType.hide)
                    Text("預設").tag(IslandTypeManager.IslandType.exten)
                    Text("檔案").tag(IslandTypeManager.IslandType.Drop)
                    Text("硬體狀態").tag(IslandTypeManager.IslandType.Hardware)
                    Text("音樂播放器").tag(IslandTypeManager.IslandType.Music)
                }.onAppear {
                    saveSettings()
                    homeViewType = IslandTypeManager.shared.defaultWindowType
                }
                .onChange(of: homeViewType) { _ ,newValue in
                    IslandTypeManager.shared.defaultWindowType = newValue
                    saveSettings()
                }
                .frame(width: 150)
            }
            HStack{
                Text("視窗位置")
                Spacer()
                Picker("", selection: $SelectWindowPos) {
                    ForEach(getAllScreenInfo()){item in
                        if item.isBuiltin{
                            Text("內建顯示器 \(item.screen.localizedName)").tag(-1)  
                        }                   
                    }
                    ForEach(getAllScreenInfo()){item in
                        Text(item.name).tag(item.index)                            
                    }
                }.onAppear {
                    saveSettings()
                    SelectWindowPos = defaultWindowPos
                    if SelectWindowPos >=  getAllScreenInfo().count{
                        SelectWindowPos = -1
                    }
                }
                .onChange(of: SelectWindowPos) { _ ,newValue in
                    defaultWindowPos = newValue
                    saveSettings()
                    IslandTypeManager.shared.OutsideChangeIslandType(to: .hide,EnforceChange: true)
                }
                .frame(width: 150)
            }
            Spacer()
            HStack{
                Text("登入時啟動")
                Spacer()
                LaunchAtLogin.Toggle("")
            }
            Spacer()
#if DEBUG
            Text("In Debug mode\nLaunch by Xcode")
#endif
        }
        .navigationTitle("基本設定")
    }
}

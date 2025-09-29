//
//  MenuView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//

import SwiftUI

struct MenuView: View {
    @ObservedObject private var island = islandTypeManager
    
    var appDelegate: AppDelegate
    
    var body: some View {
        VStack{
            HStack(spacing: 0){
#if false 
                MenuSettingButton(systemName: "gearshape.fill")
                    .frame(width: 32 , height: 32)
                    .padding(.leading)
#else
                MenuItemButton(systemName: "gearshape.fill",onTap: {appDelegate.showSettingsWindow()})
                    .frame(width: IslandTypeManager.NotchHeight , height: IslandTypeManager.NotchHeight)
                    .padding(.leading)
#endif
                MenuItemButton(
                    systemName: islandTypeManager.checkNowIslandTypeIs(.exten) ? "folder.fill" : "house.fill",
                    onTap: {FolderItemButtonAction()}
                )
                .frame(width: IslandTypeManager.NotchHeight , height: IslandTypeManager.NotchHeight)
                SoundController()
                    .frame(minWidth: IslandTypeManager.NotchHeight , maxHeight: IslandTypeManager.NotchHeight)
                //Spacer(minLength: getWindowSize(.hide).width*Resize)
                Spacer()
                MenuItemButton(systemName: "desktopcomputer.and.macbook",onTap: {appDelegate.showRemoteControlChooseWindow()}, width: 35)
                    .frame(width: IslandTypeManager.NotchHeight*1.1 , height: IslandTypeManager.NotchHeight)
                
                MenuItemButton(
                    systemName: island.isLock ? "lock.fill" : "lock.open.fill",
                    onTap: {island.isLock = !island.isLock}
                )
                .frame(width: IslandTypeManager.NotchHeight , height: IslandTypeManager.NotchHeight)
                BatteryView()
                    
            }.frame(height: IslandTypeManager.NotchHeight*1.2,alignment: .center)
//            Spacer()
        }
    }
    
    func FolderItemButtonAction(){
        withAnimation(.easeInOut(duration: 0.2)){
            island.OutsideChangeIslandType(to: island.getNowIslandType() == .exten ? .Drop : .exten)
        }
    }
}

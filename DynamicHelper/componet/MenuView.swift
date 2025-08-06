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
        HStack(spacing: 0){
            MenuItemButton(systemName: "gearshape.fill",onTap: {appDelegate.showSettingsWindow()})
                .frame(width: 32 , height: 32)
                .padding(.leading)
            MenuItemButton(
                systemName: islandTypeManager.checkNowIslandTypeIs(.exten) ? "folder.fill" : "house.fill",
                onTap: {FolderItemButtonAction()}
            )
                .frame(width: 32 , height: 32)
            SoundController()
                .frame(minWidth: 32 , maxHeight: 32)
            //Spacer(minLength: getWindowSize(.hide).width*Resize)
            Spacer()
            MenuItemButton(systemName: "desktopcomputer.and.macbook",onTap: {appDelegate.showRemoteControlChooseWindow()}, width: 35)
                .frame(width: 35 , height: 32)
            
            MenuItemButton(
                systemName: island.isLock ? "lock.fill" : "lock.open.fill",
                onTap: {island.isLock = !island.isLock}
            )
                .frame(width: 32 , height: 32)
            BatteryView()
        }.frame(maxHeight: 32*IslandTypeManager.Resize,alignment: .center)
    }
    
    func FolderItemButtonAction(){
        withAnimation(.easeInOut(duration: 0.2)){
            island.OutsideChangeIslandType(to: island.getNowIslandType() == .exten ? .Drop : .exten)
        }
    }
}

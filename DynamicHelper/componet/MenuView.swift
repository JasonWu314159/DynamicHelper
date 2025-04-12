//
//  MenuView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//

import SwiftUI

struct MenuView: View {
    @ObservedObject private var windowType = windowState
    
    var appDelegate: AppDelegate
    
    var body: some View {
        HStack(spacing: 0){
            MenuItemButton(systemName: "gearshape.fill",onTap: {appDelegate.showSettingsWindow()})
                .frame(width: 32 , height: 32)
                .padding(.leading)
            MenuItemButton(
                systemName: windowType.type == .exten ? "folder.fill" : "house.fill",
                onTap: {FolderItemButtonAction()}
            )
                .frame(width: 32 , height: 32)
            SoundController()
                .frame(minWidth: 32 , maxHeight: 32)
            //Spacer(minLength: getWindowSize(.hide).width*Resize)
            Spacer()
            MenuItemButton(
                systemName: windowType.isLock ? "lock.fill" : "lock.open.fill",
                onTap: {windowType.isLock = !windowType.isLock}
            )
                .frame(width: 32 , height: 32)
            BatteryView()
        }.frame(maxHeight: 32*Resize,alignment: .center)
    }
    
    func FolderItemButtonAction(){
        withAnimation(.easeInOut(duration: 0.2)){
            windowType.outsideChange = windowType.type == .exten ? .Drop : .exten
        }
    }
}

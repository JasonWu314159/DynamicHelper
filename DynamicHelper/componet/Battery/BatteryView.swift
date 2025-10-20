//
//  BatteryView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//

import IOKit.ps
import SwiftUI
import AppKit


struct BatteryView: View {
    
    @ObservedObject private var status: StatusModel = .shared
    @ObservedObject private var battery: PowerMonitor = .shared
    
    @State private var isShowingChargingIcon: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            Text("\(battery.batteryInfo.percentage)%")
                .foregroundColor(.white)
                .font(.caption)
            CustomBatteryView(level: CGFloat(battery.batteryInfo.percentage) / 100.0,isCharge: battery.batteryInfo.isCharging)
            if(!battery.batteryInfo.isCharging && battery.batteryInfo.isPluggedIn){
                Image(systemName: "powerplug.portrait.fill")
                    .foregroundStyle(.white)
                    .opacity(isShowingChargingIcon ? 1 : 0)
            }else if(battery.batteryInfo.isCharging){
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.green)
                    .opacity(isShowingChargingIcon ? 1 : 0)
            }else if IslandTypeManager.shared.checkNowIslandTypeIs(.onCharge){
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.black)
            }
        }
        .padding(10)
        .hoverPressEffect(HBG: 0.4,CR: 5,BGP:5) {
            if(NSEvent.modifierFlags.contains(.command)){
                PowerMonitor.openActivityMonitor()
                return
            }else{
                if IslandTypeManager.shared.checkNowIslandTypeIs(.Hardware){
                    StatusModel.shared.setNowType(.home)
                }else{
                    IslandTypeManager.shared
                        .OutsideChangeIslandType(to: .Hardware, Animate: true)
                }
            }
        }
        .padding(.trailing,10)
        .frame(height: IslandTypeManager.NotchHeight)
        .onAppear {
            if IslandTypeManager.shared.checkNowIslandTypeIs(.onCharge){
                if battery.batteryInfo.isPluggedIn{
                    isShowingChargingIcon = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isShowingChargingIcon = true
                    }
                }
            }
        }
        .contextMenu {
            ForEach(StatusModel.statusType.allCases) { infoLabel in
                Button(){
                    if !IslandTypeManager.shared.checkNowIslandTypeIs(.Hardware){
                        IslandTypeManager.shared.OutsideChangeIslandType(to: .Hardware)
                    }
                    withAnimation{
                        StatusModel.shared.setNowType(infoLabel)
                    }
                }label:{
                    Label(infoLabel.rawValue, systemImage: infoLabel.icon)
                }
            }
            id(status.nowType)
        }
    }

}





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
    @State private var percentage: Int = 0
    @State private var isCharging: Bool = false
    @State private var isPluggedIn: Bool = false
    @State private var level: CGFloat = 0
    @State private var timer: Timer?
    @State private var isShowingChargingIcon: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            Text("\(percentage)%")
                .foregroundColor(.white)
                .font(.caption)
            CustomBatteryView(level: $level,isCharge: $isCharging)
            if(!isCharging && isPluggedIn){
                Image(systemName: "powerplug.portrait.fill")
                    .foregroundStyle(.white)
                    .opacity(isShowingChargingIcon ? 1 : 0)
            }else if(isCharging){
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
            startMonitoring()
            if IslandTypeManager.shared.checkNowIslandTypeIs(.onCharge){
                if isPluggedIn{
                    isShowingChargingIcon = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isShowingChargingIcon = true
                    }
                }
            }
        }
        .onDisappear {
            stopMonitoring()
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

    func startMonitoring() {
        updateBatteryInfo() // 立即更新一次
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateBatteryInfo()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func updateBatteryInfo() {
        if let info = PowerMonitor.getBatteryInfo() {
            percentage = info.percentage
            isCharging = info.isCharging
            isPluggedIn = info.isPluggedIn
            level = CGFloat(info.percentage) / 100.0
        }
    }
}





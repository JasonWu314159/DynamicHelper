//
//  PowerMonitor.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/28.
//

import IOKit.ps
import SwiftUI
import AppKit

final class PowerMonitor: ObservableObject {
    static let shared = PowerMonitor()
    
    
    struct BatteryInfo {
        let isPluggedIn: Bool       // 是否插著電
        let isCharging: Bool        // 是否正在充電（即實際充電行為）
        let percentage: Int         // 電量百分比
    }
    
    private var runLoopSource: CFRunLoopSource?
    private var lastPluggedInState: Bool = false
    private var ChargingStateChangeTime = Date()
    @Published var batteryInfo: BatteryInfo
    
    init() {
        self.batteryInfo = PowerMonitor
            .getBatteryInfo() ?? BatteryInfo(
                isPluggedIn: false,
                isCharging: false,
                percentage: 0
            )
        
        let loop = CFRunLoopGetCurrent()
        let context = Unmanaged.passUnretained(self).toOpaque()
        
        if let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
            
            DispatchQueue.main.async {
                // 偵測到插上電
                monitor.handlePluggedInEvent()
            }
            
        }, context)?.takeRetainedValue() {
            CFRunLoopAddSource(loop, source, .defaultMode)
            self.runLoopSource = source
        }
    }
    
    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    func handlePluggedInEvent() {
        guard let info = PowerMonitor.getBatteryInfo() else { return }
        if info.isPluggedIn != lastPluggedInState{
            // 偵測到插上電
            monitorChargeEvent()
        }
        lastPluggedInState = info.isPluggedIn
        batteryInfo = info
        
    }
    
    func monitorChargeEvent() {
        let showTime = 3.0
        ChargingStateChangeTime = Date()
        if IslandTypeManager.shared.checkNowIslandTypeIs(.hide) {
            IslandTypeManager.shared.OutsideChangeIslandType(to: .onCharge)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + showTime) {
            if(Date().timeIntervalSince(self.ChargingStateChangeTime) >= showTime){
                if IslandTypeManager.shared.checkNowIslandTypeIs(.onCharge) {
                    IslandTypeManager.shared.OutsideChangeIslandType(to: .hide)
                }
            }
        }
    }
    
    
    static func getBatteryInfo() -> BatteryInfo? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any]
        else {
            return nil
        }

        guard let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int,
              let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int,
              let isCharging = description[kIOPSIsChargingKey as String] as? Bool,
              let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String
        else {
            return nil
        }

        let isPluggedIn = (powerSourceState == kIOPSACPowerValue)
        let percentage = Int((Double(currentCapacity) / Double(maxCapacity)) * 100)

        return BatteryInfo(isPluggedIn: isPluggedIn, isCharging: isCharging, percentage: percentage)
    }
    
    
    static func openActivityMonitor() {
        // 先啟動並置前
        let path = "/System/Applications/Utilities/Activity Monitor.app"
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
        
    }

}

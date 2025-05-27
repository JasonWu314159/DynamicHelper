//
//  BatteryView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//

import IOKit.ps
import SwiftUI
import AppKit

struct BatteryInfo {
    let isPluggedIn: Bool       // 是否插著電
    let isCharging: Bool        // 是否正在充電（即實際充電行為）
    let percentage: Int         // 電量百分比
}

func getBatteryInfo() -> BatteryInfo? {
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

struct BatteryView: View {
    @State private var percentage: Int = 0
    @State private var isCharging: Bool = false
    @State private var isPluggedIn: Bool = false
    @State private var level: CGFloat = 0
    @State private var timer: Timer?
    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Text("\(percentage)%")
                .foregroundColor(.white)
                .font(.caption)
            CustomBatteryView(level: $level,isCharge: $isCharging)
            if(!isCharging && isPluggedIn){
                Image(systemName: "powerplug.portrait.fill")
                    .foregroundStyle(.white)
            }else if(isCharging){
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .foregroundStyle(isHovering ? Color.gray.opacity(0.6) : Color.clear)
                .padding(5)
        )
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
        .onHover{ h in
            withAnimation(.easeInOut(duration: 0.2)){
                isHovering = h
            }
        }
        .onTapGesture {
            if(NSEvent.modifierFlags.contains(.command)){
                openActivityMonitor()
                return
            }else{
                windowState.outsideChange = .Hardware
            }
        }
    }

    func startMonitoring() {
        updateBatteryInfo() // 立即更新一次
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateBatteryInfo()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func updateBatteryInfo() {
        if let info = getBatteryInfo() {
            percentage = info.percentage
            isCharging = info.isCharging
            isPluggedIn = info.isPluggedIn
            level = CGFloat(info.percentage) / 100.0
            
//            print(info)

        }
    }
}
struct CustomBatteryView: View {
    @Binding var level: CGFloat // 0.0 ~ 1.0
    @Binding var isCharge: Bool

    var body: some View {
        ZStack(alignment: .leading) {

            Image(systemName: "battery.0")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 12)
                .foregroundColor(.gray)
            RoundedRectangle(cornerRadius: 2)
                .fill(getColor(level))
                .frame(width: 18 * level, height: 7)
                .padding(.leading, 9.5)
        }
        .padding(.horizontal,0)
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.black)
                .frame(width: 6, height: 10)
                .offset(x: 32, y: 0)
            , alignment: .trailing
        )
    }
    
    func getColor(_ a:CGFloat) -> Color {
        var color: Color = .white
        if level >= 0.8 {
            if(isCharge){
                color = .green
            }else{
                color = .white
            }
        } else if level < 0.2 {
            if(isCharge){
                color = .yellow
            }else{
                color = .red
            }
        }
        return color
    }
}

final class PowerMonitor {
    private var runLoopSource: CFRunLoopSource?
    @ObservedObject var windowType:WindowState
    private var lastPluggedInState: Bool = false
    
    init(_ windowType:WindowState) {
        let loop = CFRunLoopGetCurrent()
        self.windowType = windowType
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
        guard let info = getBatteryInfo() else { return }
        if info.isPluggedIn != lastPluggedInState{
            // 偵測到插上電
            monitorChargeEvent()
        }
        lastPluggedInState = info.isPluggedIn
    }
    
    func monitorChargeEvent() {
        if windowState.type == .hide {
            windowState.outsideChange = .onCharge
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if windowState.type == .onCharge {
                    windowState.outsideChange = .hide
                }
            }
        }
    }
}


func openActivityMonitor() {
    let path = "/System/Applications/Utilities/Activity Monitor.app"
    let url = URL(fileURLWithPath: path)
    NSWorkspace.shared.open(url)
}

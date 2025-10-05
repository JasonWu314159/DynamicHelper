//
//  HardwareInfoView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/6/8.
//

import SwiftUI

struct HardwareInfoView: View {
    @State private var timer: Timer?
    @State private var CPU_UsageTypes:[UsageType] = []
    @State private var RAM_UsageTypes:[UsageType] = []
    @State private var cpuLoad:CPU_Load = CPU_Load()
    @State private var ramLoad:RAM_Usage?// = RAM_Usage(from: nil)
    @State private var gpuLoad:[GPU_Info] = []
    @State private var cpuTempText: TextFormat = TextFormat(0,Unit:.Celsius)
    @State private var gpuPowerText: TextFormat = TextFormat(0,Unit:.Power)
    @State private var netUpText: TextFormat   = TextFormat(0,Unit:.byte_s)
    @State private var netDownText: TextFormat = TextFormat(0,Unit:.byte_s)
    @State private var lastUploadBytes: Int64?
    @State private var lastDownloadBytes: Int64?
    
    var body: some View {
        HStack(spacing: 10) {
            UsageTypeBoard(usageType:CPU_UsageTypes,label:"CPU\n\(String(format: "%.1f%%", cpuLoad.totalUsage * 100))"){
                if(NSEvent.modifierFlags.contains(.command)){
                    PowerMonitor.openActivityMonitor()
                    return
                }else{
                    StatusModel.shared.setNowType(.CPU)
                }
            }
            
            UsageTypeBoard(usageType:[UsageType(gpuLoad.first?.utilization ?? 0, name:"已使用")],label:"GPU\n\(String(format: "%.1f%%", (gpuLoad.first?.utilization ?? 0) * 100))"){
                if(NSEvent.modifierFlags.contains(.command)){
                    PowerMonitor.openActivityMonitor()
                    return
                }else{
                    StatusModel.shared.setNowType(.GPU)
                }
            }

            UsageTypeBoard(usageType:RAM_UsageTypes,label:"RAM\n\(String(format: "%.1f%%", (ramLoad?.used ?? 0) / (ramLoad?.total ?? 1) * 100))"){
                if(NSEvent.modifierFlags.contains(.command)){
                    PowerMonitor.openActivityMonitor()
                    return
                }else{
                    StatusModel.shared.setNowType(.RAM)
                }
            }

            VStack(spacing: 12) {
                
                VStack(spacing: 3) {
                    Text("感測器")
                        .bold()
                        .foregroundStyle(.white.opacity(0.9))
                    VStack(spacing: 0) {
                        MetricTile(title: "CPU平均溫度", value: cpuTempText.toString(true), color: .white)
                        MetricTile(title: "GPU功耗", value: gpuPowerText.toString(true), color: .white)
                    }
                    .background(
                        .gray.opacity(0.3),
                        in: RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                    )
                }
                .hoverPressEffect(HBG: 0.2,PBG: 0.15) {
                    if(NSEvent.modifierFlags.contains(.command)){
                        PowerMonitor.openActivityMonitor()
                        return
                    }else{
                        StatusModel.shared.setNowType(.sensor)
                    }
                }
                
                
                VStack(spacing: 3) {
                    Text("網路").bold().foregroundStyle(.white.opacity(0.9))
                    VStack(spacing: 0) {
                        MetricTile(title: "↑ 上傳", value: netUpText.toString(true), color: .red, monospaced: true)
                        MetricTile(title: "↓ 下載", value: netDownText.toString(true), color: .blue, monospaced: true)
                    }
                    .background(.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .hoverPressEffect(HBG: 0.2,PBG: 0.15) {
                    if(NSEvent.modifierFlags.contains(.command)){
                        PowerMonitor.openActivityMonitor()
                        return
                    }else{
                        StatusModel.shared.setNowType(.network)
                    }
                }
            }
            .padding(.vertical, 6)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal,20)
        .onAppear{
            startMonitoring()
        }
        .onDisappear(){
            stopMonitoring()
        }
    }
    
    
    func startMonitoring() {
        stopMonitoring()
        self.UpdateHardwareInfo()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            
            self.UpdateHardwareInfo()
            
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func UpdateHardwareInfo()  {
        if !IslandTypeManager.shared.checkNowIslandTypeIs(.Hardware) || StatusModel.shared.nowType != .home{stopMonitoring(); return}

        
        cpuLoad = CPULoadReader.shared.read() ?? CPU_Load()
        CPU_UsageTypes = [UsageType(cpuLoad.systemLoad,.red, name:"系統"),UsageType(cpuLoad.userLoad,.blue, name:"使用者")]
        
        gpuLoad = GPUsInfoReader.shared.read() ?? []
    
        
        guard let ramLoad = RAMStateMonitor.shared.read() else{ return }
        self.ramLoad = ramLoad
        RAM_UsageTypes = [UsageType(ramLoad.app / ramLoad.total,.blue, name:"App"),UsageType(ramLoad.wired / ramLoad.total,.orange, name:"核心"),UsageType(ramLoad.compressed / ramLoad.total,.red, name:"已壓縮")]
        
        
        
        DispatchQueue.global().async{
            let sensors = SensorsReader.shared.read()
            
            // CPU 溫度（取 "Average CPU"，無則退而求其次 "Hottest CPU"）
            let cpuTemp = sensors.first(where: { $0.key == "Average CPU" })?.value ?? 0
            cpuTempText.Value = cpuTemp
            
            // GPU 功耗（Apple Silicon；第一次可能為 0，第二次起有值）
            let gpuPower = sensors.first(where: { $0.key == "GPU Power" })?.value ?? 0
            gpuPowerText.Value = gpuPower
            
            // 2) Network（使用 NetStateMonitor 的介面累積位元組，自己做差）
            NetStateMonitor.shared.read()
            let usage = NetStateMonitor.shared.usage
            let currUp   = usage.bandwidth.upload      // 注意：這是「累積 bytes」
            let currDown = usage.bandwidth.download    // 注意：這是「累積 bytes」
            
            var upRate: Int64 = 0
            var downRate: Int64 = 0
            if let lu = lastUploadBytes, let ld = lastDownloadBytes {
                upRate   = max(0, currUp   - lu)
                downRate = max(0, currDown - ld)
            }
            lastUploadBytes = currUp
            lastDownloadBytes = currDown
            netUpText.Value   =  Double(upRate)
            netDownText.Value =  Double(downRate)
        }
    }
//    RAM_Usage(total: 17179869184.0, used: 14284128256.0, free: 2895740928.0, active: 2953478144.0, inactive: 2691579904.0, wired: 2977824768.0, compressed: 7635042304.0, app: 3671261184.0, cache: 2220916736.0, swap: DynamicHelper.Swap(total: 8589934592.0, used: 7197884416.0, free: 1392050176.0), pressure: DynamicHelper.Pressure(level: 2, value: DynamicHelper.RAMPressure.warning), swapins: 2163248, swapouts: 3030240)
}


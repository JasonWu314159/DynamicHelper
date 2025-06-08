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
    
    var body: some View {
        HStack {
            UsageTypeBoard(usageType:CPU_UsageTypes,label:"CPU\n\(String(format: "%.1f%%", cpuLoad.totalUsage * 100))")
                .frame(width: 100, height: 100)
                .padding(.horizontal)
            UsageTypeBoard(usageType:[UsageType(gpuLoad.first?.utilization ?? 0)],label:"GPU\n\(String(format: "%.1f%%", (gpuLoad.first?.utilization ?? 0) * 100))")
                .frame(width: 100, height: 100)
                .padding(.horizontal)
            UsageTypeBoard(usageType:RAM_UsageTypes,label:"RAM\n\(String(format: "%.1f%%", (ramLoad?.used ?? 0) / (ramLoad?.total ?? 1) * 100))")
                .frame(width: 100, height: 100)
                .padding(.horizontal)
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
        UpdateHardwareInfo()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            UpdateHardwareInfo()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func UpdateHardwareInfo()  {
        cpuLoad = CPULoadReader.shared.read() ?? CPU_Load()
        CPU_UsageTypes = [UsageType(cpuLoad.systemLoad,.red),UsageType(cpuLoad.userLoad,.blue)]
        
        gpuLoad = GPUsInfoReader.shared.read() ?? []
        
        guard let ramLoad = RAMStateMonitor.shared.read() else{ return }
        self.ramLoad = ramLoad
        RAM_UsageTypes = [UsageType(ramLoad.app / ramLoad.total,.blue),UsageType(ramLoad.wired / ramLoad.total,.orange),UsageType(ramLoad.compressed / ramLoad.total,.red)]
        
        
    }
//    RAM_Usage(total: 17179869184.0, used: 14284128256.0, free: 2895740928.0, active: 2953478144.0, inactive: 2691579904.0, wired: 2977824768.0, compressed: 7635042304.0, app: 3671261184.0, cache: 2220916736.0, swap: DynamicHelper.Swap(total: 8589934592.0, used: 7197884416.0, free: 1392050176.0), pressure: DynamicHelper.Pressure(level: 2, value: DynamicHelper.RAMPressure.warning), swapins: 2163248, swapouts: 3030240)
}


struct GameModeHardwareInfoView: View {
    @State private var timer: Timer?
    @State private var cpuLoad:CPU_Load = CPU_Load()
    @State private var ramLoad:RAM_Usage?// = RAM_Usage(from: nil)
    @State private var gpuLoad:[GPU_Info] = []
    @State private var SensorsLoad:[Sensor_p] = []
    @State private var averageTemp:Double = 0
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size.height
            HStack(spacing: 5) {
                UsageTextView(title: "CPU", value: cpuLoad.totalUsage, size: size)
                UsageTextView(title: "GPU", value: (gpuLoad.first?.utilization ?? 0), size: size)
                UsageTextView(title: "RAM", value: (ramLoad?.used ?? 0) / (ramLoad?.total ?? 1), size: size)      
                Spacer()
                UsageTextView(title: "TEMP", value: averageTemp, size: size, Unit: .Celsius)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading,15)
        .onAppear{
            startMonitoring()
        }
        .onDisappear(){
            stopMonitoring()
        }
    }
    
    func startMonitoring() {
        UpdateHardwareInfo()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            UpdateHardwareInfo()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func UpdateHardwareInfo()  {
        cpuLoad = CPULoadReader.shared.read() ?? CPU_Load()
        
        gpuLoad = GPUsInfoReader.shared.read() ?? []
        
        if let ramLoad = RAMStateMonitor.shared.read(){ self.ramLoad = ramLoad } 
        else{  self.ramLoad = nil }
        
        SensorsLoad = SensorsReader.shared.read()
        
        let cpuCoreTemperatures = SensorsLoad.filter {
            $0.group == .CPU &&
            $0.type == .temperature &&
            !$0.isComputed &&
            $0.name.lowercased().contains("core")
        }
        let averageCPUTemp = cpuCoreTemperatures.map(\.value).average
        averageTemp = averageCPUTemp
        
    }
}

struct UsageTextView: View {
    enum unit: String {
        case percent = "%"
        case Celsius = "ºC"
        case Fahrenheit = "ºF"
        case bit_s = "bit/s"
        case byte_s = "B/s"
        case kib_s = "KiB/s"
        case kb_s = "KB/s"
        case mib_s = "MiB/s"
        case mb_s = "MB/s"
        case gib_s = "GiB/s"
        case gb_s = "GB/s"
    }
    
    var title: String
    var value: Double
    var size: CGFloat
    var color: Color = .white
    var Unit: unit = .percent
    
    init(title: String, value: Double, size: CGFloat, Unit: unit = .percent){
        self.title = title
        self.value = value
        self.size = size
        self.Unit = Unit
        if Unit == .percent{
            if value > 0.7 && value <= 0.9  {
                self.color = .orange
            }
            else if value > 0.9 {
                self.color = .red
            }else{
                self.color = .white
            }
        }else if Unit == .Celsius{
            if value > 60 && value <= 85 {
                self.color = .orange
            }else if value > 85 {
                self.color = .red
            }else{
                self.color = .white
            }
        }
    }

    var body: some View {
        Text("\(title)\n\(FormatValue())")
            .foregroundStyle(color)
            .font(.system(size: size / 3.5).monospaced())
            .fontWeight(.bold)
            .frame(width: getWidthSize(), height: size, alignment: .center)
            .multilineTextAlignment(.center)
//            .background(color)
    }
    
    
    func getWidthSize() -> CGFloat{
        let len = max(title.count,FormatValue().count)
        return (size / 3.5) * CGFloat(len - 1)
    }
    
    
    func FormatValue() -> String{
        switch Unit{
            case .percent:
            if value * 100 < 10{
                return String(format: "%.2f%%", value * 100)
            }else if value * 100 >= 99.95{
                return String(format: "%.f%%", value * 100)
            }else{
                return String(format: "%.1f%%", value * 100)
            }
            default:
            if value < 10{
                return String(format: "%.2f%\(Unit.rawValue)", value)
            }else if value >= 100{
                return String(format: "%.f%\(Unit.rawValue)", value)
            }else{
                return String(format: "%.1f%\(Unit.rawValue)", value)
            }
        }
    }
}

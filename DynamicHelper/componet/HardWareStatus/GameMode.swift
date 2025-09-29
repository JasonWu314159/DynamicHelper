//
//  GameMode.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/28.
//

import SwiftUI


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
    
    var title: String
    var value: TextFormat
    var size: CGFloat
    var color: Color = .white
    
    init(title: String, value: Double, size: CGFloat, Unit: TextFormat.unit = .percent){
        self.title = title
        self.value = TextFormat(value,Unit: Unit)
        self.size = size
        if self.value.Unit == .percent{
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
        Text("\(title)\n\(value.toString())")
            .foregroundStyle(color)
            .font(.system(size: size / 3.5).monospaced())
            .fontWeight(.bold)
            .frame(width: getWidthSize(), height: size, alignment: .center)
            .multilineTextAlignment(.center)
//            .background(color)
    }
    
    
    func getWidthSize() -> CGFloat{
        let len = max(title.count,value.toString().count)
        return (size / 3.5) * CGFloat(len - 1)
    }
    
}

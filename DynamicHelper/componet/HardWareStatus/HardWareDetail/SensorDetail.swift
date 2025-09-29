//
//  SensorDetail.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/29.
//

import SwiftUI

struct SensorDetail: View {
    @State private var Sensor:[Sensor_p] = SensorsReader.shared.read()
    @State private var AirportTemp: TextFormat = TextFormat(0,Unit: .Celsius)
    @State private var NandTemp: TextFormat = TextFormat(0,Unit: .Celsius)
    @State private var HottestCPUTemp: TextFormat = TextFormat(0,Unit: .Celsius)
    @State private var AvgCPUTemp: TextFormat = TextFormat(0,Unit: .Celsius)
    @State private var CPUeCoreTemp: [Double] = []
    
    @State private var CPUPower: TextFormat = TextFormat(0,Unit: .Power)
    @State private var GPUPower: TextFormat = TextFormat(0,Unit: .Power)
    @State private var RAMPower: TextFormat = TextFormat(0,Unit: .Power)
    @State private var NPUPower: TextFormat = TextFormat(0,Unit: .Power)
    @State private var PCIPower: TextFormat = TextFormat(0,Unit: .Power)
    @State private var AvgSysPower: TextFormat = TextFormat(0,Unit: .Power)
    @State private var MmtSysPower: TextFormat = TextFormat(0,Unit: .Power)
    
    @State private var BatteryTemp: [Double] = []
    @State private var BatteryPower: TextFormat = TextFormat(0,Unit: .Power)
    @State private var DCInVolt: TextFormat = TextFormat(0,Unit: .Volt)
    @State private var _12Vrail: TextFormat = TextFormat(0,Unit: .Volt)
    @State private var DCInAmpere: TextFormat = TextFormat(0,Unit: .ampere)
    @State private var DCInPower: TextFormat = TextFormat(0,Unit: .Power)
    @State private var TtlSysCspt: TextFormat = TextFormat(0,Unit: .Energy)
    
    @State private var timer: Timer? = nil
    
    var body: some View {
        HStack(spacing: 10){
            Group{
                BoardTemperture
                BoardPower
            }
            .padding(.horizontal,5)
            .background(
                Color.gray.opacity(0.2)
                .clipShape(RoundedRectangle(cornerRadius: 10,style: .continuous))
            )
            battery
            
        }
        .padding(.horizontal,20)
        .padding(.vertical,5)
        .onAppear{
            startMonitoring()
        }
    }
    
    private var BoardTemperture: some View{
        VStack(spacing:0){
            Text("溫度")
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            MetricTile(
                title: "Wifi模組",
                value: AirportTemp.toString(),
                color: .white
                
            )
            MetricTile(
                title: "SSD顆粒",
                value: NandTemp.toString(),
                color: .white
            )
            ForEach(CPUeCoreTemp.indices,id:\.self){ i in
                let temp:TextFormat = TextFormat(CPUeCoreTemp[i],Unit: .Celsius)
                MetricTile(
                    title: "效能核心 \(i+1)",
                    value: temp.toString(),
                    color: .white
                ) 
            }
            MetricTile(
                title: "核心最高溫",
                value: HottestCPUTemp.toString(),
                color: .white
            )
            MetricTile(
                title: "核心平均溫",
                value: AvgCPUTemp.toString(),
                color: .white
            )
        }
    }
    
    private var BoardPower: some View{
        VStack(spacing:0){
            Text("功率")
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            MetricTile(
                title: "CPU功率",
                value: CPUPower.toString(),
                color: .white
            )
            MetricTile(
                title: "GPU功率",
                value: GPUPower.toString(),
                color: .white
            )
            MetricTile(
                title: "RAM功率",
                value: RAMPower.toString(),
                color: .white
            )
            MetricTile(
                title: "NPU功率",
                value: NPUPower.toString(),
                color: .white
            )
            MetricTile(
                title: "PCI功率",
                value: PCIPower.toString(),
                color: .white
            )
            MetricTile(
                title: "系統瞬時功率",
                value: AvgSysPower.toString(),
                color: .white
            )
            MetricTile(
                title: "系統平均功率",
                value: MmtSysPower.toString(),
                color: .white
            )
        }
    }
    
    private var battery: some View{
        VStack(spacing:0){
            Text("電池相關")
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            ForEach(BatteryTemp.indices,id:\.self){ i in
                let temp:TextFormat = TextFormat(BatteryTemp[i],Unit: .Celsius)
                MetricTile(
                    title: "電池 \(i+1)",
                    value: temp.toString(),
                    color: .white
                ) 
            }
            MetricTile(
                title: "電池功率",
                value: BatteryPower.toString(),
                color: .white
            ) 
            MetricTile(
                title: "12V rail",
                value: _12Vrail.toString(),
                color: .white
            ) 
            MetricTile(
                title: "DC In 電壓",
                value: DCInVolt.toString(),
                color: .white
            ) 
            MetricTile(
                title: "DC In 電流",
                value: DCInAmpere.toString(),
                color: .white
            ) 
            MetricTile(
                title: "DC In 功率",
                value: DCInPower.toString(),
                color: .white
            ) 
            MetricTile(
                title: "系統總耗能",
                value: TtlSysCspt.toString(),
                color: .white
            ) 
        }
        .padding(.horizontal,5)
        .background(
            Color.gray.opacity(0.2)
            .clipShape(RoundedRectangle(cornerRadius: 10,style: .continuous))
        )
        .hoverPressEffect(HBG: 0, PBG: 0,HS: 1.025, CR: 0) {
            StatusModel.shared.setNowType(.bettery)
        }
    }
    
    func startMonitoring() {
        stopMonitoring()
        self.RefreshSensor()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            
            self.RefreshSensor()
            
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func RefreshSensor(){
        if !islandTypeManager.checkNowIslandTypeIs(.Hardware) || StatusModel.shared.nowType != .sensor{stopMonitoring(); return  }
        
        Sensor = SensorsReader.shared.read()
        AirportTemp.Value = readSensor("Airport") as! Double
        NandTemp.Value = readSensor("NAND") as! Double
        HottestCPUTemp.Value = readSensor("Hottest CPU") as! Double
        AvgCPUTemp.Value = readSensor("Average CPU") as! Double
        BatteryTemp = readSensor("Battery ") as! [Double]
        CPUeCoreTemp = readSensor("CPU efficiency core ") as! [Double]
        
        CPUPower.Value = readSensor("CPU Power") as! Double
        GPUPower.Value = readSensor("GPU Power") as! Double
        RAMPower.Value = readSensor("RAM Power") as! Double
        NPUPower.Value = readSensor("ANE Power") as! Double
        PCIPower.Value = readSensor("PCI Power") as! Double
        AvgSysPower.Value = readSensor("Average System Total") as! Double
        MmtSysPower.Value = readSensor(key:"PSTR") as! Double
        
        _12Vrail.Value = readSensor("12V rail") as! Double
        DCInVolt.Value = readSensor(key:"VD0R") as! Double
        DCInAmpere.Value = readSensor(key:"ID0R") as! Double
        DCInPower.Value = readSensor(key:"PDTR") as! Double
        TtlSysCspt.Value = readSensor("Total System Consumption") as! Double
        BatteryPower.Value = readSensor(key:"PPBR") as! Double
        
    }
    
    
    private func readSensor(_ name: String) -> Any {
        let value = Sensor.filter { $0.name.contains(name) } 
        let v:[Double] = value.map { $0.value }
        if v.count == 1{return v[0]}
        return v
    }
    
    private func readSensor(key: String) -> Any {
        let value = Sensor.filter { $0.key.contains(key) } 
        let v:[Double] = value.map { $0.value }
        if v.count == 1{return v[0]}
        return v
    }
}

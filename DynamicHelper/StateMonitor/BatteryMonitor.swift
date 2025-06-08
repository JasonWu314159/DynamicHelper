//
//  readers.swift
//  Battery
//
//  Created by Serhiy Mytrovtsiy on 06/06/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import IOKit.ps

struct Battery_Usage: Codable {
    var powerSource: String = ""
    var state: String? = nil
    var isCharged: Bool = false
    var isCharging: Bool = false
    var isBatteryPowered: Bool = false
    var optimizedChargingEngaged: Bool = false
    var level: Double = 0
    var cycles: Int = 0
    var health: Int = 0
    
    var designedCapacity: Int = 0
    var maxCapacity: Int = 0
    var currentCapacity: Int = 0
    
    var amperage: Int = 0
    var voltage: Double = 0
    var temperature: Double = 0
    
    var ACwatts: Int = 0
    var chargingCurrent: Int = 0
    var chargingVoltage: Int = 0
    
    var timeToEmpty: Int = 0
    var timeToCharge: Int = 0
    var timeOnACPower: Date? = nil
}

class BatteryMonitor {
    static let shared = BatteryMonitor()
    
    private var service: io_connect_t = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    
    private var usage: Battery_Usage = Battery_Usage()
    
    public func read() -> Battery_Usage?{
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as [CFTypeRef]
        
        if psList.isEmpty {
            return nil
        }
        
        for ps in psList {
            if let list = IOPSGetPowerSourceDescription(psInfo, ps).takeUnretainedValue() as? [String: Any] {
                self.usage.powerSource = list[kIOPSPowerSourceStateKey] as? String ?? "AC Power"
                self.usage.isBatteryPowered = self.usage.powerSource == "Battery Power"
                self.usage.isCharged = list[kIOPSIsChargedKey] as? Bool ?? false
                self.usage.isCharging = self.getBoolValue("IsCharging" as CFString) ?? false
                self.usage.optimizedChargingEngaged = list["Optimized Battery Charging Engaged"] as? Int == 1
                self.usage.level = Double(list[kIOPSCurrentCapacityKey] as? Int ?? 0) / 100
                
                if let time = list[kIOPSTimeToEmptyKey] as? Int {
                    self.usage.timeToEmpty = Int(time)
                }
                if let time = list[kIOPSTimeToFullChargeKey] as? Int {
                    self.usage.timeToCharge = Int(time)
                }
                
                if self.usage.powerSource == "AC Power" {
                    self.usage.timeOnACPower = Date()
                }
                
                self.usage.cycles = self.getIntValue("CycleCount" as CFString) ?? 0
                
                self.usage.currentCapacity = self.getIntValue("AppleRawCurrentCapacity" as CFString) ?? 0
                self.usage.designedCapacity = self.getIntValue("DesignCapacity" as CFString) ?? 1
                self.usage.maxCapacity = self.getIntValue((isARM ? "AppleRawMaxCapacity" : "MaxCapacity") as CFString) ?? 1
                if !isARM {
                    self.usage.state = list[kIOPSBatteryHealthKey] as? String
                }
                self.usage.health = Int((Double(100 * self.usage.maxCapacity) / Double(self.usage.designedCapacity)).rounded(.toNearestOrEven))
                
                self.usage.amperage = self.getIntValue("Amperage" as CFString) ?? 0
                self.usage.voltage = self.getVoltage() ?? 0
                self.usage.temperature = self.getTemperature() ?? 0
                
                var ACwatts: Int = 0
                if let ACDetails = IOPSCopyExternalPowerAdapterDetails() {
                    if let ACList = ACDetails.takeRetainedValue() as? [String: Any] {
                        guard let watts = ACList[kIOPSPowerAdapterWattsKey] else {
                            return nil
                        }
                        ACwatts = Int(watts as! Int)
                    }
                }
                self.usage.ACwatts = ACwatts
                
                if let chargerData = self.getChargerData() {
                    self.usage.chargingCurrent = chargerData["ChargingCurrent"] as? Int ?? 0
                    self.usage.chargingVoltage = chargerData["ChargingVoltage"] as? Int ?? 0
                }
                
                print(self.usage)
                return self.usage
            }
        }
        return nil
    }
    
    private func getBoolValue(_ forIdentifier: CFString) -> Bool? {
        if let value = IORegistryEntryCreateCFProperty(self.service, forIdentifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Bool
        }
        return nil
    }
    
    private func getIntValue(_ identifier: CFString) -> Int? {
        if let value = IORegistryEntryCreateCFProperty(self.service, identifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Int
        }
        return nil
    }
    
    private func getDoubleValue(_ identifier: CFString) -> Double? {
        if let value = IORegistryEntryCreateCFProperty(self.service, identifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Double
        }
        return nil
    }
    
    private func getVoltage() -> Double? {
        if let value = self.getDoubleValue("Voltage" as CFString) {
            return value / 1000.0
        }
        return nil
    }
    
    private func getTemperature() -> Double? {
        if let value = IORegistryEntryCreateCFProperty(self.service, "Temperature" as CFString, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as! Double / 100.0
        }
        return nil
    }
    
    private func getChargerData() -> [String: Any]? {
        if let chargerData = IORegistryEntryCreateCFProperty(service, "ChargerData" as CFString, kCFAllocatorDefault, 0) {
            return chargerData.takeRetainedValue() as? [String: Any]
        }
        return nil
    }
}


public class BatteryProcessReader{
    static let shared = BatteryProcessReader()
    
    private var numberOfProcesses: Int {
        get {
            return 8
        }
    }
    
    public func read() -> [TopProcess]{
        if self.numberOfProcesses == 0 {
            return []
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/top"
        task.arguments = ["-o", "power", "-l", "2", "-n", "\(self.numberOfProcesses)", "-stats", "pid,command,power"]
        
        let outputPipe = Pipe()
        defer {
            outputPipe.fileHandleForReading.closeFile()
        }
        task.standardOutput = outputPipe
        
        do {
            try task.run()
        } catch let err {
            error("error read ps: \(err.localizedDescription)")
            return []
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if outputData.isEmpty {
            return []
        }
        
        let output = String(data: outputData.advanced(by: outputData.count/2), encoding: .utf8)
        guard let output, !output.isEmpty else { return []}
        
        var processes: [TopProcess] = []
        output.enumerateLines { (line, _) in
            if line.matches("^\\d+ *[^(\\d)]*\\d+\\.*\\d* *$") {
                let str = line.trimmingCharacters(in: .whitespaces)
                let pidFind = str.findAndCrop(pattern: "^\\d+")
                let usageFind = pidFind.remain.findAndCrop(pattern: " +[0-9]+.*[0-9]*$")
                let command = usageFind.remain.trimmingCharacters(in: .whitespaces)
                let pid = Int(pidFind.cropped) ?? 0
                guard let usage = Double(usageFind.cropped.filter("01234567890.".contains)) else {
                    return
                }
                
                var name: String = command
                if let app = NSRunningApplication(processIdentifier: pid_t(pid)), let n = app.localizedName {
                    name = n
                }
                
                processes.append(TopProcess(pid: pid, name: name, usage: usage))
            }
        }
        
//        print(processes.suffix(self.numberOfProcesses).sorted(by: { $0.usage > $1.usage }))
        
        return processes.suffix(self.numberOfProcesses).sorted(by: { $0.usage > $1.usage })
    }
}

//
//  readers.swift
//  Sensors
//
//  Created by Serhiy Mytrovtsiy on 17/06/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa


class SensorsReader{
    static let shared: SensorsReader = SensorsReader()
    
    static let HIDtypes: [SensorType] = [.temperature, .voltage]
    
    internal var list: Sensors_List = Sensors_List()
    
    private var lastRead: Date = Date()
    private let firstRead: Date = Date()
    
    private var HIDState: Bool {
//        Store.shared.bool(key: "Sensors_hid", defaultValue: false)
        false
    }
    private var unknownSensorsState: Bool
    
    private var channels: CFMutableDictionary? = nil
    private var subscription: IOReportSubscriptionRef? = nil
    private var powers: (CPU: Double, GPU: Double, ANE: Double, RAM: Double, PCI: Double) = (0.0, 0.0, 0.0, 0.0, 0.0)
    
    init() {
        self.unknownSensorsState = false
//        self.unknownSensorsState = Store.shared.bool(key: "Sensors_unknown", defaultValue: false)
//        super.init(.sensors, callback: callback)
        
        self.channels = self.getChannels()
        var dict: Unmanaged<CFMutableDictionary>?
        self.subscription = IOReportCreateSubscription(nil, self.channels, &dict, 0, nil)
        dict?.release()
        
        self.list.sensors = self.sensors()
    }
    
    private func sensors() -> [Sensor_p] {
        var available: [String] = SMC.shared.getAllKeys()
        var list: [Sensor_p] = []
        var sensorsList = SensorsList
        
        if let platform = SystemKit.shared.device.platform {
            sensorsList = sensorsList.filter({ $0.platforms.contains(platform) })
        }
        
        
        available = available.filter({ (key: String) -> Bool in
            switch key.prefix(1) {
            case "T", "V", "P", "I": return true
            default: return false
            }
        })
        
        sensorsList.forEach { (s: Sensor) in
            if let idx = available.firstIndex(where: { $0 == s.key }) {
                list.append(s)
                available.remove(at: idx)
            }
        }
        sensorsList.filter{ $0.key.contains("%") }.forEach { (s: Sensor) in
            var index = 1
            for i in 0..<10 {
                let key = s.key.replacingOccurrences(of: "%", with: "\(i)")
                if let idx = available.firstIndex(where: { $0 == key }) {
                    var sensor = s.copy()
                    sensor.key = key
                    sensor.name = s.name.replacingOccurrences(of: "%", with: "\(index)")
                    
                    list.append(sensor)
                    available.remove(at: idx)
                    index += 1
                }
            }
        }
        available.forEach { (key: String) in
            var type: SensorType? = nil
            switch key.prefix(1) {
            case "T": type = .temperature
            case "V": type = .voltage
            case "P": type = .power
            case "I": type = .current
            default: type = nil
            }
            if let t = type {
                list.append(Sensor(key: key, name: key, group: .unknown, type: t, platforms: []))
            }
        }
        
        for sensor in list {
            if let newValue = SMC.shared.getValue(sensor.key) {
                if let idx = list.firstIndex(where: { $0.key == sensor.key }) {
                    list[idx].value = newValue
                }
            }
        }
        
        var results: [Sensor_p] = []
        results += list.filter({ (s: Sensor_p) -> Bool in
            if s.type == .temperature && (s.value == 0 || s.value > 110) {
                return false
            } else if s.type == .current && s.value > 100 {
                return false
            }
            return true
        })
        
        #if arch(arm64)
        if self.HIDState {
            results += self.initHIDSensors()
        }
        results += self.initIOSensors()
        #endif
        results += self.initCalculatedSensors(results)
        
        return results
    }
    
    public func read() -> [Sensor_p]{
        for i in self.list.sensors.indices {
            guard self.list.sensors[i].group != .hid && !self.list.sensors[i].isComputed else { continue }
            if !self.unknownSensorsState && self.list.sensors[i].group == .unknown { continue }
            
            var newValue = SMC.shared.getValue(self.list.sensors[i].key) ?? 0
            if self.list.sensors[i].type == .temperature && self.list.sensors[i].group == .CPU &&
                (newValue < 10 || newValue > 120) { // fix for m2 broken sensors
                newValue = self.list.sensors[i].value
            }
            self.list.sensors[i].value = newValue
        }
        
        var cpuSensors = self.list.sensors.filter({ $0.group == .CPU && $0.type == .temperature && $0.average }).map{ $0.value }
        var gpuSensors = self.list.sensors.filter({ $0.group == .GPU && $0.type == .temperature && $0.average }).map{ $0.value }
        
        #if arch(arm64)
        if self.HIDState {
            for typ in SensorsReader.HIDtypes {
                let (page, usage, type) = self.m1Preset(type: typ)
                AppleSiliconSensors(page, usage, type).forEach { (key, value) in
                    guard let key = key as? String, let value = value as? Double, value < 300 && value >= 0 else {
                        return
                    }
                    
                    if let idx = self.list.sensors.firstIndex(where: { $0.group == .hid && $0.key == key }) {
                        self.list.sensors[idx].value = value
                    }
                }
            }
            
            cpuSensors += self.list.sensors.filter({ $0.key.hasPrefix("pACC MTR Temp") || $0.key.hasPrefix("eACC MTR Temp") }).map{ $0.value }
            gpuSensors += self.list.sensors.filter({ $0.key.hasPrefix("GPU MTR Temp") }).map{ $0.value }
            
            let socSensors = self.list.sensors.filter({ $0.key.hasPrefix("SOC MTR Temp") }).map{ $0.value }
            if !socSensors.isEmpty {
                if let idx = self.list.sensors.firstIndex(where: { $0.key == "Average SOC" }) {
                    self.list.sensors[idx].value = socSensors.reduce(0, +) / Double(socSensors.count)
                }
                if let max = socSensors.max() {
                    if let idx = self.list.sensors.firstIndex(where: { $0.key == "Hottest SOC" }) {
                        self.list.sensors[idx].value = max
                    }
                }
            }
        }
        
        if let (cpu, gpu, ane, ram, pci) = self.IOSensors() {
            if let idx = self.list.sensors.firstIndex(where: { $0.key == "CPU Power" }) {
                self.list.sensors[idx].value = cpu
            }
            if let idx = self.list.sensors.firstIndex(where: { $0.key == "GPU Power" }) {
                self.list.sensors[idx].value = gpu
            }
            if let idx = self.list.sensors.firstIndex(where: { $0.key == "ANE Power" }) {
                self.list.sensors[idx].value = ane
            }
            if let idx = self.list.sensors.firstIndex(where: { $0.key == "RAM Power" }) {
                self.list.sensors[idx].value = ram
            }
            if let idx = self.list.sensors.firstIndex(where: { $0.key == "PCI Power" }) {
                self.list.sensors[idx].value = pci
            }
        }
        #endif
        
        if !cpuSensors.isEmpty {
            if let idx = self.list.sensors.firstIndex(where: { $0.key == "Average CPU" }) {
                self.list.sensors[idx].value = cpuSensors.reduce(0, +) / Double(cpuSensors.count)
            }
            if let max = cpuSensors.max() {
                if let idx = self.list.sensors.firstIndex(where: { $0.key == "Hottest CPU" }) {
                    self.list.sensors[idx].value = max
                }
            }
        }
        if !gpuSensors.isEmpty {
            if let idx = self.list.sensors.firstIndex(where: { $0.key == "Average GPU" }) {
                self.list.sensors[idx].value = gpuSensors.reduce(0, +) / Double(gpuSensors.count)
            }
            if let max = gpuSensors.max() {
                if let idx = self.list.sensors.firstIndex(where: { $0.key == "Hottest GPU" }) {
                    self.list.sensors[idx].value = max
                }
            }
        }
        
        if let PSTRSensor = self.list.sensors.first(where: { $0.key == "PSTR"}), PSTRSensor.value > 0 {
            let sinceLastRead = Date().timeIntervalSince(self.lastRead)
            let sinceFirstRead = Date().timeIntervalSince(self.firstRead)
            
            if let totalIdx = self.list.sensors.firstIndex(where: {$0.key == "Total System Consumption"}), sinceLastRead > 0 {
                self.list.sensors[totalIdx].value += PSTRSensor.value * sinceLastRead / 3600
                if let avgIdx = self.list.sensors.firstIndex(where: {$0.key == "Average System Total"}), sinceFirstRead > 0 {
                    self.list.sensors[avgIdx].value = self.list.sensors[totalIdx].value * 3600 / sinceFirstRead
                }
            }
            
            self.lastRead = Date()
        }
        
        // cut off low dc in voltage
        if let idx = self.list.sensors.firstIndex(where: { $0.key == "VD0R" }), self.list.sensors[idx].value < 0.4 {
            self.list.sensors[idx].value = 0
        }
        // cut off low dc in current
        if let idx = self.list.sensors.firstIndex(where: { $0.key == "ID0R" }), self.list.sensors[idx].value < 0.05 {
            self.list.sensors[idx].value = 0
        }
        
//        self.callback(self.list)
//        print(self.list.sensors)
        
        return self.list.sensors
    }
    
    private func initCalculatedSensors(_ sensors: [Sensor_p]) -> [Sensor_p] {
        var list: [Sensor_p] = []
        
        var cpuSensors = sensors.filter({ $0.group == .CPU && $0.type == .temperature && $0.average }).map{ $0.value }
        var gpuSensors = sensors.filter({ $0.group == .GPU && $0.type == .temperature && $0.average }).map{ $0.value }
        
        #if arch(arm64)
        if self.HIDState {
            cpuSensors += sensors.filter({ $0.key.hasPrefix("pACC MTR Temp") || $0.key.hasPrefix("eACC MTR Temp") }).map{ $0.value }
            gpuSensors += sensors.filter({ $0.key.hasPrefix("GPU MTR Temp") }).map{ $0.value }
        }
        #endif
        
        
        if !cpuSensors.isEmpty {
            let value = cpuSensors.reduce(0, +) / Double(cpuSensors.count)
            list.append(Sensor(key: "Average CPU", name: "Average CPU", value: value, group: .CPU, type: .temperature, platforms: Platform.all, isComputed: true))
            if let max = cpuSensors.max() {
                list.append(Sensor(key: "Hottest CPU", name: "Hottest CPU", value: max, group: .CPU, type: .temperature, platforms: Platform.all, isComputed: true))
            }
        }
        if !gpuSensors.isEmpty {
            let value = gpuSensors.reduce(0, +) / Double(gpuSensors.count)
            list.append(Sensor(key: "Average GPU", name: "Average GPU", value: value, group: .GPU, type: .temperature, platforms: Platform.all, isComputed: true))
            if let max = gpuSensors.max() {
                list.append(Sensor(key: "Hottest GPU", name: "Hottest GPU", value: max, group: .GPU, type: .temperature, platforms: Platform.all, isComputed: true))
            }
        }
        
        // Init total power since launched, only if Total Power sensor is available
        if sensors.contains(where: { $0.key == "PSTR"}) {
            list.append(Sensor(key: "Total System Consumption", name: "Total System Consumption", value: 0, group: .sensor, type: .energy, platforms: Platform.all, isComputed: true))
            list.append(Sensor(key: "Average System Total", name: "Average System Total", value: 0, group: .sensor, type: .power, platforms: Platform.all, isComputed: true))
        }
        
        return list.filter({ (s: Sensor_p) -> Bool in
            switch s.type {
            case .temperature:
                return s.value < 110 && s.value >= 0
            case .voltage:
                return s.value < 300 && s.value >= 0
            case .current:
                return s.value < 100 && s.value >= 0
            default: return true
            }
        }).sorted { $0.key.lowercased() < $1.key.lowercased() }
    }
    
    public func unknownCallback() {
        self.unknownSensorsState = false
//        self.unknownSensorsState = Store.shared.bool(key: "Sensors_unknown", defaultValue: false)
    }
}

// MARK: - Fans


// MARK: - HID sensors

extension SensorsReader {
    private func m1Preset(type: SensorType) -> (Int32, Int32, Int32) {
        var page: Int32 = 0
        var usage: Int32 = 0
        var eventType: Int32 = kIOHIDEventTypeTemperature
        
        //  usagePage:
        //    kHIDPage_AppleVendor                        = 0xff00,
        //    kHIDPage_AppleVendorTemperatureSensor       = 0xff05,
        //    kHIDPage_AppleVendorPowerSensor             = 0xff08,
        //    kHIDPage_GenericDesktop
        //
        //  usage:
        //    kHIDUsage_AppleVendor_TemperatureSensor     = 0x0005,
        //    kHIDUsage_AppleVendorPowerSensor_Current    = 0x0002,
        //    kHIDUsage_AppleVendorPowerSensor_Voltage    = 0x0003,
        //    kHIDUsage_GD_Keyboard
        //
        
        switch type {
        case .temperature:
            page = 0xff00
            usage = 0x0005
            eventType = kIOHIDEventTypeTemperature
        case .current:
            page = 0xff08
            usage = 0x0002
            eventType = kIOHIDEventTypePower
        case .voltage:
            page = 0xff08
            usage = 0x0003
            eventType = kIOHIDEventTypePower
        case .power, .energy, .fan: break
        }
        
        return (page, usage, eventType)
    }
    
    private func initHIDSensors() -> [Sensor] {
        var list: [Sensor] = []
        
        for typ in SensorsReader.HIDtypes {
            let (page, usage, type) = self.m1Preset(type: typ)
            if let sensors = AppleSiliconSensors(page, usage, type) {
                sensors.forEach { (key, value) in
                    guard let key = key as? String, let value = value as? Double else {
                        return
                    }
                    var name: String = key
                    
                    HIDSensorsList.forEach { (s: Sensor) in
                        if s.key.contains("%") {
                            var index = 1
                            for i in 0..<64 {
                                if s.key.replacingOccurrences(of: "%", with: "\(i)") == key {
                                    name = s.name.replacingOccurrences(of: "%", with: "\(index)")
                                }
                                index += 1
                            }
                        } else if s.key == key {
                            name = s.name
                        }
                    }
                    
                    list.append(Sensor(
                        key: key,
                        name: name,
                        value: value,
                        group: .hid,
                        type: typ,
                        platforms: Platform.all
                    ))
                }
            }
        }
        
        let socSensors = list.filter({ $0.key.hasPrefix("SOC MTR Temp") }).map{ $0.value }
        if !socSensors.isEmpty {
            let value = socSensors.reduce(0, +) / Double(socSensors.count)
            list.append(Sensor(key: "Average SOC", name: "Average SOC", value: value, group: .hid, type: .temperature, platforms: Platform.all))
            if let max = socSensors.max() {
                list.append(Sensor(key: "Hottest SOC", name: "Hottest SOC", value: max, group: .hid, type: .temperature, platforms: Platform.all))
            }
        }
        
        return list.filter({ (s: Sensor_p) -> Bool in
            switch s.type {
            case .temperature:
                return s.value < 110 && s.value >= 0
            case .voltage:
                return s.value < 300 && s.value >= 0
            case .current:
                return s.value < 100 && s.value >= 0
            default: return true
            }
        }).sorted { $0.key.lowercased() < $1.key.lowercased() }
    }
    
    public func HIDCallback() {
        if self.HIDState {
            self.list.sensors += self.initHIDSensors()
        } else {
            self.list.sensors = self.list.sensors.filter({ $0.group != .hid })
        }
    }
}

// MARK: - Apple Silicon power sensors

extension SensorsReader {
    private func getChannels() -> CFMutableDictionary? {
        let channelNames: [(String, String?)] = [("Energy Model", nil)]
        
        var channels: [CFDictionary] = []
        for (gname, sname) in channelNames {
            let channel = IOReportCopyChannelsInGroup(gname as CFString?, sname as CFString?, 0, 0, 0)
            guard let channel = channel?.takeRetainedValue() else { continue }
            channels.append(channel)
        }
        
        let chan = channels[0]
        for i in 1..<channels.count {
            IOReportMergeChannels(chan, channels[i], nil)
        }
        
        let size = CFDictionaryGetCount(chan)
        guard let channel = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, size, chan),
              let chan = channel as? [String: Any], chan["IOReportChannels"] != nil else {
            return nil
        }
        
        return channel
    }
    
    private func initIOSensors() -> [Sensor] {
        guard let (cpu, gpu, ane, ram, pci) = self.IOSensors() else { return [] }
        return [
            Sensor(key: "CPU Power", name: "CPU Power", value: cpu, group: .CPU, type: .power, platforms: Platform.apple, isComputed: true),
            Sensor(key: "GPU Power", name: "GPU Power", value: gpu, group: .GPU, type: .power, platforms: Platform.apple, isComputed: true),
            Sensor(key: "ANE Power", name: "ANE Power", value: ane, group: .system, type: .power, platforms: Platform.apple, isComputed: true),
            Sensor(key: "RAM Power", name: "RAM Power", value: ram, group: .system, type: .power, platforms: Platform.apple, isComputed: true),
            Sensor(key: "PCI Power", name: "PCI Power", value: pci, group: .system, type: .power, platforms: Platform.apple, isComputed: true)
        ]
    }
    
    private func IOSensors() -> (Double, Double, Double, Double, Double)? {
        guard let sample = IOReportCreateSamples(self.subscription, self.channels, nil)?.takeRetainedValue(),
              let dict = sample as? [String: Any] else {
            return nil
        }
        let items = dict["IOReportChannels"] as! CFArray
        
        let prevCPU = self.powers.CPU
        let prevGPU = self.powers.GPU
        let prevANE = self.powers.ANE
        let prevRAM = self.powers.RAM
        let prevPCI = self.powers.PCI
        
        for i in 0..<CFArrayGetCount(items) {
            let dict = CFArrayGetValueAtIndex(items, i)
            let item = unsafeBitCast(dict, to: CFDictionary.self)
            
            guard let group = IOReportChannelGetGroup(item)?.takeUnretainedValue() as? String,
                  group == "Energy Model",
                  let channel = IOReportChannelGetChannelName(item)?.takeUnretainedValue() as? String,
                  let unit = IOReportChannelGetUnitLabel(item)?.takeUnretainedValue() as? String else { continue }
            
            let value = Double(IOReportSimpleGetIntegerValue(item, 0))
            
            if channel.hasSuffix("CPU Energy") {
                self.powers.CPU = value.power(unit)
            } else if channel.hasSuffix("GPU Energy") {
                self.powers.GPU = value.power(unit)
            } else if channel.starts(with: "ANE") {
                self.powers.ANE = value.power(unit)
            } else if channel.starts(with: "DRAM") {
                self.powers.RAM = value.power(unit)
            } else if channel.starts(with: "PCI") && channel.hasSuffix("Energy") {
                self.powers.PCI = value.power(unit)
            }
        }
        
        guard prevCPU != 0 else { return (0, 0, 0, 0, 0) } // omit first read
        
        return (
            self.powers.CPU - prevCPU,
            self.powers.GPU - prevGPU,
            self.powers.ANE - prevANE,
            self.powers.RAM - prevRAM,
            self.powers.PCI - prevPCI
        )
    }
}

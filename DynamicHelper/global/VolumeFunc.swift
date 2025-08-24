//
//  VolumeFunc.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/28/25.
//

import CoreAudio
import Foundation
import AudioToolbox


/// 偵測這台裝置可用哪種音量路徑
private struct VolumePath {
    let useVirtualMaster: Bool
    let channels: [UInt32] // e.g. [1,2]
}

private func hasProperty(_ dev: AudioObjectID,
                         _ sel: AudioObjectPropertySelector,
                         _ scope: AudioObjectPropertyScope,
                         _ elem: AudioObjectPropertyElement) -> Bool {
    var addr = AudioObjectPropertyAddress(mSelector: sel, mScope: scope, mElement: elem)
    return AudioObjectHasProperty(dev, &addr)
}

private func isSettable(_ dev: AudioObjectID,
                        _ sel: AudioObjectPropertySelector,
                        _ scope: AudioObjectPropertyScope,
                        _ elem: AudioObjectPropertyElement) -> Bool {
    var addr = AudioObjectPropertyAddress(mSelector: sel, mScope: scope, mElement: elem)
    var settable = DarwinBoolean(false)
    return AudioObjectIsPropertySettable(dev, &addr, &settable) == noErr && settable.boolValue
}

/// 取得預設輸出裝置
private func defaultOutputDevice() -> AudioDeviceID? {
    var dev = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &dev) == noErr,
          dev != kAudioObjectUnknown else { return nil }
    return dev
}


private func probeVolumePath(_ dev: AudioDeviceID) -> VolumePath? {
    // 1) 優先用 Virtual Master（一次控整體）
    if hasProperty(dev, kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                   kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain) {
        return VolumePath(useVirtualMaster: true, channels: [])
    }
    // 2) 退到左右聲道
    var ch: [UInt32] = []
    if hasProperty(dev, kAudioDevicePropertyVolumeScalar,
                   kAudioDevicePropertyScopeOutput, 1) { ch.append(1) }
    if hasProperty(dev, kAudioDevicePropertyVolumeScalar,
                   kAudioDevicePropertyScopeOutput, 2) { ch.append(2) }
    return ch.isEmpty ? nil : VolumePath(useVirtualMaster: false, channels: ch)
}

class VolumeFunc {
    enum DeviceType {
        case input
        case output
        case unkown
    }
    
    static func getSystemVolume() -> Float32? {
        guard let dev = defaultOutputDevice(),
              let path = probeVolumePath(dev) else { return nil }
        
        var size = UInt32(MemoryLayout<Float32>.size)
        if path.useVirtualMaster {
            var addr = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            var v: Float32 = 0
            guard AudioObjectGetPropertyData(dev, &addr, 0, nil, &size, &v) == noErr else { return nil }
            return max(0, min(1, v))
        } else {
            var vals: [Float32] = []
            for ch in path.channels {
                var addr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: ch
                )
                var v: Float32 = 0
                var s = size
                if AudioObjectGetPropertyData(dev, &addr, 0, nil, &s, &v) == noErr {
                    vals.append(v)
                }
            }
            return vals.isEmpty ? nil : max(0, min(1, vals.reduce(0,+) / Float32(vals.count)))
        }
    }
    
    
    static func setSystemVolume(_ volume: Float32) {
        guard let dev = defaultOutputDevice(),
              let path = probeVolumePath(dev) else {
            // 外接 HDMI/DP 多半會走到這裡：沒有硬體音量
            return
        }
        let v = max(0, min(1, volume))
        let size = UInt32(MemoryLayout<Float32>.size)
        
        if path.useVirtualMaster &&
            isSettable(dev, kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                       kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain) {
            var addr = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            var vv = v
            _ = AudioObjectSetPropertyData(dev, &addr, 0, nil, size, &vv)
            return
        }
        
        // 退到左右聲道：至少寫到一個即可
        for ch in path.channels {
            if isSettable(dev, kAudioDevicePropertyVolumeScalar,
                          kAudioDevicePropertyScopeOutput, ch) {
                var addr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: ch
                )
                var vv = v
                _ = AudioObjectSetPropertyData(dev, &addr, 0, nil, size, &vv)
            }
        }
    }
    
    
    static func isSystemMuted() -> Bool {
        guard let dev = defaultOutputDevice() else { return false }
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        guard hasProperty(dev, addr.mSelector, addr.mScope, addr.mElement) else { return false }
        var m: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(dev, &addr, 0, nil, &size, &m) == noErr ? (m != 0) : false
    }
    
    
    static func setSystemMute(_ mute: Bool) {
        guard let dev = defaultOutputDevice() else { return }
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        guard hasProperty(dev, addr.mSelector, addr.mScope, addr.mElement),
              isSettable(dev, addr.mSelector, addr.mScope, addr.mElement) else { return }
        var m: UInt32 = mute ? 1 : 0
        _ = AudioObjectSetPropertyData(dev, &addr, 0, nil, UInt32(MemoryLayout<UInt32>.size), &m)
    }
    
    
    static func getAllAbleOutputDevice() -> [UInt32:(name:String,type:DeviceType)]? {
        var propertySize: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // 先取得所有裝置
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize
        )
        
        if status != noErr {
            print("❌ 取得裝置清單大小失敗: \(status)")
            return nil
        }
        
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        let status2 = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceIDs
        )
        
        if status2 != noErr {
            print("❌ 取得裝置清單失敗: \(status2)")
            return nil
        }
        
        var Devices: [UInt32:(name:String,type:DeviceType)] = [:]
        
        
        for deviceID in deviceIDs {
            var deviceName = "" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            
            let nameStatus = withUnsafeMutablePointer(to: &deviceName) { ptr in
                AudioObjectGetPropertyData(
                    deviceID,
                    &nameAddress,
                    0,
                    nil,
                    &nameSize,
                    ptr
                )
            }
            
            if nameStatus == noErr {
                let name = deviceName as String
                Devices[deviceID] = (name,getDeviceType(deviceID))
            } else {
                Devices[deviceID] = ("unknown",.unkown)
            }
        }
        return Devices
    }
    
    static func getDeviceType(_ deviceID: AudioDeviceID) -> DeviceType {
        var streamsSize: UInt32 = 0
        var streamsAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &streamsAddress,
            0,
            nil,
            &streamsSize
        )
        
        if status != noErr {
            return .unkown
        }
        
        let streamCount = Int(streamsSize) / MemoryLayout<AudioStreamID>.size
        return streamCount > 0 ? .output : .input
    }
    
    static func switchOutputDevice(named targetName: String) {
        var devices: [UInt32:(name:String,type:DeviceType)] = [:]
        if let d = getAllAbleOutputDevice(){
            devices = d
        }else{
            return
        }
        
        for deviceID in devices.keys {
            if(devices[deviceID]?.name == targetName){
                setOutputDevice(deviceID)
            }
        }
        print("❌ 找不到符合名稱 '\(targetName)' 的裝置")
        return
        
    }
    
    
    static func setOutputDevice(_ deviceID: AudioDeviceID) {
        var deviceID = deviceID
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )
        
        if status == noErr {
            VolumeListenerManager.VolumeManager.removeVolumeListener()
            VolumeListenerManager.VolumeManager.setupVolumeListener()
        } else {
            print("❌ 切換預設輸出裝置失敗: \(status)")
        }
    }
    
    static func getCurrentOutputDeviceID() -> UInt32? {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &defaultOutputDeviceID
        )
        
        if status != noErr {
            //        print("取得預設輸出裝置失敗: \(status)")
            return nil
        }
        
        return UInt32(defaultOutputDeviceID)
        
    }
    
}


//var VolumeManager = VolumeListenerManager()

final class VolumeListenerManager: ObservableObject {
    static let VolumeManager = VolumeListenerManager()
    
    private var queue = DispatchQueue(label: "VolumeListenerQueue")
    private var outputDeviceID = AudioDeviceID(0)
    private var volumeBlock: AudioObjectPropertyListenerBlock?
    private var installedAddrs: [AudioObjectPropertyAddress] = []

    @Published var volume: Float32 = 0
    @Published var isMuted: Bool = false
    @Published var canGetVolume: Bool = true

    init() { setupVolumeListener() }
    deinit { removeVolumeListener() }

    func setupVolumeListener() {
        removeVolumeListener()

        guard let dev = defaultOutputDevice() else { return }
        outputDeviceID = dev

        // 根據可用路徑決定要聽哪些屬性
        var addrs: [AudioObjectPropertyAddress] = []

        if hasProperty(dev, kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                       kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain) {
            addrs.append(.init(mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                               mScope: kAudioDevicePropertyScopeOutput,
                               mElement: kAudioObjectPropertyElementMain))
        } else {
            if hasProperty(dev, kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeOutput, 1) {
                addrs.append(.init(mSelector: kAudioDevicePropertyVolumeScalar,
                                   mScope: kAudioDevicePropertyScopeOutput,
                                   mElement: 1))
            }
            if hasProperty(dev, kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeOutput, 2) {
                addrs.append(.init(mSelector: kAudioDevicePropertyVolumeScalar,
                                   mScope: kAudioDevicePropertyScopeOutput,
                                   mElement: 2))
            }
        }
        if hasProperty(dev, kAudioDevicePropertyMute, kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain) {
            addrs.append(.init(mSelector: kAudioDevicePropertyMute,
                               mScope: kAudioDevicePropertyScopeOutput,
                               mElement: kAudioObjectPropertyElementMain))
        }

        volumeBlock = { [weak self] _, _ in self?.refresh() }

        if let block = volumeBlock {
            for var a in addrs {
                let st = AudioObjectAddPropertyListenerBlock(dev, &a, queue, block)
                if st == noErr { installedAddrs.append(a) }
            }
        }

        // 再加：預設輸出裝置變更時，重建監聽
        var devAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let sysBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.setupVolumeListener()
            return// noErr
        }
        _ = AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject),
                                                &devAddr, queue, sysBlock)

        refresh()
    }

    func removeVolumeListener() {
        guard outputDeviceID != 0 else { return }
        if let block = volumeBlock {
            for var a in installedAddrs {
                _ = AudioObjectRemovePropertyListenerBlock(outputDeviceID, &a, queue, block)
            }
        }
        installedAddrs.removeAll()
        volumeBlock = nil
    }

    private func refresh() {
        DispatchQueue.main.async {
            let v = VolumeFunc.getSystemVolume()
            self.canGetVolume = (v != nil)
            self.volume = v ?? 0
            self.isMuted = VolumeFunc.isSystemMuted() ?? false
        }
    }
}

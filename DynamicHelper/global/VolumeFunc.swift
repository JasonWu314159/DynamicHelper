//
//  VolumeFunc.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/28/25.
//

import CoreAudio
import Foundation

enum DeviceType {
    case input
    case output
    case unkown
}

func getSystemVolume() -> Float32? {
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
    
    address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: 0
    )
    
    var volume: Float32 = 0
    size = UInt32(MemoryLayout<Float32>.size)
    let volumeStatus = AudioObjectGetPropertyData(
        defaultOutputDeviceID,
        &address,
        0,
        nil,
        &size,
        &volume
    )
    
    if volumeStatus != noErr {
//        print("取得音量失敗: \(volumeStatus)")
        return nil
    }
    
    return volume
}

func setSystemVolume(_ volume: Float32) {
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
        print("取得預設輸出裝置失敗: \(status)")
        return
    }
    
    address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: 0
    )
    
    var newVolume = volume
    let setStatus = AudioObjectSetPropertyData(
        defaultOutputDeviceID,
        &address,
        0,
        nil,
        UInt32(MemoryLayout<Float32>.size),
        &newVolume
    )
    
    if setStatus != noErr {
        print("設定音量失敗: \(setStatus)")
    }
}

func isSystemMuted() -> Bool? {
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
        print("取得預設輸出裝置失敗: \(status)")
        return nil
    }
    
    address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyMute,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: 0 // 這裡也是 0，代表主通道
    )
    
    var muted: UInt32 = 0
    size = UInt32(MemoryLayout<UInt32>.size)
    let muteStatus = AudioObjectGetPropertyData(
        defaultOutputDeviceID,
        &address,
        0,
        nil,
        &size,
        &muted
    )
    
    if muteStatus != noErr {
        print("取得靜音狀態失敗: \(muteStatus)")
        return nil
    }
    
    return muted != 0
}


func setSystemMute(_ mute: Bool) {
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
        print("取得預設輸出裝置失敗: \(status)")
        return
    }
    
    address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyMute,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: 0 // 主聲道
    )
    
    var muteValue: UInt32 = mute ? 1 : 0
    let muteStatus = AudioObjectSetPropertyData(
        defaultOutputDeviceID,
        &address,
        0,
        nil,
        UInt32(MemoryLayout<UInt32>.size),
        &muteValue
    )
    
    if muteStatus != noErr {
        print("設定靜音失敗: \(muteStatus)")
    }
}


func getAllAbleOutputDevice() -> [UInt32:(name:String,type:DeviceType)]? {
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

func getDeviceType(_ deviceID: AudioDeviceID) -> DeviceType {
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

func switchOutputDevice(named targetName: String) {
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


func setOutputDevice(_ deviceID: AudioDeviceID) {
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
        VolumeManager.removeVolumeListener()
        VolumeManager.setupVolumeListener()
    } else {
        print("❌ 切換預設輸出裝置失敗: \(status)")
    }
}

func getCurrentOutputDeviceID() -> UInt32? {
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


var VolumeManager = VolumeListenerManager()

final class VolumeListenerManager: ObservableObject {
    private var volumeListenerQueue = DispatchQueue(label: "VolumeListenerQueue")
    private var outputDeviceID = AudioDeviceID(0)
    private var volumeListenerBlock: AudioObjectPropertyListenerBlock?
    private var isSuspended = false

    @Published var volume: Float32 = 0
    @Published var isMuted: Bool = false
    @Published var canGetVolume: Bool = true

    init() {
        setupVolumeListener()
    }

    deinit {
        removeVolumeListener()
    }

    func setupVolumeListener() {
        // 取得預設輸出裝置
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
            &outputDeviceID
        )
        
        if status != noErr {
            print("取得預設輸出裝置失敗: \(status)")
            return
        }
        
        // 監聽音量變化
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        
        volumeListenerBlock = { [weak self] (_, _) in
            guard let self = self else { return }
            self.fetchVolumeState()
        }
        
        if let block = volumeListenerBlock {
            let volumeListenerStatus = AudioObjectAddPropertyListenerBlock(
                outputDeviceID,
                &volumeAddress,
                volumeListenerQueue,
                block
            )
            
            if volumeListenerStatus != noErr {
                print("添加音量監聽器失敗: \(volumeListenerStatus)")
            }
            
            let muteListenerStatus = AudioObjectAddPropertyListenerBlock(
                outputDeviceID,
                &muteAddress,
                volumeListenerQueue,
                block
            )
            if muteListenerStatus != noErr {
                print("添加靜音監聽器失敗: \(muteListenerStatus)")
            }
        }
        
        // 第一次自己抓一次音量
        fetchVolumeState()
    }
    
    func removeVolumeListener() {
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        
        let volumeRemoveStatus = AudioObjectRemovePropertyListenerBlock(
            outputDeviceID,
            &volumeAddress,
            volumeListenerQueue,
            volumeListenerBlock!
        )
        if volumeRemoveStatus != noErr {
            print("移除音量監聽器失敗: \(volumeRemoveStatus)")
        }
        let muteRemoveStatus = AudioObjectRemovePropertyListenerBlock(
            outputDeviceID,
            &muteAddress,
            volumeListenerQueue,
            volumeListenerBlock!
        )
        if muteRemoveStatus != noErr {
            print("移除靜音監聽器失敗: \(muteRemoveStatus)")
        }
    }
    
    private func fetchVolumeState() {
        DispatchQueue.main.async {
            self.canGetVolume = getSystemVolume() != nil
            self.volume = getSystemVolume() ?? 0
            self.isMuted = isSystemMuted() ?? false
        }
    }
    
    func pauseListening() {
        if !isSuspended {
            volumeListenerQueue.suspend()
            isSuspended = true
        }
    }
    
    func resumeListening() {
        if isSuspended {
            volumeListenerQueue.resume()
            isSuspended = false
        }
    }
}

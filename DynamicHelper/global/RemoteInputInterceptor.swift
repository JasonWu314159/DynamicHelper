//
//  RemoteInputInterceptor.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/8/4.
//

import Cocoa
import Carbon
import CoreGraphics
import AppKit
import SwiftUI

class RemoteInputInterceptor {
    static var shared: RemoteInputInterceptor = RemoteInputInterceptor()
    
    static var DetectionTime: Double = 5
    static var DetectionInterval: Double = 0.5
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    public private(set) var ConnectSocket: SocketServer?
    public private(set) var clientInfo: SocketServer.ClientInfo = SocketServer.ClientInfo(ip: "127.0.0.1", port: 8888,fd: 0)
    private var lastTimeIslandType: IslandTypeManager.IslandType = .hide
    private var ReconnectTimer: Timer?
    private var CurrentInputSource: TISInputSource?
    
    public private(set) var isControling: Bool = false
    
    func setClientInfo(_ clientInfo: SocketServer.ClientInfo?) {
        self.clientInfo = clientInfo ?? self.clientInfo
    }

    func startContorl() -> Bool{
        guard let ConnectSocket = self.ConnectSocket else {print("Socket daed"); return false }
        var hasThisClient:Bool = false
        ConnectSocket.connectedClients.forEach{ (_, info) in 
            if info.ip == self.clientInfo.ip{
                self.clientInfo = info
                hasThisClient = true
            }
        }
        if !hasThisClient{print("no client"); return false }
        
        if !ConnectSocket.isAlive(info: self.clientInfo){print("client daed"); return false }
        
        if isControling{print("already controling"); return false }
        
        
        guard eventTap == nil else {print("???"); return false}
        
        let eventTypes: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .otherMouseDown, .otherMouseUp,
            .mouseMoved,
            .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
            .scrollWheel
        ]
        let mask: CGEventMask = eventTypes.reduce(0) { $0 | (UInt64(1) << $1.rawValue) }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: eventTapCallback,
            userInfo: refcon
        )

        guard let eventTap = eventTap else {
            print("❌ 無法建立 event tap")
            return false
        }
        

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        lastTimeIslandType = islandTypeManager.getNowIslandType()
        islandTypeManager.OutsideChangeIslandType(to: .RemoteControl)
        isControling = true
        rememberCurrentInputSource()
        _ = SwitchToABC()
        
        let pasteboard = NSPasteboard.general
        if let copied = pasteboard.string(forType: .string) {
            ConnectSocket.sendResponse("clipboard:\(copied)\n", to: clientInfo)
        }
        return true
    }

    func HandleInputEvent(_ event: CGEvent)  {
        if !SwitchToABC(){print("switch to abc failed"); return}
        if let nsEvent = NSEvent(cgEvent: event),
           event.type == .keyDown || event.type == .flagsChanged {
            let keyCode = nsEvent.keyCode
            let flags = nsEvent.modifierFlags

            // ✅ 偵測中斷熱鍵：Command + Option + Escape（keyCode 53 是 Esc）
            if (flags.contains(.command) && flags.contains(.option) && flags.contains(.control) && keyCode == kVK_ANSI_U) 
                || (flags.contains(.command) && flags.contains(.option) && keyCode == 53)
            {
                print("🛑 偵測到強制停止熱鍵，取消攔截")
                stopControl()
                ConnectSocket?.stop()
                return
            }
        }
        
        var info: [String: Any] = [:]

        switch event.type {
        case .keyDown, .keyUp:
            if let nsEvent = NSEvent(cgEvent: event) {
                info["eventType"] = "\(event.type.rawValue)"
                info["keyCode"] = nsEvent.keyCode
                info["key"] = nsEvent.charactersIgnoringModifiers ?? "?"
                let flags = nsEvent.modifierFlags
                var modifiers: [String] = []
                // 按著時的狀態
                if flags.contains(.command) {
                    if nsEvent.keyCode == 55 { modifiers.append("commandLeft") }
                    else if nsEvent.keyCode == 54 { modifiers.append("commandRight") }
                    else { modifiers.append("command") }
                }
                if flags.contains(.shift) {
                    if nsEvent.keyCode == 56 { modifiers.append("shiftLeft") }
                    else if nsEvent.keyCode == 60 { modifiers.append("shiftRight") }
                    else { modifiers.append("shift") }
                }
                if flags.contains(.control) {
                    if nsEvent.keyCode == 59 { modifiers.append("controlLeft") }
                    else if nsEvent.keyCode == 62 { modifiers.append("controlRight") }
                    else { modifiers.append("control") }
                }
                if flags.contains(.option) {
                    if nsEvent.keyCode == 58 { modifiers.append("optionLeft") }
                    else if nsEvent.keyCode == 61 { modifiers.append("optionRight") }
                    else { modifiers.append("option") }
                }
                info["modifiers"] = modifiers
            }
            
        case .flagsChanged:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
            info["eventType"] = "\(event.type.rawValue)"
            info["keyCode"] = keyCode
            info["key"] = "modifier"
            var modifiers: [String] = []
            if flags.contains(.command) {
                if keyCode == 55 { modifiers.append("commandLeft") }
                else if keyCode == 54 { modifiers.append("commandRight") }
                else { modifiers.append("command") }
            }
            if flags.contains(.shift) {
                if keyCode == 56 { modifiers.append("shiftLeft") }
                else if keyCode == 60 { modifiers.append("shiftRight") }
                else { modifiers.append("shift") }
            }
            if flags.contains(.control) {
                if keyCode == 59 { modifiers.append("controlLeft") }
                else if keyCode == 62 { modifiers.append("controlRight") }
                else { modifiers.append("control") }
            }
            if flags.contains(.option) {
                if keyCode == 58 { modifiers.append("optionLeft") }
                else if keyCode == 61 { modifiers.append("optionRight") }
                else { modifiers.append("option") }
            }

            info["modifiers"] = modifiers
        case .mouseMoved, .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
                .leftMouseDragged, .rightMouseDragged, .scrollWheel, .otherMouseDown, .otherMouseDragged, .otherMouseUp:
            info["eventType"] = "\(event.type.rawValue)"
            let loc = event.location
            let x:CGFloat;
            let y:CGFloat;
            if let info = getCurrentScreenMouseInfo() {
                x = loc.x / info.pointSize.width
                y = loc.y / info.pointSize.height
            } else {
                print("無法判定滑鼠所在螢幕")
                x = loc.x
                y = loc.y
            }
            info["position"] = ["x": x, "y": y]
            if event.type == .scrollWheel {
                info["scrollDeltaY"] = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)
            }
        default:
            return
        }

        if let json = try? JSONSerialization.data(withJSONObject: info),
           let jsonString = String(data: json, encoding: .utf8) {
            guard let ConnectSocket = self.ConnectSocket else {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "連線失敗"
                    alert.informativeText = "socket server還沒啟動"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "確定")
                    alert.runModal()
                }
                stopControl();
                return 
            }
            if !ConnectSocket.isAlive(info: self.clientInfo){
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "連線失敗"
                    alert.informativeText = "被控端已斷線"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "確定")
                    alert.runModal()
                }
                stopControl();
                return 
            }
            
             print("📤to:\(clientInfo) 發送字串：\(jsonString)")
            ConnectSocket.sendResponse(jsonString, to: clientInfo)
        }
    }

    func stopControl() {
        islandTypeManager.OutsideChangeIslandType(to: lastTimeIslandType)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        runLoopSource = nil
        eventTap = nil
        isControling = false
        SwitchToCurrent()
    }

    func startFoundOtherComputer(DetectionTime: Double = RemoteInputInterceptor.DetectionTime, DetectionInterval: Double = RemoteInputInterceptor.DetectionInterval) {
        guard let ip = getLocalIPv4Address() else {
            print("沒找到ip")
            return
        }
        print("開始廣播")
        let uDPBroadcaster = UDPBroadcaster(message: ip)
        uDPBroadcaster.startBroadcasting(interval: DetectionInterval)
        ConnectSocket = ConnectSocket ?? SocketServer()
        ConnectSocket?.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + DetectionTime) {
            uDPBroadcaster.stopBroadcasting()
//            if self.ConnectSocket?.getConnectedClientsAmout() == 0 {
//                self.ConnectSocket?.stop()
//            } else {
//                clientInfo = ConnectSocket.
//                self.startContorl()
//            }
            print("結束廣播")
        }
    }
    
    func ReconnectToLastComputer(DetectionTime: Double = 1, DetectionInterval: Double = 0.1) {
        startFoundOtherComputer(DetectionTime:DetectionTime, DetectionInterval: DetectionInterval)
        ReconnectTimer?.invalidate()
        ReconnectTimer = nil
        ReconnectTimer = Timer.scheduledTimer(withTimeInterval: DetectionInterval, repeats: true) { _ in
            if self.startContorl(){
                self.ReconnectTimer?.invalidate()
                self.ReconnectTimer = nil
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DetectionTime) {
            self.ReconnectTimer?.invalidate()
            self.ReconnectTimer = nil
        }
    }
    
    func rememberCurrentInputSource(){
        guard let currentInputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            print("⚠️ 無法取得目前輸入法")
            return
        }
        CurrentInputSource = currentInputSource
    }
    
    func SwitchToABC() -> Bool{
        guard let currentInputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            print("⚠️ 無法取得目前輸入法")
            return false
        }
        // 2. 找到英文（ABC）輸入法
        let properties = [
            kTISPropertyInputSourceID: "com.apple.keylayout.ABC"
        ] as CFDictionary

        guard let abcInputSources = TISCreateInputSourceList(properties, false)?.takeRetainedValue() as? [TISInputSource],
              let abcInputSource = abcInputSources.first else {
            print("⚠️ 無法找到 ABC 輸入法")
            return false
        }
        
        if currentInputSource != abcInputSource {
            // 3. 切換成 ABC
            let statusSet = TISSelectInputSource(abcInputSource)
            if statusSet != noErr {
                print("⚠️ 無法切換到 ABC 輸入法")
                return false 
            }
        }
        return true
    }
    
    func SwitchToCurrent(){
        let statusRestore = TISSelectInputSource(CurrentInputSource)
        if statusRestore != noErr {
            print("⚠️ 無法還原原本輸入法")
        }
    }
    
}

@_cdecl("eventTapCallback")
func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passUnretained(event)
    }

    let interceptor = Unmanaged<RemoteInputInterceptor>.fromOpaque(refcon).takeUnretainedValue()
    interceptor.HandleInputEvent(event)
    return nil // 阻止本地處理（可改為 return event 傳下去）
}

struct ScreenMouseInfo {
    let pointSize: CGSize           // 螢幕解析度（點）
    let pixelSize: CGSize           // 螢幕解析度（像素）
    let mouseLocationInScreen: CGPoint  // 滑鼠在該螢幕中的相對位置（點）
}

func getCurrentScreenMouseInfo() -> ScreenMouseInfo? {
    let globalMouseLocation = NSEvent.mouseLocation

    guard let screen = NSScreen.screens.first(where: { $0.frame.contains(globalMouseLocation) }) else {
        return nil
    }

    let screenFrame = screen.frame
    let scale = screen.backingScaleFactor

    let mouseInScreen = CGPoint(
        x: globalMouseLocation.x - screenFrame.origin.x,
        y: globalMouseLocation.y - screenFrame.origin.y
    )

    let pointSize = screenFrame.size
    let pixelSize = CGSize(width: pointSize.width * scale, height: pointSize.height * scale)

    return ScreenMouseInfo(
        pointSize: pointSize,
        pixelSize: pixelSize,
        mouseLocationInScreen: mouseInScreen
    )
}

extension AppDelegate{
    func SetShortCutKey() {
        HotKeyManager.shared.registerHotKey(
            keyCode: UInt32(kVK_ANSI_U),
            modifiers: UInt32(cmdKey | optionKey | controlKey)
        ) {
            print("✅ 快捷鍵 Cmd+Option+Control+U 被觸發")
            let t:Double = 1
            let i:Double = 0.1
            RemoteInputInterceptor.shared.ReconnectToLastComputer(DetectionTime: t,DetectionInterval: i)
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                if !RemoteInputInterceptor.shared.isControling{
                    self.showRemoteControlChooseWindow()
                }
            }
        }
    }
}

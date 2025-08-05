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
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var ConnectSocket: SocketServer?
    private var clientInfo: SocketServer.ClientInfo = SocketServer.ClientInfo(ip: "127.0.0.1", port: 8888)
    private var lastTimeIslandType: IslandTypeManager.IslandType = .hide

    func startContorl() {
        guard eventTap == nil else { return }
        lastTimeIslandType = islandTypeManager.getNowIslandType()
        islandTypeManager.OutsideChangeIslandType(to: .RemoteControl)
        
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
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func HandleInputEvent(_ event: CGEvent)  {
        if let nsEvent = NSEvent(cgEvent: event),
           event.type == .keyDown || event.type == .flagsChanged {
            let keyCode = nsEvent.keyCode
            let flags = nsEvent.modifierFlags

            // ✅ 偵測中斷熱鍵：Command + Option + Escape（keyCode 53 是 Esc）
            if flags.contains(.command) && flags.contains(.option) && keyCode == 53 {
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
                if flags.contains(.command) { modifiers.append("command") }
                if flags.contains(.shift) { modifiers.append("shift") }
                if flags.contains(.control) { modifiers.append("control") }
                if flags.contains(.option) { modifiers.append("option") }
                info["modifiers"] = modifiers
            }
            
        case .flagsChanged:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
            info["eventType"] = "\(event.type.rawValue)"
            info["keyCode"] = keyCode
            info["key"] = "modifier"
            var modifiers: [String] = []
            if flags.contains(.command) { modifiers.append("command") }
            if flags.contains(.shift) { modifiers.append("shift") }
            if flags.contains(.control) { modifiers.append("control") }
            if flags.contains(.option) { modifiers.append("option") }
            info["modifiers"] = modifiers
        case .mouseMoved, .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
                .leftMouseDragged, .rightMouseDragged, .scrollWheel, .otherMouseDown, .otherMouseDragged, .otherMouseUp:
            info["eventType"] = "\(event.type.rawValue)"
            let loc = event.location
            let x:CGFloat;
            let y:CGFloat;
            if let info = getCurrentScreenMouseInfo() {
//                print("螢幕點數解析度：\(info.pointSize.width) x \(info.pointSize.height)")
//                print("螢幕像素解析度：\(info.pixelSize.width) x \(info.pixelSize.height)")
//                print("滑鼠在螢幕內部座標（點）：x=\(info.mouseLocationInScreen.x), y=\(info.mouseLocationInScreen.y)")
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
//            print("📤 發送字串：\(jsonString)")
            ConnectSocket?.broadcast(jsonString+"\n")
//            ConnectSocket?.sendResponse(jsonString, to: clientInfo)
            // sendToWindows(jsonString) // 你自己的傳送函式
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
    }

    func startFoundOtherComputer() {
        guard let ip = getLocalIPv4Address() else {
            print("沒找到ip")
            return
        }
        print("開始廣播")
        let uDPBroadcaster = UDPBroadcaster(message: ip)
        uDPBroadcaster.startBroadcasting()
        ConnectSocket = ConnectSocket ?? SocketServer()
        ConnectSocket?.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            uDPBroadcaster.stopBroadcasting()
            if self.ConnectSocket?.getConnectedClientsAmout() == 0 {
                self.ConnectSocket?.stop()
            } else {
//                clientInfo = ConnectSocket.
                self.startContorl()
            }
            print("結束廣播")
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


struct RemoteControlHint:View{
    
    let size:CGFloat = 20.0
    
    var body: some View {
        HStack{
            Text("按⌥+⌘+⎋結束").foregroundStyle(.white)
            Spacer()
            Text("遠端遙控中").foregroundStyle(.white)
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.8))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Image(systemName: "desktopcomputer.and.macbook")
                    .font(.system(size: size*0.8))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size*1.2)
            
        }.padding(.horizontal,10)
    }
    
}

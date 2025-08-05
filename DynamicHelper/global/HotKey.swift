//
//  HotKey.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/8/5.
//

import Cocoa
import Carbon.HIToolbox

class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    
    func registerHotKey(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        var eventHotKeyID = EventHotKeyID(signature: OSType(bitPattern: Int32(truncatingIfNeeded: "HK01".fourCharCodeValue)),
                                          id: 1)
        
        // 將 handler 存起來，配合回調使用
        self.hotKeyHandler = handler
        
        // 註冊快捷鍵
        let status = RegisterEventHotKey(keyCode,
                                         modifiers,
                                         eventHotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)
        
        guard status == noErr else {
            print("❌ 註冊快捷鍵失敗：\(status)")
            return
        }
        
        // 安裝熱鍵事件處理
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(theEvent,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hotKeyID)
            
            if hotKeyID.signature == OSType(bitPattern: Int32(truncatingIfNeeded: "HK01".fourCharCodeValue)) {
                HotKeyManager.shared.hotKeyHandler?()
            }
            
            return noErr
        }, 1, [EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                            eventKind: UInt32(kEventHotKeyPressed))], nil, nil)
    }
    
    private var hotKeyHandler: (() -> Void)?
}

extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        if let data = self.data(using: .macOSRoman), data.count == 4 {
            data.withUnsafeBytes {
                result = $0.load(as: FourCharCode.self)
            }
        }
        return result
    }
}

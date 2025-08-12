//
//  keycodeTrans.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/8/11.
//

import Foundation

class KeycodeTransfer{
    static private let macKeyCodeToHIDUsage_0x07: [UInt16: UInt16] = [
        // 字母
        0: 0x04,   // A
        11: 0x05,  // B
        8: 0x06,   // C
        2: 0x07,   // D
        14: 0x08,  // E
        3: 0x09,   // F
        5: 0x0A,   // G
        4: 0x0B,   // H
        34: 0x0C,  // I
        38: 0x0D,  // J
        40: 0x0E,  // K
        37: 0x0F,  // L
        46: 0x10,  // M
        45: 0x11,  // N
        31: 0x12,  // O
        35: 0x13,  // P
        12: 0x14,  // Q
        15: 0x15,  // R
        1:  0x16,  // S
        17: 0x17,  // T
        32: 0x18,  // U
        9:  0x19,  // V
        13: 0x1A,  // W
        7:  0x1B,  // X
        16: 0x1C,  // Y
        6:  0x1D,  // Z

        // 數字列與符號
        18: 0x1E,  // 1
        19: 0x1F,  // 2
        20: 0x20,  // 3
        21: 0x21,  // 4
        23: 0x22,  // 5
        22: 0x23,  // 6
        26: 0x24,  // 7
        28: 0x25,  // 8
        25: 0x26,  // 9
        29: 0x27,  // 0
        36: 0x28,  // Return / Enter
        53: 0x29,  // Escape
        51: 0x2A,  // Delete (Backspace)
        48: 0x2B,  // Tab
        49: 0x2C,  // Space
        27: 0x2D,  // -
        24: 0x2E,  // =
        33: 0x2F,  // [
        30: 0x30,  // ]
        42: 0x31,  // \ (US)
        41: 0x33,  // ;
        39: 0x34,  // '
        50: 0x35,  // ` (Grave)
        43: 0x36,  // ,
        47: 0x37,  // .
        44: 0x38,  // /

        // 控制/功能鍵
        57: 0x39,  // Caps Lock
        122: 0x3A, // F1
        120: 0x3B, // F2
        99:  0x3C, // F3
        118: 0x3D, // F4
        96:  0x3E, // F5
        97:  0x3F, // F6
        98:  0x40, // F7
        100: 0x41, // F8
        101: 0x42, // F9
        109: 0x43, // F10
        103: 0x44, // F11
        111: 0x45, // F12

        // 導航鍵
        114: 0x49, // Insert/Help
        115: 0x4A, // Home
        116: 0x4B, // Page Up
        117: 0x4C, // Forward Delete
        119: 0x4D, // End
        121: 0x4E, // Page Down
        124: 0x4F, // →
        123: 0x50, // ←
        125: 0x51, // ↓
        126: 0x52, // ↑

        // 小鍵盤
        71:  0x53, // Num Lock / Clear（Apple 鍵盤作為 Clear）
        75:  0x54, // Numpad /
        67:  0x55, // Numpad *
        78:  0x56, // Numpad -
        69:  0x57, // Numpad +
        76:  0x58, // Numpad Enter
        83:  0x59, // Numpad 1
        84:  0x5A, // Numpad 2
        85:  0x5B, // Numpad 3
        86:  0x5C, // Numpad 4
        87:  0x5D, // Numpad 5
        88:  0x5E, // Numpad 6
        89:  0x5F, // Numpad 7
        91:  0x60, // Numpad 8
        92:  0x61, // Numpad 9
        82:  0x62, // Numpad 0
        65:  0x63, // Numpad .
        81:  0x67, // Numpad =
        
        // 更多功能鍵
        105: 0x68, // F13
        107: 0x69, // F14
        113: 0x6A, // F15
        106: 0x6B, // F16
        64:  0x6C, // F17
        79:  0x6D, // F18
        80:  0x6E, // F19
        // 若有 F20+ 依需要再擴充（0x6F..0x73）
        
        // 修飾鍵（注意：左右手區分）
        59:  0xE0, // Left Control
        56:  0xE1, // Left Shift
        58:  0xE2, // Left Option (Alt)
        55:  0xE3, // Left GUI (Command)
        62:  0xE4, // Right Control
        60:  0xE5, // Right Shift
        61:  0xE6, // Right Option (Alt)
        54:  0xE7, // Right GUI (Command)
    ]

    /// 反向：HID Usage (Page 0x07) → macOS keyCode
    static private var hidUsageToMacKeyCode_0x07: [UInt16: UInt16] = {
        var dict: [UInt16: UInt16] = [:]
        for (k, v) in macKeyCodeToHIDUsage_0x07 { dict[v] = k }
        return dict
    }()

    /// 取得 HID Keyboard/Keypad usage。回傳 (page, usage)
    static func hidFromMacKeyCode(_ keyCode: UInt16) -> (page: UInt16, usage: UInt16) {
        guard let usage = macKeyCodeToHIDUsage_0x07[keyCode] else { return (page: 0x0, usage: 0x0) }
        return (0x07, usage)
    }

    /// 自 HID Keyboard/Keypad usage 取得 macOS keyCode
    static func macKeyCodeFromHID(page: UInt16, usage: UInt16) -> UInt16? {
        guard page == 0x07 else { return nil }
        return hidUsageToMacKeyCode_0x07[usage]
    }
}

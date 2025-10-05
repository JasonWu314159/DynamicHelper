//
//  SensorAndNet.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/28.
//

import SwiftUI
import Combine
import Cocoa

// MARK: - Helpers

/// 數值格式
struct TextFormat {
    enum unit: String {
        case percent = "%"
        case Celsius = "ºC"
        case Fahrenheit = "ºF"
        case Power = "W"
        case Volt = "V"
        case ampere = "A"
        case Energy = "Wh"
        case byte_s = "B/s"
        case ibyte_s = "iB/s"
        case byte = "B"
        case ibyte = "iB"
        case bps = "bps"
        
        var canPrefix: Bool{
            switch self{
            case .percent,.Celsius,.Fahrenheit: return false
            default: return true
            }
        }
    }
    
    var Value: Double
    var Unit: unit
    var isBinary = false
    var length: Int
    func toString(_ haveSpace:Bool = false) -> String{Format()}
    
    init(_ Value: Double, Unit: unit, length: Int = 3) {
        self.Value = Value
        self.Unit = Unit
        self.length = length
        if [unit.ibyte_s,unit.ibyte].contains(Unit){isBinary = true}
    }
    
    private func Format(haveSpace:Bool = false) -> String{
        let bigPrefixes = ["", "K", "M", "G", "T", "P", "E"]
        let smallPrefixes = ["", "m", "µ", "n", "p", "f", "a"]
        
        var v = Value
        var index = 0
        let range:Double = isBinary ? 1024 : 1000
        
        let s = haveSpace ? " " : ""
        if v == 0 { return "0\(s)\(Unit.rawValue)" }
        
        
        if !Unit.canPrefix {
            let l:Int = Int(log10(v))+1
            let formatted = String(format: "%.\(length-l)f", v)
            return "\(formatted)\(s)\(Unit.rawValue)"
        }
        
        if abs(v) >= 1 {
            // 大於等於 1 → K, M, G...
            while abs(v) >= range && index < bigPrefixes.count - 1 {
                v /= range
                index += 1
            }
            let l:Int = Int(log10(v))+1
            let formatted = String(format: "%.\(length-l)f", v)
            return "\(formatted)\(s)\(bigPrefixes[index])\(Unit.rawValue)"
        } else {
            // 小於 1 → m, µ, n...
            while abs(v) < 1 && index < smallPrefixes.count - 1 {
                v *= range
                index += 1
            }
            let l:Int = Int(log10(v))+1
            let formatted = String(format: "%.\(length-l)f", v)
            return "\(formatted)\(s)\(smallPrefixes[index])\(Unit.rawValue)"
        }
    }
    
}


// MARK: - View





/// 小型數值方塊，適合窄區域
struct MetricTile: View {
    var icon: NSImage? = nil
    var symbol: String? = nil
    let title: String
    let value: String
    let color: Color
    var textSize: CGFloat = 13
    var monospaced: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            if let icn = icon{
                Image(nsImage: icn)
            }
            if let sym = symbol{
                Image(systemName: sym)
                    .font(.system(size: textSize))
            }
            Text(title)
                .font(.system(size: textSize*0.8))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Text(value)
                .font(.system(size: textSize, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .if(monospaced) { v in v.monospacedDigit() }
//                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
    }
}

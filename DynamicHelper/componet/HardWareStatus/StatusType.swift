//
//  StatusType.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/28.
//

import SwiftUI

final class StatusModel: ObservableObject {
    static let shared = StatusModel()
    
    @Published private(set) var nowType: statusType = .home
    
    func setNowType(_ t:statusType){
        withAnimation(.easeInOut(duration: 0.3)){
            nowType = t
        }
    }
    
    enum statusType: String, CaseIterable, Hashable, Identifiable {
        
        case home = "總覽"
        case system = "系統資訊"
        case bettery = "電池"
        case CPU = "處理器"
        case GPU = "顯示卡"
        case RAM = "記憶體"
        case sensor = "感測器"
        case network = "網路"
        case disk = "硬碟"
        
        var icon: String {
            switch self {
            case .home: "house.fill";
            case .system: "macbook";
            case .bettery: "battery.100";
            case .CPU: "cpu.fill";
            case .GPU: "display";
            case .RAM: "memorychip.fill";
            case .sensor: "sensor.fill";
            case .network: "wifi.router.fill";
            case .disk: "opticaldiscdrive.fill";
            default: "";
            }
        }
        
        var id: String { rawValue }   // ✅ ForEach 需要 identifiable
        
        static var allCases: [statusType] {
            return [.home,.system,.bettery,.CPU, .GPU, .RAM, .sensor, .network, .disk]
                .filter { $0 != StatusModel.shared.nowType }
        }
        
    }
    
}

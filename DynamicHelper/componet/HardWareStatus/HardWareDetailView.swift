//
//  HardWareDetailView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/28.
//

import SwiftUI


struct HardWareDetailView: View {
    @ObservedObject private var model: StatusModel = .shared
    var body: some View {
        Group{
            switch model.nowType{
            case .system: CMPInfo()
            case .bettery: BatteryDetail()
            case .CPU: CPUDetail()
            case .GPU: GPUDetail()
            case .RAM: RAMDetail()
            case .sensor: SensorDetail()
            case .network: NetworkDetail()
            case .disk: SSDDetail()
            default:
                HardwareInfoView().id(model.nowType)
            }
        }
    }
}

//
//  CMPInfo.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/28.
//

import SwiftUI

struct CMPInfo: View {
    let SystemInfo = SystemKit.shared.device
    
    var body: some View{
        HStack{
            macImage
            GeometryReader { geo in
                let size: CGFloat = 0.55
                HStack{
                    HarewareInfo.frame(width: geo.size.width * size)
                    ComputerInfo.frame(width: geo.size.width * (1-size))
                }
            }
        }
        .padding(.bottom,5)
        .padding(.horizontal,20)
    }
    
    
    private var macImage: some View {
        VStack{
            let icon = SystemInfo.model.icon
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width:icon.size.width*0.7, height:icon.size.height*0.7)
            
            Text(SystemInfo.model.name)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
                .font(.system(size: 12))
                .bold()
            Text(
                "macOS \(SystemInfo.os?.name ?? "")(\(SystemInfo.os?.version.getFullVersion() ?? ""))"
            ).minimumScaleFactor(0.6)
            .foregroundStyle(.white)
            .font(.system(size: 10))
            .bold()
            
            Label("詳細資訊",systemImage: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.white)
                .frame(width: 90,height: 18)
                .background(
                    Color.gray.opacity(0.4)
                        .clipShape(RoundedRectangle(cornerRadius: 8,style: .continuous))
                )
                .hoverPressEffect {
                    
                    let path = "/System/Applications/Utilities/System Information.app"
                    let url = URL(fileURLWithPath: path)
                    NSWorkspace.shared.open(url)
                }
        }
    }
    
    private var HarewareInfo: some View {
        VStack(spacing:0){
            Text("硬體規格")
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            let info = SystemInfo.info
            MetricTile(
                title: "處理器",
                value: "\(info.cpu?.name ?? "")\n\(info.cpu?.physicalCores ?? 0)核心,\(info.cpu?.logicalCores ?? 0)執行緒\n\(info.cpu?.pCores ?? 0)效能,\(info.cpu?.eCores ?? 0)節能",
                color: .white
            )
            .frame(minHeight: 45)
            Divider().foregroundStyle(.white)
            MetricTile(
                title: "記憶體",
                value: "\(info.ram?.dimms[0].size ?? "0B")",
                color: .white
            )
            Divider().foregroundStyle(.white)
            MetricTile(
                title: "顯示卡",
                value: "\(info.gpu?[0].name ?? "") (\(info.gpu?[0].cores ?? 0)核心)",
                color: .white
            )
            Divider().foregroundStyle(.white)
            let size = TextFormat(Double(info.disk?[0].size ?? 0) ,Unit: .byte)
            MetricTile(
                title: "硬碟",
                value: "\(info.disk?[0].name ?? "") (\(size.toString()))",
                color: .white
            )
        }
//            .layoutPriority(1)
        .background(
            Color.gray.opacity(0.2)
            .clipShape(RoundedRectangle(cornerRadius: 5,style: .continuous))
        )
    }
    
    private var ComputerInfo: some View {
        VStack(spacing:0){
            Text("本機資訊")
                .foregroundStyle(.white.opacity(0.9))

            Spacer()
            MetricTile(
                title: "機型識別碼",
                value: "\(SystemInfo.model.id)",
                color: .white
            )
            Divider().foregroundStyle(.white)
            MetricTile(
                title: "製造年份",
                value: "\(SystemInfo.model.year)",
                color: .white
            )
            Divider().foregroundStyle(.white)
            MetricTile(
                title: "序號",
                value: "\(SystemInfo.serialNumber)",
                color: .white
            )
            Divider().foregroundStyle(.white)
            let interval:Int = Int(Date().timeIntervalSince(SystemInfo.bootDate))
            MetricTile(
                title: "開機時間",
                value: "\(interval/3600)h\(interval%3600/60)m",
                color: .white
            )
        }
        .background(
            Color.gray.opacity(0.2)
            .clipShape(RoundedRectangle(cornerRadius: 5,style: .continuous))
        )
    }
}


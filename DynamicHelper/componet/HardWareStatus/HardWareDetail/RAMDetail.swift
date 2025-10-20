//
//  RAMDetail.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/29.
//

import SwiftUI

struct RAMDetail: View {
    @State private var ramLoad:RAM_Usage?
    @State private var RAM_UsageTypes:[UsageType] = []
    @State private var timer: Timer?
    
    @State private var RamTotal: TextFormat = TextFormat(0,Unit: .ibyte,isBinary: true)
    @State private var RamUsed: TextFormat = TextFormat(0,Unit: .ibyte,isBinary: true)
    @State private var RamAppUsed: TextFormat = TextFormat(0,Unit: .ibyte,isBinary: true)
    @State private var RamSysUsed: TextFormat = TextFormat(0,Unit: .ibyte,isBinary: true)
    @State private var RamCompress: TextFormat = TextFormat(0,Unit: .ibyte,isBinary: true)
    @State private var RamFree: TextFormat = TextFormat(0,Unit: .ibyte,isBinary: true)
    @State private var RamSwap: TextFormat = TextFormat(0,Unit: .ibyte,isBinary: true)
    @State private var RamCache: TextFormat = TextFormat(0,Unit: .ibyte,isBinary: true)
    
    @State private var RamPressure: Int = 0
    @State private var height: CGFloat = 0
    @State private var width: CGFloat = 0
    
    @State private var HigherUsageProccesses:[TopProcess] = []

    
    var body: some View {
        HStack{
            VStack{
                UsageTypeBoard(
                    usageType:RAM_UsageTypes,
                    label:"記憶體\n\(String(format: "%.1f%%", (ramLoad?.used ?? 0) / (ramLoad?.total ?? 1) * 100))",
                    lineWidth: 13,
                    TypeDetial: false
                )
                .onAppear{
                    startMonitoring()
                }
                .onDisappear{
                    stopMonitoring()
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { width = proxy.size.width }
                            .onChange(of: proxy.size.width) {_,new in width = new }
                    }
                )
                
                MetricTile(
                    dot: .gray,
                    title: "空閒：",
                    value: RamFree.toString(),
                    titleColor: .white,
                    color: .white
                )
                .frame(width:width)
            }
            VStack{
                Text("壓力")
                    .foregroundStyle(.white)
                HStack(spacing: 1){
                    VStack(spacing: 0){
                        Rectangle().fill(.red).frame(maxHeight:.infinity)
                        Rectangle().fill(.yellow).frame(maxHeight:.infinity)
                        Rectangle().fill(.green).frame(maxHeight:.infinity)
                    }.frame(width:5)
                    
                    Image(systemName: "arrowtriangle.left.fill")
                        .foregroundStyle(.white)
                        .offset(y: height/3.0*CGFloat(RamPressure))
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { height = proxy.size.height }
                            .onChange(of: proxy.size.height) {_,new in height = new }
                    }
                )
            }
            .padding(.bottom,10)
            
            Detail
            
            Proccesses
        }
        .padding(.horizontal,20)
    }
    
    
    private var Detail: some View{
        VStack(spacing:0){
            Text("詳細資訊")
                .foregroundStyle(.white)
            Spacer()
            MetricTile(
                title: "實體記憶體：",
                value: RamTotal.toString(),
                titleColor: .white,
                color: .white
            )
            MetricTile(
                title: "記憶體用量：",
                value: RamUsed.toString(),
                titleColor: .white,
                color: .white
            )
            MetricTile(
                dot: .blue,
                title: "App記憶體：",
                value: RamAppUsed.toString(),
                titleColor: .white,
                color: .white
            )
            MetricTile(
                dot: .orange,
                title: "系統核心記憶體：",
                value: RamSysUsed.toString(),
                titleColor: .white,
                color: .white
            )
            MetricTile(
                dot: .red,
                title: "已壓縮：",
                value: RamCompress.toString(),
                titleColor: .white,
                color: .white
            )
            MetricTile(
                title: "快取的檔案：",
                value: RamCache.toString(),
                titleColor: .white,
                color: .white
            )
            MetricTile(
                title: "使用的交換檔：",
                value: RamSwap.toString(),
                titleColor: .white,
                color: .white
            )
        }.background(
            Color.gray.opacity(0.2)
            .clipShape(RoundedRectangle(cornerRadius: 10,style: .continuous))
        )
    }
    
    
    private var Proccesses: some View {
        VStack(spacing:0){
            Text("高使用程序")
                .foregroundStyle(.white)
            Spacer()
            ForEach(HigherUsageProccesses,id:\.pid){ topProcess in 
                MetricTile(
                    icon: topProcess.icon,
                    title: topProcess.name,
                    value: TextFormat(topProcess.usage,Unit: .ibyte,isBinary: true).toString(),
                    titleColor: .white,
                    color: .white
                )
            }
        }.background(
            Color.gray.opacity(0.2)
            .clipShape(RoundedRectangle(cornerRadius: 10,style: .continuous))
        )
    }
    
    
    func startMonitoring() {
        stopMonitoring()
        self.update()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            
            self.update()
            
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func update(){
        guard let ramLoad = RAMStateMonitor.shared.read() else{ return }
        self.ramLoad = ramLoad
        RAM_UsageTypes = [UsageType(ramLoad.app / ramLoad.total,.blue, name:"App"),UsageType(ramLoad.wired / ramLoad.total,.orange, name:"核心"),UsageType(ramLoad.compressed / ramLoad.total,.red, name:"已壓縮")]
        RamTotal.Value = ramLoad.total
        RamUsed.Value = ramLoad.used
        RamAppUsed.Value = ramLoad.app
        RamSysUsed.Value = ramLoad.wired
        RamCompress.Value = ramLoad.compressed
        RamCache.Value = ramLoad.cache
        RamSwap.Value = ramLoad.swap.used
        RamFree.Value = ramLoad.free
        
        RamPressure = 2 - ramLoad.pressure.level
        
        HigherUsageProccesses = RAMProcessReader.shared.read(7)
    }
}

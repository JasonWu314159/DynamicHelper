//
//  InputAnimate.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/28.
//

import SwiftUI


struct InputAnimation: View  {
    @State var spacing: CGFloat = 0
    @State private var isPluggedIn: Bool = false
    @State private var timer: Timer?
    @State private var isShowInputAnimation: Bool = false
    @State private var AnimateQueue: [Bool] = []
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 10) {
                Image(systemName: "cable.connector.horizontal")
                    .foregroundStyle(.white)
                    .font(.system(size: geometry.size.height))
                    .offset(x:spacing)
                HStack {
                    Image("Magsafe")
                        .resizable()
                        .scaledToFit()
                }.frame(width: geometry.size.height, height: geometry.size.height)
            }
        }
        .clipped()
        .onAppear {
            startMonitoring()
            if !isPluggedIn{
                showInputAnimation(isPluggedIn)
            }
        }
        .onChange(of: isPluggedIn) { _,batteryInfo in
            showInputAnimation(batteryInfo)
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    func showInputAnimation(_ PluggedIn: Bool) {
        if isShowInputAnimation {
            if AnimateQueue.count < 1{
                AnimateQueue.append(PluggedIn)
            }
            return 
        }
        isShowInputAnimation = true
        let p = PluggedIn
        self.spacing = p ? 0 : 20
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                self.spacing = p ? 20 : 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isShowInputAnimation = false
                if AnimateQueue.count > 0 {
                    showInputAnimation(AnimateQueue.first!)
                    AnimateQueue.removeFirst()
                }
            }
        }
    }
    
    func startMonitoring() {
        updateBatteryInfo() // 立即更新一次
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateBatteryInfo()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func updateBatteryInfo() {
        if let info = PowerMonitor.getBatteryInfo() {
            isPluggedIn = info.isPluggedIn
        }
//        print(1)
    }
}

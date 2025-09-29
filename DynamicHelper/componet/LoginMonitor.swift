//
//  LoginMonitor.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/25.
//

import Foundation
import AppKit
import SwiftUI



struct LoginAnimation:View {
    @State var isUnlocking:Bool = false
    @State var isUnlock:Bool = false
    var body: some View {
        LockAnimationView(isUnlocked:$isUnlocking)
            .onAppear {
                isUnlockingAnimation()
            }
        Spacer()
        if isUnlock{
            Image(systemName: "macbook.badge.checkmark")
                .font(.system(size: 20))
                .foregroundColor(.green)
                .symbolEffect(.wiggle, value: isUnlock)
                .padding(.trailing,3)
        }
    }
    
    func isUnlockingAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.isUnlocking.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.5)){
                    self.isUnlock = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if islandTypeManager.getNowIslandType() == .onLogin{ 
                        islandTypeManager.OutsideChangeIslandType(to: .hide)
                    }
                }
            }
        }
    }
    
    struct LockAnimationView: View {
        @Binding var isUnlocked:Bool
        
        var body: some View {
            Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 20))
                .foregroundColor(isUnlocked ? .green : .gray)
                .symbolEffect(.wiggle, value: isUnlocked) // 系統提供的動畫效果
                .padding(4)
        }
    }
}

extension AppDelegate{
    func LoginObserver(_ notification: Notification) {
        let dnc = DistributedNotificationCenter.default()
        
        dnc.addObserver(forName: Notification.Name("com.apple.screenIsUnlocked"),
                        object: nil,
                        queue: .main) { _ in
            if islandTypeManager.getNowIslandType() == .hide{
                islandTypeManager.OutsideChangeIslandType(to:.onLogin)
            }
        }
    }
}

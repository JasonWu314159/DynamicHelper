//
//  MarqueeText.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/22/25.
//

import SwiftUI

struct MarqueeText: View {
    var text: String
    let speed: Double // 秒數越小越快
    var delay: Double = 1.0 // 開始前延遲
    var TextColor: Color = .white
    var Space: CGFloat = 15
    var font: Font = .system(size: 10)
    
    @State private var offsetX: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isVisible = false
    @State private var timer: Timer?

       var body: some View {
           GeometryReader { geometry in
               let containerW = geometry.size.width

               HStack(spacing: Space) {
                   Text(text)
                       .font(font)
                       .lineLimit(1)
                       .fixedSize()
                       .background(WidthReader(width: $textWidth, height: $textHeight, text: text, Space: Space))
                       .foregroundColor(TextColor)
                   if(textWidth > containerW){
                       Text(text)
                           .font(font).lineLimit(1).fixedSize().foregroundColor(TextColor)
                       Text(text)
                           .font(font).lineLimit(1).fixedSize().foregroundColor(TextColor)
                   }
               }
               .frame(width: containerW, height: geometry.size.height)
               .offset(x: offsetX)
               .onAppear {
                   isVisible = true
                   containerWidth = containerW
                   restartAnimation()
               }
               .onDisappear {
                   isVisible = false
                   stopAnimation()
               }
               .onChange(of: textWidth) { oldValue, newValue in
                   if abs(newValue - oldValue) > 1 {
                       restartAnimation()
                   }
               }
           }
           .clipped()
           .frame(height: textHeight)
       }

       func restartAnimation() {
           stopAnimation() // ✅ 停掉舊動畫
           offsetX = 0
           if(textWidth < containerWidth){return}
           offsetX = textWidth/2 - containerWidth/2 - Space/2
           let duration = speed * Double(textWidth)

           timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
               guard isVisible else { return }

               withAnimation(Animation.linear(duration: duration)) {
                   offsetX = -textWidth
               }

               timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
                   offsetX = 0
                   withAnimation(Animation.linear(duration: duration)) {
                       offsetX = -textWidth
                   }
               }
           }
       }

       func stopAnimation() {
           timer?.invalidate()
           timer = nil
           withAnimation(Animation.linear(duration: 0.0)) {
               offsetX = 0
           }
       }

}

// 幫忙讀取 Text 寬度
struct WidthReader: View {
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    var text: String
    let Space: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    width = geometry.size.width+Space
                    height = geometry.size.height+1
                }
                .onChange(of: text) {
                    width = geometry.size.width + Space
                    height = geometry.size.height + 1
                }
        }
    }
    
}

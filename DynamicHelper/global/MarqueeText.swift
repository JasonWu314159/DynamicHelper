//
//  MarqueeText.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/22/25.
//

import SwiftUI


struct MarqueeText: View {
    var text: String
    let speed: Double // 秒數越大越快
    var delay: Double = 1.0 // 開始前延遲
    var TextColor: Color = .white
    var Space: CGFloat = 15
    var font: Font = .system(size: 10)
    var fontWeight: Font.Weight = .regular
    
    @State private var offsetX: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var timer: Timer?
    
    @State private var startTime: Date?
    
    var body: some View {
        GeometryReader { geometry in
            let containerW = geometry.size.width
            TimelineView(.animation) { timeline in
                let now = timeline.date
                let start = startTime ?? now
                let elapsed = now.timeIntervalSince(start)
                let dx = -CGFloat(elapsed) * speed
                
                HStack(spacing: Space) {
                    Text(text)
                        .font(font)
                        .fontWeight(fontWeight)
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
                .offset(x: textWidth > containerW ? dx.truncatingRemainder(dividingBy: textWidth) : 0)
                .onAppear {
                    containerWidth = containerW
                    startTime = Date()
                }
            }
        }
        .clipped()
        .frame(height: textHeight)
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

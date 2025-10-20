//
//  SliderBar.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/22/25.
//

import SwiftUI

struct SliderBar: View {
    let progress: Double // 初始進度 (0 ~ 1)
    var ReturnOnEnd: Bool = true 
    let action: (Double,Bool) -> Void 
    
    
    @State private var DraggingProgress: Double = 0
    @State private var isDragging: Bool = false
    @State private var dragOffset: CGFloat? = nil
    
    var barHeight: CGFloat = 8
    var width: CGFloat = .infinity
    @State private var isHovering: Bool = false
    
    

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            VStack(alignment: .center) {
                ZStack(alignment: .leading) {
                    // 背景軌道
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: totalWidth,height: barHeight)
                    
                    // 已播放部分
                    Rectangle()
                        .fill(Color.white)
                        .frame(
                            width: max((isDragging ? DraggingProgress : progress) * totalWidth,0),
                            height: barHeight
                        )
                    
                    // 滑塊 knob
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: totalWidth, height: barHeight)
                        .cornerRadius(barHeight / 2)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let locationX = value.location.x
                                    if !isDragging {
                                        DraggingProgress = progress
                                    }
                                    isDragging = true
                                    // 第一次進入拖曳
                                    if dragOffset == nil {
                                        let endX = totalWidth * DraggingProgress
                                        dragOffset = locationX - endX
                                        
                                        // 是點一下（沒有移動）
                                        if abs(value.translation.width) < 1 {
                                            DraggingProgress = min(max(locationX / totalWidth, 0), 1)
                                            if !ReturnOnEnd {action(DraggingProgress,false)}
                                            dragOffset = nil
                                            return
                                        }
                                    }
                                    
                                    // 正在拖曳時，維持原有偏移
                                    if let offset = dragOffset {
                                        let newEndX = locationX - offset
                                        DraggingProgress = min(max(newEndX / totalWidth, 0), 1)
                                        if !ReturnOnEnd {action(DraggingProgress,false)}
                                    }
                                }
                                .onEnded { _ in
                                    dragOffset = nil
                                    isDragging = false
                                    action(DraggingProgress, true)
                                }
                        )
                    
                    
                }.cornerRadius(barHeight / 2)
                    .scaleEffect(x:isHovering ? 1.05 : 1.0,
                                    y:isHovering ? 1.4 : 1.0)
                    .frame(height: barHeight)
                    .frame(maxWidth: width)
                    .onHover{ hovering in
                        withAnimation(.easeInOut(duration: 0.2)){
                            isHovering = hovering
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: barHeight)
        .padding(.horizontal)
    }
}


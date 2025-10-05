//
//  HoverAndPressed.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/28.
//

import SwiftUI

struct HoverPressEffect: ViewModifier {
    
    var HoverBackground: Color// = .gray.opacity(0.4)
    var PressedBackground: Color// = .gray.opacity(0.3)
    var HoverScale: CGFloat// = 1.05
    var PressedScale: CGFloat {
        (HoverScale-1)/2+1
    }
    var cornerRadius: CGFloat// = 8
    var BGPadding: CGFloat
    var action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    
    
    func body(content: Content) -> some View {
        content
            .background(
                (isPressed ? PressedBackground :
                 isHovered ? HoverBackground :
                 Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius,style: .continuous))
                .padding(BGPadding)
            )
            .scaleEffect(isPressed ? PressedScale : (isHovered ? HoverScale : 1.0))
            .onHover { hovering in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    isHovered = hovering
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            isPressed = false
                            action()
                        }
                    }
            )
    }
}

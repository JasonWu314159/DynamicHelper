//
//  MenuItemButton.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/24/25.
//

import SwiftUI

let defaultMenuItemButtonSize:CGFloat = 25
let defaultMenuItemButtonSizeR:CGFloat = 0.6
let defaultMenuItemButtonResizeMagin:CGFloat = 1.1
let defaultMenuItemButtonRadius:CGFloat = 4

struct MenuItemButton: View {
    let systemName: String
    var radius: CGFloat = defaultMenuItemButtonRadius
    var onTap: (() -> Void)? = nil
    var size: CGFloat = defaultMenuItemButtonSize
    var width: CGFloat?// = defaultMenuItemButtonSize
    var height: CGFloat?// = defaultMenuItemButtonSize
    var ResizeMagin:CGFloat = defaultMenuItemButtonResizeMagin
    
    @State private var backgroundColor: CGFloat = 0.0
    @State private var isPressed = false
    @State private var isHovering = false
    @State private var showHelpText: Bool = false
    
    let sizeR:CGFloat = defaultMenuItemButtonSizeR
    
    var body: some View {
        let pressGesture = DragGesture(minimumDistance: 0)
            .onChanged { _ in
                isPressed = true
                backgroundColor = 0.4
            }
            .onEnded { _ in
                // 放開時還原顏色或執行其他動作
                isPressed = false
                backgroundColor = 0.5
                onTap?()
            }
        let s = min(width ?? size, height ?? size)
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.gray.opacity(backgroundColor))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Image(systemName: systemName)
                .font(.system(size: s*sizeR))
                .foregroundStyle(.white)
                .scaleEffect(isPressed ? 1.0 : defaultMenuItemButtonResizeMagin)
//                .padding(.leading)
        }
        .frame(width: width ?? size, height: height ?? size)
        .scaleEffect(isHovering ? ResizeMagin : 1.0)
        .onHover { IsHovering in
            if(isPressed){return}
            withAnimation(.easeInOut(duration: 0.1)){
                isHovering = IsHovering
                backgroundColor = isHovering ? 0.5 : 0.0
            }
        }
        .gesture(pressGesture)
    }
    
}

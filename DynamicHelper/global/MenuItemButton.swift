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
        let s = min(width ?? size, height ?? size)
        ZStack {
            Image(systemName: systemName)
                .font(.system(size: s*sizeR))
                .foregroundStyle(.white)
        }
        .frame(width: width ?? size, height: height ?? size)
        .hoverPressEffect(HS:ResizeMagin,CR:radius) {
            onTap?()
        }
    }
    
}

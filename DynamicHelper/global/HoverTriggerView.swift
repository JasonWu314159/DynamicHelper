//
//  HoverTriggerView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//

import SwiftUI
import AppKit



struct HoverTriggerView: View {
    @ObservedObject var hoverState: HoverState
    var appDelegate: AppDelegate
    
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(
                width: WindowSize[.hide]?.width,
                height: WindowSize[.hide]?.height
            )
            .cornerRadius(WindowSize[.hide]?.downRadius ?? 0)
            .contentShape(Rectangle())
            .onHover { hovering in
                hoverState.isHovering = hovering
                print(hoverState.isHovering)
            }
    }
}

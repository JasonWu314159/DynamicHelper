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
                width: IslandTypeManager.getWindowSize(.hide).width,
                height: IslandTypeManager.getWindowSize(.hide).height
            )
            .cornerRadius(IslandTypeManager.getWindowRadius(.hide).down)
            .contentShape(Rectangle())
            .onHover { hovering in
                hoverState.isHovering = hovering
                print(hoverState.isHovering)
            }
    }
}

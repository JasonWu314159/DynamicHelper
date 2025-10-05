//
//  ViewExtension.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/10/5.
//

import SwiftUI

// 小語法糖：條件修飾符
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

extension View {
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}


extension View {
    func hoverPressEffectColor(HBG:Color = .gray.opacity(0.4), PBG: Color = .gray.opacity(0.3), HS:CGFloat = 1.05, CR: CGFloat = 8,BGP: CGFloat = 0, action: @escaping () -> ()) -> some View {
        self.modifier(HoverPressEffect(
            HoverBackground:HBG,
            PressedBackground: PBG,
            HoverScale: HS,
            cornerRadius: CR, 
            BGPadding: BGP,
            action:action
        ))
    }
    
    func hoverPressEffect(HBG:CGFloat = 0.4, PBG: CGFloat = 0.3, HS:CGFloat = 1.05, CR: CGFloat = 8,BGP: CGFloat = 0, action: @escaping () -> ()) -> some View {
        self.modifier(HoverPressEffect(
            HoverBackground:.gray.opacity(HBG),
            PressedBackground: .gray.opacity(PBG),
            HoverScale: HS,
            cornerRadius: CR, 
            BGPadding: BGP,
            action:action
        ))
    }
}

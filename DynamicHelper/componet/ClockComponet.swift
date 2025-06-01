//
//  ClockComponet.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/5/2.
//

import SwiftUI

struct Alarm: View {
    @State private var selectedNumber1: Int = 4
    @State private var selectedNumber2: Int = 4
    @State private var selectedNumber3: Int = 4
    @State private var offsetY:CGFloat = 0
    var body: some View {
        HStack(spacing:20){
            WheelPicker(range: 0..<24, selection: $selectedNumber1).frame(width: 30)
            WheelPicker(range: 0..<60, selection: $selectedNumber2).frame(width: 30)
            WheelPicker(range: 0..<60, selection: $selectedNumber2).frame(width: 30)
        }
        .frame(height:100)
    }
}


struct BackTimer: View {
    var body: some View {
        Text("BackTimer")
            .foregroundStyle(.white)
    }
}


struct stopwatch: View {
    var body: some View {
        Text("stopwatch")
            .foregroundStyle(.white)
    }
}

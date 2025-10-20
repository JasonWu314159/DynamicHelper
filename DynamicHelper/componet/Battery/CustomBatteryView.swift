//
//  CustomBatteryView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/28.
//

import SwiftUI


struct CustomBatteryView: View {
    var level: CGFloat // 0.0 ~ 1.0
    var isCharge: Bool

    var body: some View {
        ZStack(alignment: .leading) {

            Image(systemName: "battery.0")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 12)
                .foregroundColor(.gray)
            RoundedRectangle(cornerRadius: 2)
                .fill(getColor())
                .frame(width: 18 * level, height: 7)
                .padding(.leading, 9.5)
        }
        .padding(.horizontal,0)
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.black)
                .frame(width: 6, height: 10)
                .offset(x: 32, y: 0)
            , alignment: .trailing
        )
    }
    
    func getColor() -> Color {
        var color: Color = .white
        if level >= 0.8 {
            if(isCharge){
                color = .green
            }else{
                color = .white
            }
        } else if level < 0.2 {
            if(isCharge){
                color = .yellow
            }else{
                color = .red
            }
        }
        return color
    }
}

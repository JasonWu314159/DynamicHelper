//
//  AirDropArea.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/24/25.
//

import SwiftUI

struct AirDropArea: View {
    @ObservedObject var airDropViewSpace = AirDropViewSpace
    var body: some View {
        GeometryReader { geo in
            ZStack{
                
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: airDropViewSpace.isHovering ? 10 : 5)
                    .frame(maxWidth: .infinity,maxHeight: .infinity)
            
                Rectangle()
                    .fill(Color.gray)
                    .frame(maxWidth: 50,maxHeight: 50)
                    .overlay(
                Image("airDropIcon")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity))
            }
            .padding()
            .frame(width: min(geo.size.width, geo.size.height))
            .onAppear {
                AirDropViewSpace.frame = geo.frame(in: .global)
                AirDropViewSpace.isHovering = false
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

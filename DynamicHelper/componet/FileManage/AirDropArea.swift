//
//  AirDropArea.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/24/25.
//

import SwiftUI

struct AirDropArea: View {
    @ObservedObject var airDropViewSpace = ViewSpace.AirDrop
    @State var isActive: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack{
                
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color(red: 0.5, green: 0.5, blue: 0.5), lineWidth: airDropViewSpace.isHovering ? 10 : 5)
                    .frame(maxWidth: .infinity,maxHeight: .infinity)
            
                AirDropIcon()
                    .fill(.gray)
                    .frame(maxWidth: 63,maxHeight: 63)
            }
            .padding()
            .frame(width: min(geo.size.width, geo.size.height))
            .onAppear {
                ViewSpace.AirDrop.isHovering = false
            }
            .onChange(of: geo.frame(in: .global)) { 
                ViewSpace.AirDrop.frame = geo.frame(in: .global)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
}

struct AirDropIcon: Shape {
    
    func path(in rect: CGRect) -> Path {
        let LineWidth:CGFloat = min(rect.midY,rect.midX)/7
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfLineWidth = LineWidth/2
        let angle = Angle.degrees(60)
        let PI = Angle.degrees(180)
        
        for i in stride(from: 3, to: 9, by: 2){
            let size = CGFloat(i)*LineWidth
            path.addArc(center: center,
                        radius: size,
                        startAngle: PI-angle,
                        endAngle: angle,
                        clockwise: false)
            path.addArc(center: CGPoint(x: rect.midX+(size-halfLineWidth)*CGFloat(cos(angle.radians)), y: rect.midY+(size-halfLineWidth)*CGFloat(sin(angle.radians))),
                        radius: halfLineWidth,
                        startAngle: angle,
                        endAngle: angle + PI,
                        clockwise: false)
            
            path.addArc(center: center,
                        radius: size-LineWidth,
                        startAngle: angle,
                        endAngle: PI - angle,
                        clockwise: true)
            
            path.addArc(center: CGPoint(x: rect.midX-(size-halfLineWidth)*CGFloat(cos(angle.radians)), y: rect.midY+(size-halfLineWidth)*CGFloat(sin(angle.radians))),
                        radius: halfLineWidth,
                        startAngle: -angle,
                        endAngle: PI-angle,
                        clockwise: false)
            path.closeSubpath()
        }
        path.addArc(center: center,
                    radius: LineWidth,
                    startAngle: -PI/2,
                    endAngle: PI*3/2,
                    clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

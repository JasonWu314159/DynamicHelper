//
//  Dashboard.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/6/8.
//

import SwiftUI
import Foundation

struct UsageType{
    var id: UUID = UUID()
    var name: String = ""
    var value: Double = 0
    var accumulation: Double = 0
    var foregroundColor: Color = .blue
    
    init(_ value: Double,_ foregroundColor: Color = .blue, name: String = "") {
        self.value = value
        self.foregroundColor = foregroundColor
        self.name = name
    }
}


struct UsageTypeBoard: View {
    
    var usageType: [UsageType]      // 目前值 (0~1)
    var label: String      // 中間顯示的文字
    var lineWidth: CGFloat
    var size: CGFloat = 110
    var testSize: CGFloat = 18
    var backgroundColor: Color
    var TypeDetial: Bool = true
    var onTap: (() -> Void)?
    
    @State private var isHover: Bool = false
    @State private var isPressed: Bool = false
    
    private var EmptyStartValue: Double{
        var sum:Double = 0
        for i in usageType{
            sum += i.value
        }
        if sum >= 1{return 1}
        else if sum <= 0{return 0}
        else {return sum}
    }
    
    init(usageType: [UsageType], label: String, lineWidth: CGFloat = 17, size: CGFloat = 110, testSize: CGFloat = 18, backgroundColor: Color = .gray.opacity(0.6),TypeDetial: Bool = true ,action: (() -> Void)? = nil){
        self.usageType = usageType
        self.label = label
        self.lineWidth = lineWidth
        self.backgroundColor = backgroundColor
        self.onTap = action
        self.TypeDetial = TypeDetial
        self.size = size
        self.testSize = testSize
        
        var accumulation: Double = 0
        for i in 0..<self.usageType.count{
            self.usageType[i].accumulation = accumulation
            accumulation += self.usageType[i].value
        }
//        print(self.usageType)
    }
    
    

    var body: some View {
        VStack{
            Spacer()
            ZStack {
                ZStack{
                    ZStack {
                        ForEach(usageType, id: \.id) { type in
                            SectorShape(startAngle: .degrees(360)*type.accumulation, endAngle: .degrees(360)*(type.accumulation+type.value),width:lineWidth)
                                .foregroundStyle(type.foregroundColor)
                        }
                        SectorShape(startAngle: .degrees(360)*EmptyStartValue, endAngle: .degrees(360),width:lineWidth)
                            .foregroundStyle(backgroundColor)
                    }.rotationEffect(Angle.degrees(-90))
                    Text(label)
                        .font(.system(size: testSize, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .scaleEffect(0.9)
            }
            .frame(width: size, height: size)
            .if(onTap != nil){content in 
                content.hoverPressEffect(HBG:0.2,PBG: 0.1,CR:15){
                    onTap?()
                }
            }
            if(TypeDetial){
                Spacer()
                HStack(spacing:0){
                    let size:CGFloat = 7;
                    let space:CGFloat = 1;
                    let spacer:CGFloat = 2;
                    Spacer(minLength: spacer)
                    ForEach(usageType, id: \.id) { type in
                        HStack(spacing:space){
                            RoundedRectangle(cornerRadius: size/4)
                                .foregroundStyle(type.foregroundColor)
                                .frame(width: size, height: size)
                            Text(type.name)
                                .font(.system(size: size))
                                .foregroundStyle(.white)
                        }
                        Spacer(minLength: spacer)
                    }
                    HStack(spacing:space){
                        RoundedRectangle(cornerRadius: size/4)
                            .foregroundStyle(backgroundColor)
                            .frame(width: size, height: size)
                        Text("閒置")
                            .font(.system(size: size))
                            .foregroundStyle(.white)
                    }
                    Spacer(minLength: spacer)
                }
            }
            Spacer()
        }
    }
}

struct SectorShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var width: CGFloat = 14
    var clockwise: Bool = false

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let sradius = radius - width
        
        let NewEndAngle: Angle = endAngle * ( clockwise ? -1 : 1)

        var path = Path()
//        path.move(to: center)
        path.move(to: CGPoint(x: rect.midX + CoreGraphics.cos(startAngle.radians) * sradius, y: rect.midY + CoreGraphics.sin(startAngle.radians) * sradius))
        path.addLine(to: CGPoint(x: rect.midX + CoreGraphics.cos(startAngle.radians) * radius, y: rect.midY + CoreGraphics.sin(startAngle.radians) * radius))
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: clockwise)
        path.addLine(to: CGPoint(x: rect.midX + CoreGraphics.cos(NewEndAngle.radians) * sradius, y: rect.midY + CoreGraphics.sin(NewEndAngle.radians) * sradius))
        path.addArc(center: center,
                    radius: sradius,
                    startAngle: endAngle,
                    endAngle: startAngle,
                    clockwise: !clockwise)
        path.closeSubpath()
        return path
    }
}

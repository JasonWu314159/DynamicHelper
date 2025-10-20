//
//  Clock.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/26/25.
//

import SwiftUI
import Combine


struct ClockView: View {
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let h_size = size/2
            let radius = h_size * 0.7
            
            
            ZStack {
                // 畫數字
                
                ForEach(1...12, id: \.self) { i in
                    let j = getTextAngle(i)
                    let x:CGFloat = h_size+cos(j)*radius
                    let y:CGFloat = h_size+sin(j)*radius
                    Text("\(i)")
                        .foregroundStyle(.white)
                        .position(x:x, y:y)
                }
                
                Text(DateFrom("time"))
                    .foregroundStyle(.white)
                    .position(x:h_size, y:h_size+radius*0.3)
                
                Text(DateFrom("date"))
                    .foregroundStyle(.white)
                    .position(x:h_size, y:h_size+radius*0.65)
                    .font(.system(size: 7))
                    .multilineTextAlignment(.center)
                
                TimelineView(.periodic(from: Date(), by: 0.1)){ ctx in
                    
                    let cal = Calendar.current
                    let comps = cal.dateComponents([.hour, .minute, .second, .nanosecond], from: ctx.date)
                    let h = Double(comps.hour ?? 0)// / 12.0
                    let m = Double(comps.minute ?? 0)// / 60.0
                    let s = (Double(comps.second ?? 0) + Double(comps.nanosecond ?? 0) / 1_000_000_000)// / 60.0
                    let hourAngle: Angle = Angle.degrees(h / 12.0 * 360.0 + m / 60.0 * 30.0)
                    let minuteAngle: Angle = Angle.degrees(m / 60.0 * 360.0 + s / 60.0 * 6.0)
                    let secondAngle: Angle = Angle.degrees(s * 6.0)
                    
                    // 畫時針、分針、秒針
                    ZStack{
                        ClockHand(length: (radius-8)*0.5, width: 6, color: .white, rotation: hourAngle)
                        ClockHand(length: (radius-8), width: 4, color: .white, rotation: minuteAngle)
                        ClockHand(length: (radius-8), width: 2, color: .red, rotation: secondAngle)
                    }
                }
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
            }
            .frame(width: size, height: size)
            .hoverPressEffect(HBG:0.2,PBG:0.1,HS:1,CR:size*0.2) {
                if(NSEvent.modifierFlags.contains(.command)){
                    openClockApp()
                    return
                }else{
                }
            }
            
        }
        .padding(.trailing,10)
        .aspectRatio(1, contentMode: .fit)
    }
    
    
    func getTextAngle(_ i:Int)->CGFloat{
        return CGFloat(CGFloat(i)*(2.0 * .pi)/12.0)-CGFloat.pi/2.0
    }
    
    func DateFrom(_ time:String)->String{
        let c = Calendar.current
        let d = Date()
        if(time == "date"){
            let weekday = ["日","一","二","三","四","五","六"][c.component(.weekday, from: d)-1]
            let dateForm:String = "\(c.component(.year, from: d))/\(c.component(.month, from: d))/\(c.component(.day, from: d))\n(\(weekday))"
            return dateForm
        }else if(time == "time"){
            let h = c.component(.hour, from: d)
            let n = ["子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"]
            return "\(n[((h+1)>>1)%12])時"
        }else{
            return ""
        }
    }
}

struct ClockHand: View {
    let length: CGFloat
    let width: CGFloat
    let color: Color
    let rotation: Angle

    var body: some View {
        RoundedRectangle(cornerRadius: width/2)
            .fill(color)
            .frame(width: width > 0 ? width : 10, height: length > 0 ? length : 10)
            .offset(y: -length/2)
            .rotationEffect(rotation)
    }
}



func openClockApp(){
    let script: String = """
    tell application "Clock"
        if it is not running then
            launch
        end if
        activate
    end tell
    """
    _ = NSAppleScript(source: script)?.executeAndReturnError(nil)
}

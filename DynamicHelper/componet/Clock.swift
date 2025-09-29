//
//  Clock.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/26/25.
//

import SwiftUI
import Combine


struct ClockView: View {
    @State private var date = Date()
    @State private var timerCancellable: Cancellable? = nil
    @State private var isHovering: Bool = false
    @State private var size:CGFloat = 0
    

    var body: some View {
        GeometryReader { geometry in
            let h_size = size/2
            let radius = h_size * 0.7
            
            ZStack {
                // 畫數字
//                RoundedRectangle(cornerRadius: size*0.2)
//                    .fill(isHovering && !islandTypeManager.checkNowIslandTypeIs(.Clock) ? .gray.opacity(0.2) : .clear)
//                    .frame(width: size*0.95, height: size*0.95)
                
                
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
                
                // 畫時針、分針、秒針
                ClockHand(length: (radius-8)*0.5, width: 6, color: .white, rotation: hourAngle)
                ClockHand(length: (radius-8), width: 4, color: .white, rotation: minuteAngle)
                ClockHand(length: (radius-8), width: 2, color: .red, rotation: secondAngle)
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
            }
            .frame(width: size, height: size)
            .onAppear{
                size = min(geometry.size.width, geometry.size.height)
            }
            .hoverPressEffect(HBG:0.2,PBG:0.1,HS:1,CR:size*0.2) {
                if(NSEvent.modifierFlags.contains(.command)){
                    openClockApp()
                    return
                }else{
    //                windowState.outsideChange = .Clock
                }
            }
//            .padding()
            
        }
        .padding(.trailing,10)
        .aspectRatio(1, contentMode: .fit)
        .onAppear { initTimer() }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
//        .contentShape(Rectangle())
//        .onTapGesture{
//            if(NSEvent.modifierFlags.contains(.command)){
//                openClockApp()
//                return
//            }else{
////                windowState.outsideChange = .Clock
//            }
//        }
//        .onHover { isHover in
//            withAnimation(.linear(duration: 0.2)) {
//                isHovering = isHover
//            }
//        }
    }
    
    func initTimer(){
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { input in
                self.date = input
            }
    }
    
    func getTextAngle(_ i:Int)->CGFloat{
        return CGFloat(CGFloat(i)*(2.0 * .pi)/12.0)-CGFloat.pi/2.0
    }
    
    func DateFrom(_ time:String)->String{
        if(time == "date"){
            let c = Calendar.current
            let d = Date()
            let weekday = ["日","一","二","三","四","五","六"][c.component(.weekday, from: d)-1]
            let dateForm:String = "\(c.component(.year, from: d))/\(c.component(.month, from: d))/\(c.component(.day, from: d))\n(\(weekday))"
            return dateForm
        }else if(time == "time"){
            let h = calendar.component(.hour, from: date)
            let n = ["子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"]
            return "\(n[((h+1)>>1)%12])時"
        }else{
            return ""
        }
    }

    var calendar: Calendar {
        Calendar.current
    }
    

    var hourAngle: Angle {
        let hour = calendar.component(.hour, from: date) % 12
        let minute = calendar.component(.minute, from: date)
        return Angle.degrees(Double(hour) / 12 * 360 + Double(minute) / 60 * 30)
    }

    var minuteAngle: Angle {
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        return Angle.degrees(Double(minute) / 60 * 360 + Double(second) / 60 * 6)
    }

    var secondAngle: Angle {
        let second = calendar.component(.second, from: date)
        let milliseconds = Int((date.timeIntervalSince1970 * 1000).truncatingRemainder(dividingBy: 1000))
        return Angle.degrees((Double(second) + Double(milliseconds) / 1000) / 60 * 360)
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

//
//  IslandView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//

import SwiftUI
import AppKit

struct IslandView: View {
    @ObservedObject var windowType = windowState
    @State private var dummyState = false
    @State private var isHovering = false
    @State private var mouseLocation = NSEvent.mouseLocation
    @ObservedObject var hoverState: HoverState = HoverState()
    var appDelegate: AppDelegate = AppDelegate()
    @State private var windowWidth: CGFloat = 0
    @State private var windowHeight: CGFloat = 0
    @State private var windowUpRadius: CGFloat = 0
    @State private var windowDownRadius: CGFloat = 0
    @State private var isInAnimation: Bool = false
    
    @State private var windowPosX: CGFloat = 0
    @State private var windowPosY: CGFloat = 0

    @State private var mousePosition: CGPoint = CGPoint()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: windowDownRadius)
                    .fill(Color.black.opacity(windowType.type == .hide ? 0.3 : 0.7))
                    .blur(radius: windowUpRadius/2) // 模糊模擬陰影散射
                    .frame(width: windowWidth-windowUpRadius*2, height: windowHeight+windowUpRadius)
                    .offset(y:-windowUpRadius/2)
                //.padding(getWindowRadius(windowType.type).up)
                
                HStack {
                    switch windowType.type {
                        case .hide:
                            EmptyView()
                        case .exten:
                            VStack{
                                MenuView(appDelegate: appDelegate).id(windowType.type)
                                Spacer()
                                HStack{
                                    MusicView().id(windowType.type)
                                    VStack{
                                        Spacer()
                                        CopyBookScroller().id(windowType.type)
//                                            .background(.blue)
                                    }
                                    ClockView().id(windowType.type)
                                }
                            }.padding(.vertical,5)
                        case .onCharge:
                            Spacer()
                            BatteryView().id(windowType.type)
                        case .Drop:
                            VStack{
                                MenuView(appDelegate: appDelegate).id(windowType.type)
                                Spacer()
                                HStack(spacing:0){
                                    AirDropArea().padding(.leading).id(windowType.type)
                                    DroppableIslandView().padding(.trailing).id(windowType.type)
                                }
                            }.padding(.vertical,5)
                        case .Clock:
                            VStack{
                                MenuView(appDelegate: appDelegate).id(windowType.type)
                                Spacer()
                                HStack{
                                    ClockView()
                                        .id(windowType.type)
                                    Spacer()
                                    Alarm()
                                    Spacer()
//                                    BackTimer()
                                    Spacer()
//                                    stopwatch()
                                }.id(windowType.type)
                                .padding(.horizontal)
                            }.padding(.vertical,5)
                        case .Hardware:
                            VStack{
                                MenuView(appDelegate: appDelegate)
                                Spacer()
                                HStack{
                                }
                                .padding(.horizontal)
                            }.id(windowType.type)
                            .padding(.vertical,5)
                        default:
                            EmptyView()
                            
                    }
                }
                .padding(.horizontal, windowUpRadius)
                .frame(width: windowWidth, height: windowHeight+EdgeToTop)
                .background(.black)
                .clipShape(TopRounded(Radius: (down:windowDownRadius, up:windowUpRadius)))
                //            .animation(nil, value: windowType.type)
                .onAppear(){
                    refreshWindowSize(type: windowType.type, isAnimated:false, Enforcement:true)
                    startIdleKeepAlive()
                }
                .onChange(of: hoverState.isDragger) {
                    getMousePosition()
                    if hoverState.isDragger{
                        onDraggerEvent(hoverState.isDragger)
                    }
                }
                .onChange(of: windowState.outsideChange) {
                    if(windowState.outsideChange != nil){
                        refreshWindowSize(
                            type:windowState.outsideChange ?? .hide,
                            Enforcement: windowState.ousideEnforceChange
                        )
                        windowState.outsideChange = nil
                        windowState.ousideEnforceChange = false
                    }
                }
                .onHover { hovering in
                    if(isInAnimation){return}
                    if(hoverState.isDragger){return}
                    if(windowType.isLock && !hovering){return}
                    onHoverEvent(hovering)
                    hoverState.isHovering = hovering
                }
                .onDrop(of: ["public.file-url"], isTargeted: $hoverState.isDragger) { providers in
                    // 實際 drop 時會觸發這裡
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                    {
                        withAnimation(.easeInOut(duration: 0.3)){
                            AirDropViewSpace.isHovering = false
                            FileDropViewSpace.isHovering = false
                        }
                    }
                    return handleDrop(providers: providers)
                }
                .onChange(of: windowHeight) { _,newValue in
                    print("✅ windowHeight 改變為：\(newValue)")
                }
            }
            .position(x: windowPosX,y: windowPosY)
        }
    }
    
    func getMousePosition(){
        mousePosition = getMousePoint()
        AirDropViewSpace.checkHovering(mousePosition)
        FileDropViewSpace.checkHovering(mousePosition)
        if(hoverState.isDragger){
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)
            {
                getMousePosition()
            }
        }
//        if !(0 < mousePosition.x 
//            && mousePosition.x < getWindowSize(windowType.type).width
//            && 0 < mousePosition.y
//            && mousePosition.y < getWindowSize(windowType.type).height
//        ){
//            refreshWindowSize(type:.hide)
//        }
    }
    
    func refreshWindowSize(type:WindowType,isAnimated:Bool = true, Enforcement:Bool = false){
        if(type == windowType.type && !Enforcement){return}
        let animateTime:CGFloat = 0.5
        isInAnimation = true
        let size = getWindowSize(type)
        let radius = getWindowRadius(type)
        if(!hasNotch && windowType.type == .hide){windowWidth=1;windowHeight=1}
        withAnimation(.spring(response: isAnimated ? animateTime : 0, dampingFraction: 0.75)){
            if(!hasNotch && type == .hide){windowWidth=1}
            else{windowWidth = size.width}
            windowHeight = size.height
            windowUpRadius = radius.up
            windowDownRadius = radius.down
            windowPosY = windowHeight/2+windowUpRadius/2
        }
        if(type == .hide){
            windowType.type = type
            DispatchQueue.main.asyncAfter(deadline: .now() + animateTime+0.01) {
                appDelegate.update(type: type)
                windowPosX = size.width/2
                isInAnimation = false
                windowWidth = size.width
            }
        }else{
            if(defaultWindowType == .hide && type != .onCharge){lastWindowType = type}
            appDelegate.update(type: type)
            windowPosX = size.width/2
            withAnimation{
                windowType.type = type
            }
            isInAnimation = false
        }
    }
    
    func onHoverEvent(_ hovering:Bool? = nil){
        let h = hovering ?? hoverState.isHovering
        isHovering = h
        mouseLocation = NSEvent.mouseLocation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if isHovering == h && mouseLocation != NSEvent.mouseLocation {
                var type:WindowType = windowType.type
                if(type != .Drop){
                    type = h ? lastWindowType : .hide
                }else if(!h){
                    type = .hide
                }
                refreshResize()
                refreshWindowSize(type: type)
                
            }
        }
    }
    
    func onDraggerEvent(_ hovering:Bool? = nil){
        let h = hovering ?? hoverState.isDragger
        isHovering = h
        mouseLocation = NSEvent.mouseLocation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if isHovering == h && mouseLocation != NSEvent.mouseLocation {
                let type:WindowType = h ? .Drop : .hide
                refreshWindowSize(type:type)
                refreshResize()
            }
        }
    }
    
    func startIdleKeepAlive() {
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in
            dummyState.toggle() // 這樣 SwiftUI 會 refresh 並避免 App Nap
        }
    }
    
}


struct TopRounded: Shape {
    var Radius: (down:CGFloat, up:CGFloat) = (11*Resize,6*Resize)
    let up = EdgeToTop
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY+up))
        
        path.addQuadCurve(to: CGPoint(x: rect.maxX - Radius.up, y: rect.minY+Radius.up+up),control: CGPoint(x: rect.maxX - Radius.up, y: rect.minY+up))
        
        path.addLine(to: CGPoint(x: rect.maxX - Radius.up, y: rect.maxY-Radius.down))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - Radius.up-Radius.down, y: rect.maxY),
                          control: CGPoint(x: rect.maxX-Radius.up, y: rect.maxY))
        
        path.addLine(to: CGPoint(x: rect.minX+Radius.up+Radius.down, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + Radius.up, y: rect.maxY-Radius.down),
                          control: CGPoint(x: rect.minX+Radius.up, y: rect.maxY))
        
        path.addLine(to: CGPoint(x: rect.minX + Radius.up, y: rect.minY+Radius.up))
        
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY+up),
                          control: CGPoint(x: rect.minX+Radius.up, y: rect.minY+up))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        path.closeSubpath()
        return path
    }
}

extension TopRounded: Animatable {
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(Radius.down, Radius.up) }
        set { Radius.down = newValue.first; Radius.up = newValue.second }
    }
}


//#Preview {
//    VStack{
//        MenuView()
//        Spacer()
//        HStack(spacing:0){
//            AirDropArea()
//                .background(.blue)//.padding(.leading)
//            DroppableIslandView()
//                .background(.blue)//.padding(.trailing)
//        }
//    }.padding(.vertical,5)
//}

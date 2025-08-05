//
//  IslandView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//

import SwiftUI
import AppKit

struct IslandView: View {
    @ObservedObject var island = islandTypeManager
    @State private var dummyState = false
    @State private var isHovering = false
    @State private var isPlayingGame: Bool = false
    @State private var mouseLocation = NSEvent.mouseLocation
    @ObservedObject var hoverState: HoverState = HoverState()
    var appDelegate: AppDelegate// = //AppDelegate()
    @State private var windowWidth: CGFloat = 0
    @State private var windowHeight: CGFloat = 0
    @State private var windowUpRadius: CGFloat = 0
    @State private var windowDownRadius: CGFloat = 0
    
    @State private var windowPosX: CGFloat = 0
    @State private var windowPosY: CGFloat = 0

    @State private var mousePosition: CGPoint = CGPoint()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: windowDownRadius)
                    .fill(Color.black.opacity(island.checkNowIslandTypeIs(.hide) ? 0.3 : 0.7))
                    .blur(radius: windowUpRadius/2) // 模糊模擬陰影散射
                    .frame(width: windowWidth-windowUpRadius*2, height: windowHeight+windowUpRadius)
                    .offset(y:-windowUpRadius/2)
                //.padding(getWindowRadius(windowType.type).up)
                
                HStack {
                    HStack{
                        switch island.getNowIslandType() {
                        case .hide:
                            EmptyView()
                        case .exten:
                            VStack{
                                MenuView(appDelegate: appDelegate).id(island.type)
                                Spacer()
                                HStack{
                                    MusicView()
                                    VStack{
                                        Spacer()
                                        CopyBookScroller()
                                        //                                            .background(.blue)
                                    }
                                    ClockView()
                                }
                            }.padding(.vertical,5)
                        case .onCharge:
                            VStack{
                                InputAnimation()
                                Spacer(minLength: 0)
                            }.padding(.leading,10)
                            Spacer()
                            VStack{
                                BatteryView()
                                Spacer(minLength: 0)
                            }
                        case .gameMode:
                            VStack{
                                HStack(spacing:0){
                                    GameModeHardwareInfoView()
                                    BatteryView()
//                                        .background(.green)
                                }
                                Spacer(minLength: 0)
                            }
                        case .Drop:
                            VStack{
                                MenuView(appDelegate: appDelegate)
                                Spacer()
                                HStack(spacing:0){
                                    AirDropArea().padding(.leading)
                                    DroppableIslandView().padding(.trailing)
                                }
                            }.padding(.vertical,5)
                        case .Clock:
                            VStack{
                                MenuView(appDelegate: appDelegate)
                                Spacer()
                                HStack{
                                    ClockView()
                                    Spacer()
                                    Alarm()
                                    Spacer()
                                    //                                    BackTimer()
                                    Spacer()
                                    //                                    stopwatch()
                                }.padding(.horizontal)
                            }.padding(.vertical,5)
                        case .Hardware:
                            VStack{
                                MenuView(appDelegate: appDelegate)
                                HardwareInfoView()
                                    .frame(maxHeight: .infinity)
                            }
                            .padding(.vertical,5)
                        case .RemoteControl:
                            RemoteControlHint()
                        default:
                            EmptyView()
                            
                        }
                        
                    }.id(island.type)
                }
                .padding(.horizontal, windowUpRadius)
                .frame(width: windowWidth, height: windowHeight+IslandTypeManager.EdgeToTop)
                .background(.black)
                .clipShape(TopRounded(Radius: (down:windowDownRadius, up:windowUpRadius)))
                //            .animation(nil, value: windowType.type)
                .onAppear(){
//                    print(defaultWindowPos)
                    island.refreshIsland()
                    startIdleKeepAlive()
                    MonitorIsPlayingGame()
                }
                .onChange(of: hoverState.isDragger) {
                    getMousePosition()
                    if hoverState.isDragger{
                        onDraggerEvent(hoverState.isDragger)
                    }
                }
                .onChange(of: island.outsideChange) {_,newValue in
                    if(newValue != nil){
                        refreshWindowSize()
                    }
                }
                .onHover { hovering in
                    if(hoverState.isDragger){return}
                    if(island.isLock && !hovering){return}
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
                    return fileStorage.handleDrop(providers: providers, airDropViewSpace: AirDropViewSpace)
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
    }
    
    func refreshWindowSize(isAnimated:Bool = true){//type:WindowType,isAnimated:Bool = true, Enforcement:Bool = false){
        if(!island.ShouldRefreshIsland()){island.resetOutsideChange();return}
        var type = island.outsideChange ?? .hide
        if type == .hide && isPlayingGame{type = .gameMode}
        let hasnotch = IslandTypeManager.hasNotch
        island.setIslandViewChangeState(isChanging: true)
        let LastTypeSize = islandTypeManager.getNowWindowSize()
        let NewTypeSize = IslandTypeManager.getWindowSize(type)
        let NewTypeRadius = IslandTypeManager.getWindowRadius(type)
        if(!hasnotch && island.checkNowIslandTypeIs(.hide)){windowWidth=1;windowHeight=1}
        let isToSmall = IslandTypeManager.isIslandTypeToSmall(from: island.getNowIslandType(), to: type)
        let isToBig = IslandTypeManager.isIslandTypeToBig(from: island.getNowIslandType(), to: type)
        let animateTime:CGFloat = isAnimated ? 0.5 : 0 
        withAnimation(.spring(response: animateTime, dampingFraction: isToBig ? 0.5 : 0.75)){
            if(!hasnotch && type == .hide){windowWidth=NewTypeSize.width}
            else{windowWidth = NewTypeSize.width}
            windowHeight = NewTypeSize.height
            windowUpRadius = NewTypeRadius.up
            windowDownRadius = NewTypeRadius.down
            windowPosY = windowHeight/2+windowUpRadius/2
        }
        var size = CGSize(width: max(LastTypeSize.width,NewTypeSize.width), height: max(LastTypeSize.height,NewTypeSize.height))
        size.height *= 1.5
        size.width *= 1.5
        appDelegate.update(size: size)
        windowPosX = size.width/2
        if(isToSmall || isToBig){
            island.changeIslandType(.hide)
        }
        withAnimation(.easeInOut(duration: animateTime)){
            island.changeIslandType(type)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animateTime*(isToBig ? 1.5 : 1)) {
            appDelegate.update(type: type)
            windowPosX = NewTypeSize.width/2
            windowWidth = NewTypeSize.width
            island.changelastIslandType(type)
            island.resetOutsideChange()
            DispatchQueue.main.async{
                island.setIslandViewChangeState(isChanging: false)
            }
        }
    }
    
    func onHoverEvent(_ hovering:Bool? = nil){
        let h = hovering ?? hoverState.isHovering
        isHovering = h
        mouseLocation = NSEvent.mouseLocation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if isHovering == h && mouseLocation != NSEvent.mouseLocation {
                var type = island.getNowIslandType()
                if(type != .Drop){
                    type = h ? island.lastWindowType : .hide
                }else if(!h){
                    type = .hide
                }
                island.OutsideChangeIslandType(to: type)
            }
        }
    }
    
    func onDraggerEvent(_ hovering:Bool? = nil){
        let h = hovering ?? hoverState.isDragger
        isHovering = h
        mouseLocation = NSEvent.mouseLocation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if isHovering == h && mouseLocation != NSEvent.mouseLocation {
                island.OutsideChangeIslandType(to: h ? .Drop : .hide)
            }
        }
    }
    
    func startIdleKeepAlive() {
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in
            dummyState.toggle() // 這樣 SwiftUI 會 refresh 並避免 App Nap
        }
    }
    
    func MonitorIsPlayingGame(){
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            isPlayingGame = isLikelyGameApp()
            if(!isPlayingGame && island.checkNowIslandTypeIs(.gameMode)){
                island.OutsideChangeIslandType(to: .hide,EnforceChange: true)
            }
            if(island.checkNowIslandTypeIs(.hide) && isPlayingGame){
                island.OutsideChangeIslandType(to: .gameMode,EnforceChange: true)
            }
        }
    }
    
}


struct TopRounded: Shape {
    var Radius: (down:CGFloat, up:CGFloat) = (11,6)
    let up = IslandTypeManager.EdgeToTop
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

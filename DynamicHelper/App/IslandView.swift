//
//  IslandView.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/4/13.
//

import SwiftUI
import AppKit

struct IslandView: View {
    @ObservedObject var island = IslandTypeManager.shared
    @State private var dummyState = false
    @State private var isPlayingGame: Bool = false
    @State private var isPlayingMusic: Bool = false
    @ObservedObject var hoverState: HoverState
    var appDelegate: AppDelegate
    @State private var windowWidth: CGFloat = 0
    @State private var windowHeight: CGFloat = 0
    @State private var windowUpRadius: CGFloat = 0
    @State private var windowDownRadius: CGFloat = 0
    
    @State private var windowPosX: CGFloat = 0
    @State private var windowPosY: CGFloat = 0

    @State private var mousePosition: CGPoint = CGPoint()
    
    @State private var MonitorTimer: Timer? = nil
    

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: windowDownRadius)
                    .fill(Color.black.opacity(island.checkNowIslandTypeIs(.hide) ? 0.3 : 0.7))
                    .blur(radius: windowUpRadius/2) // 模糊模擬陰影散射
                    .frame(width: windowWidth-windowUpRadius*2, height: windowHeight+windowUpRadius)
                    .offset(y:-windowUpRadius/2)
                
                HStack {
                    HStack{
                        switch island.getNowIslandType() {
                        case .hide:
                            EmptyView()
                        case .onLogin:
                            LoginAnimation()
                        case .onMusicPlaying,.onMusicChanging:
                            MusicPlaying()
                        case .exten:
                            VStack{
                                MenuView(appDelegate: appDelegate).id(island.NowType)
                                HStack{
                                    MusicView()
                                    VStack{
#if DEBUG
                                        Spacer()
                                        Text("In Debug mode\nLaunch by Xcode")
                                            .foregroundStyle(.white)
#endif
                                        Spacer()
                                        CopyBookScroller()
                                    }
                                    ClockView()
                                }.frame(maxHeight:.infinity)
                            }.padding(.vertical,5)
                        case .Music:
                            VStack{
                                MenuView(appDelegate: appDelegate).id(island.NowType)
                                MusicView()
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
                                }
                                Spacer(minLength: 0)
                            }
                        case .Drop:
                            VStack{
                                MenuView(appDelegate: appDelegate)
                                HStack(spacing:0){
                                    AirDropArea().padding(.leading)
                                    DroppableIslandView().padding(.trailing)
                                }.frame(maxHeight:.infinity)
                            }.padding(.vertical,5)
                        case .Clock:
                            VStack{
                                MenuView(appDelegate: appDelegate)
                                HStack{
                                    ClockView()
                                    Spacer()
                                }.padding(.horizontal).frame(maxHeight:.infinity)
                            }.padding(.vertical,5)
                        case .Hardware:
                            VStack(spacing:0){
                                MenuView(appDelegate: appDelegate)
                                HardWareDetailView().frame(maxHeight:.infinity)
                            }.padding(.vertical,5)
                            .frame(maxHeight: .infinity, alignment: .top)

                        case .RemoteControl:
                            RemoteControlHint()
                        default:
                            EmptyView()
                            
                        }
                        
                    }.id(island.NowType)
                }
                .padding(.horizontal, windowUpRadius)
                .frame(width: windowWidth, height: windowHeight+IslandTypeManager.EdgeToTop)
                .background(.black)
                .clipShape(TopRounded(Radius: (down:windowDownRadius, up:windowUpRadius)))
                .onAppear(){
                    island.refreshIsland()
                    startIdleKeepAlive()
                    StartMonitorTimer()
                }
                .onChange(of: hoverState.isDragger) {
                    getMousePosition()
                    if hoverState.isDragger{
                        onDraggerEvent(hoverState.isDragger)
                    }
                }
                .onChange(of: island.outsideChange) {_,newValue in
                    DispatchQueue.main.async{
                        if(newValue != nil){
                            refreshWindowSize(isAnimated:island.ousideChangeWithAnimate)
                        }
                    }
                }
                .onHover { hovering in
                    if(hoverState.isDragger){return}
                    if(island.isLock && !hovering){return}
                    onHoverEvent(hovering)
                    hoverState.isHovering = hovering
                }
                .onDrop(of: [.item], isTargeted: $hoverState.isDragger) { providers in
                    // 實際 drop 時會觸發這裡
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
                    {
                        withAnimation(.easeInOut(duration: 0.3)){
                            ViewSpace.AirDrop.isHovering = false
                            ViewSpace.FileDrop.isHovering = false
                        }
                    }
                    return fileStorage.handleDrop(providers: providers, airDropViewSpace: ViewSpace.AirDrop)
                }
            }
            .position(x: windowPosX,y: windowPosY)
        }
    }
    
    func getMousePosition(){
        mousePosition = getMousePoint()
        ViewSpace.AirDrop.checkHovering(mousePosition)
        ViewSpace.FileDrop.checkHovering(mousePosition)
        if(hoverState.isDragger){
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)
            {
                getMousePosition()
            }
        }
    }
    
    func refreshWindowSize(isAnimated:Bool = true){
        if(!island.ShouldRefreshIsland()){island.resetOutsideChange();return}
        island.setIslandViewChangeState(isChanging: true)
        var type = island.outsideChange ?? .hide
        if type == .hide && isPlayingGame{type = .gameMode}
        if type == .hide && isPlayingMusic{type = .onMusicPlaying}
        let hasnotch = IslandTypeManager.hasNotch
        let LastTypeSize = IslandTypeManager.shared.getNowWindowSize()
        let NewTypeSize = IslandTypeManager.getWindowSize(type)
        let NewTypeRadius = IslandTypeManager.getWindowRadius(type)
        if(!hasnotch && island.checkNowIslandTypeIs(.hide)){windowWidth=190;windowHeight=1}
        let isToSmall = IslandTypeManager.isIslandTypeToSmall(from: island.getNowIslandType(), to: type)
        let isToBig = IslandTypeManager.isIslandTypeToBig(from: island.getNowIslandType(), to: type)
        let animateTime:CGFloat = isAnimated ? 0.5 : 0 
        
        withAnimation(.spring(response: animateTime, dampingFraction: isToBig ? 0.5 : 0.75)){
            if(!hasnotch && type == .hide){windowWidth=10}
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
        island.changelastIslandType(type)
        island.resetOutsideChange()
        DispatchQueue.main.asyncAfter(deadline: .now() + animateTime*(isToBig ? 1.5 : 1)) {
            let type = island.getNowIslandType()
            let NewTypeSize = IslandTypeManager.getWindowSize(type)
            appDelegate.update(type: type)
            windowPosX = NewTypeSize.width/2
            windowWidth = NewTypeSize.width
            
            island.setIslandViewChangeState(isChanging: false)
            
        }
    }
    
    func onHoverEvent(_ hovering:Bool? = nil){
        let WindowRect = NSRect(
            origin: NSPoint(x: -1,y: -1),
            size: CGSize(width: windowWidth, height: windowHeight+1)
        )        
        let h = WindowRect.contains(getMousePoint())
        var type = island.getNowIslandType()
        if(type != .Drop){
            type = h ? island.lastWindowType : .hide
        }else if(!h){
            type = .hide
        }
        island.OutsideChangeIslandType(to: type)
    }
    
    func onDraggerEvent(_ hovering:Bool? = nil){
        let WindowRect = NSRect(
            origin: NSPoint(x: -1,y: -1),
            size: CGSize(width: windowWidth, height: windowHeight)
        )        
        let h = WindowRect.contains(getMousePoint())
        island.OutsideChangeIslandType(to: h ? .Drop : .hide)
    }
    
    func startIdleKeepAlive() {
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in
            dummyState.toggle() // 這樣 SwiftUI 會 refresh 並避免 App Nap
        }
    }
    
    
    func StartMonitorTimer(){
        MonitorTimer?.invalidate()
        MonitorTimer = nil
        MonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if island.isTypeChanging {return}
            MonitorIsPlayingGame()
            MonitorIsMusicPlaying()
        }
    }
    
    
    
    func MonitorIsPlayingGame(){
        isPlayingGame = isLikelyGameApp()
        if(!isPlayingGame && island.checkNowIslandTypeIs(.gameMode)){
            island.OutsideChangeIslandType(to: .hide,EnforceChange: true)
        }
        if(island.getNowIslandType().level < IslandTypeManager.IslandType.gameMode.level && isPlayingGame){
            island.OutsideChangeIslandType(to: .gameMode,EnforceChange: true)
        }
    }
    
    func MonitorIsMusicPlaying(){
        isPlayingMusic = (isMusicPlaying() ?? false)
        if isPlayingMusic && island.getNowIslandType().level < IslandTypeManager.IslandType.onMusicPlaying.level{
            island.OutsideChangeIslandType(to: .onMusicPlaying,EnforceChange: true)
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

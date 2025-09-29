//
//  RemoteControl.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/8/5.
//
import SwiftUI

struct RemoteControlHint:View{
    
    let size:CGFloat = 20.0
    
    var body: some View {
        HStack{
            Text("按⌥+⌘+⎋結束").foregroundStyle(.white)
            Spacer()
            Text("遠端遙控中").foregroundStyle(.white)
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.8))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Image(systemName: "desktopcomputer.and.macbook")
                    .font(.system(size: size*0.8))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size*1.2)
            
        }.padding(.horizontal,10)
    }
    
}


struct RemoteControlChooseView:View{
    
    var appDelegate: AppDelegate!
    @State var connectedClients: [Int32 : SocketServer.ClientInfo] = [:]
    @State var timer: Timer? = nil
    @State var chooseComputer: SocketServer.ClientInfo? = nil
    @State var ConnectButtonText: String = "連線"
    
    
    var body: some View {
        VStack{
            ScrollView {
                VStack(spacing: 0) {
                    Divider()
                    ForEach(Array(connectedClients.values), id: \.ip) { client in
                        ComputerButton(ComputerInfo: client, chooseComputer: $chooseComputer)
                        
                        Divider()
                    }
                    Spacer(minLength: 20)
                    Button(action: {
                        RemoteInputInterceptor.shared.ConnectSocket?.stop()
                        StartFoundOtherComputer()
                    }){
                        Text("重新整理")
                    }
                }
                //                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .border(Color.black, width: 1)
            .onTapGesture {
                chooseComputer = nil
            }
            if chooseComputer != nil{
                VStack{
                    Text("是否要遠端遙控:\(chooseComputer?.name ?? "")的電腦")
                        .frame(maxWidth: .infinity,alignment: .leading)
                    Spacer()
                    Button(action: {
                        ConnectButtonText = "連線中"
                        RemoteInputInterceptor.shared.setClientInfo(chooseComputer)
                        let result = RemoteInputInterceptor.shared.startContorl()
                        if result {
                            ConnectButtonText = "連線"
                            appDelegate.closeRemoteControlChooseWindow()
                        }else{
                            ConnectButtonText = "連線失敗"
                        }
                    }){
                        Text(ConnectButtonText)
                    }
                    .onAppear{
                        ConnectButtonText = "連線"
                    }
                }
                .padding(.bottom,5)
            }else{
                Spacer()
            }
        }
        .background(Color.white)
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            RemoteInputInterceptor.shared.ConnectSocket?.stop()
            StartFoundOtherComputer()
        }
    }
    
    func UpdateFoundComputerList() {
        connectedClients = RemoteInputInterceptor.shared.ConnectSocket?.connectedClients ?? [:]
    }
    
    func StartFoundOtherComputer(interval: TimeInterval = RemoteInputInterceptor.DetectionInterval) {
        RemoteInputInterceptor.shared.startFoundOtherComputer()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            UpdateFoundComputerList()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + RemoteInputInterceptor.DetectionTime) {
            timer?.invalidate()
            timer = nil
        }
    }
}


struct ComputerButton:View{
    var ComputerInfo:SocketServer.ClientInfo
    var ImageName:String{
        if ComputerInfo.os.lowercased().contains("mac"){ return "MacOS_logo" }
        else if ComputerInfo.os.lowercased().contains("windows"){ return "Windows_logo" } 
        else if ComputerInfo.os.lowercased().contains("linux"){ return "Linux_logo" }
        else{ return "" }
    }
    
    @Binding var chooseComputer:SocketServer.ClientInfo?
    
    var body: some View {
        HStack{
            Image(ImageName)
                .resizable()
                .frame(width: 40, height: 40)
                .scaledToFit()
            VStack{
                MarqueeText(text: ComputerInfo.name, speed: 20, delay: 0.5,TextColor: .black, font: .system(size: 20), fontWeight: .bold)
                Text(ComputerInfo.ip)
                    .font(.system(size: 12))
            }.frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .padding(.horizontal)
        .background(chooseComputer == ComputerInfo ? .gray.opacity(0.2) : Color.white)
        .onTapGesture {
            chooseComputer = ComputerInfo
        }
    }
}


extension AppDelegate {
    func showRemoteControlChooseWindow() {
        if RemoteControlChooseWindow == nil {
            let size: CGSize = .init(width: 250, height: 400)
            let origin: CGPoint = .init(x: (NSScreen.main?.frame.width ?? 0) / 2 - size.width / 2,
                                        y: (NSScreen.main?.frame.height ?? 0) / 2 - size.height / 2)
            
            let window = NSWindow(
                contentRect: NSRect(origin: origin, size: size),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false)
            
            window.title = "選擇你要連線的電腦"
            window.level = NSWindow.Level(rawValue: 200)//min:102 max:500
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: RemoteControlChooseView(appDelegate: self))
            remoteControlChooseWindowDelegate = RemoteControlChooseWindowDelegate(appDelegate: self)
            window.delegate = remoteControlChooseWindowDelegate
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary,.stationary]
            
            RemoteControlChooseWindow = window
        }
        
        RemoteControlChooseWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isProgrammaticallyClosingRemoteControlWindow = false
    }
    
    func closeRemoteControlChooseWindow(){
        isProgrammaticallyClosingRemoteControlWindow = true
        print(isProgrammaticallyClosingRemoteControlWindow)
        RemoteControlChooseWindow?.close()
    }
    
}

final class RemoteControlChooseWindowDelegate: NSObject, NSWindowDelegate {
    var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func windowWillClose(_ notification: Notification) {
        appDelegate?.RemoteControlChooseWindow = nil
        if !(appDelegate?.isProgrammaticallyClosingRemoteControlWindow ?? false){
            RemoteInputInterceptor.shared.ConnectSocket?.stop()
        }
    }
}

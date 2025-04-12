//
//  SoundController.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/24/25.
//

import SwiftUI
import CoreAudio
import Foundation


struct SoundController: View {
    
    @ObservedObject private var volumeManager = VolumeManager
    @State private var backgroundColor: CGFloat = 0.0
    @State private var isPressed = false
    @State var isHovering: Bool = false
    
    var size: CGFloat = defaultMenuItemButtonSize
    let sizeR:CGFloat = defaultMenuItemButtonSizeR
    var volumeListenerQueue = DispatchQueue(label: "VolumeListenerQueue")
    let hoverMaxTime:CGFloat = 1
    let BigSize:CGFloat = 3.9
    @State var BigType:Bool = false
    @State var timer:Timer?
    @State var volume:Double = Double(getSystemVolume() ?? 0.5)
    @State var isDragged:Bool = false
    
    var body: some View {
        let pressGesture = DragGesture(minimumDistance: 0)
            .onChanged { _ in
//                if(!VolumeManager.canGetVolume){return}
                isPressed = true
                var mute = !isSystemMuted()! || VolumeManager.volume == 0
                if(!VolumeManager.canGetVolume){mute = !isSystemMuted()!}
//                print(mute)
                setSystemMute(mute)
            }
            .onEnded { _ in
                isPressed = false
            }
        ZStack {
            RoundedRectangle(cornerRadius: defaultMenuItemButtonRadius)
                .fill(Color.gray.opacity(isHovering ? 0.6 : 0.0))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            ZStack{
                HStack{
                    Image(
                        systemName: getVolumeIcon(VolumeManager)
                    )
                    .font(.system(size: size*sizeR))
                    .foregroundStyle(volumeManager.canGetVolume ? .white : .red)
                    .scaleEffect(isPressed ? 1.0 : defaultMenuItemButtonResizeMagin)
                    .gesture(pressGesture)
                    .offset(x: 0)
                    .help(VolumeManager.canGetVolume ? "" : "無法取得聲音資訊")
                }
                .padding(.horizontal,4)
                .frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .leading)
                if(BigType){
                    HStack{
                        SliderBar(progress: $volume, isDragging: $isDragged)
                            .onChange(of: volume) { oldValue,newValue in
                                if(!VolumeManager.isMuted || newValue != 0) {setSystemVolume(Float(newValue))}
                                setSystemMute(newValue == 0)
                            }.onChange(of: VolumeManager.isMuted) { oldValue,newValue in
                                volume = VolumeManager.isMuted ? 0.0 : Double(VolumeManager.volume)
                            }.onChange(of: VolumeManager.volume) { oldValue,newValue in
                                if(!isDragged){
                                    volume = Double(VolumeManager.volume)
                                }
                            }
                    }
                    .padding(.leading,size*sizeR)
                }
            }
            
        }.onHover { entered in
            entered ? self.startTimer() : self.stopTimer()
            withAnimation(.easeInOut(duration: 0.2)){
                BigType = entered ? BigType : false
                isHovering = entered
            }
        }
        .scaleEffect(x: isHovering ? defaultMenuItemButtonResizeMagin : 1.0 , y:isHovering ? defaultMenuItemButtonResizeMagin : 1.0)
        .frame(width: BigType ? size*BigSize : size, height: size)
        .offset(x: BigType ? size*(defaultMenuItemButtonResizeMagin-1)*(BigSize-1) : 0)
        .contextMenu {
            setOutputDeviceView()
        }
        .onChange(of: VolumeManager.canGetVolume) { oldValue,newValue in
            volume = Double(VolumeManager.volume)
        }
    }
    
    
    func getVolumeIcon(_ VLM:VolumeListenerManager)->String{
        let IconArray:[String] = ["volume.1.fill","volume.2.fill","volume.3.fill","volume.3.fill"]
        if(!VLM.canGetVolume){return VLM.isMuted ? "speaker.badge.exclamationmark" : "speaker.badge.exclamationmark.fill"}
        if(VLM.isMuted){return "volume.slash.fill"}
        if(VLM.volume < 0.05){return "volume.fill"}
        return IconArray[Int(VLM.volume*3)]
    }
    
    
    func getXExten(_ BigType:Bool, _ isHovering:Bool)->CGFloat{
        if(BigType){
            return (defaultMenuItemButtonResizeMagin-1)/BigSize+1
        }else if(isHovering){
            return defaultMenuItemButtonResizeMagin
        }else{
            return 1
        }
        
    }
    
    func startTimer() {
        if(!volumeManager.canGetVolume){return}
        self.timer = Timer.scheduledTimer(withTimeInterval: hoverMaxTime, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.2)){
                BigType = true
            }
        }
    }
    
    func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
}



struct setOutputDeviceView: View {
    @State var COD = getCurrentOutputDeviceID()
    var body: some View {
        Text("設定輸出裝置")
        ForEach (getOutputDevice(), id:\.ID){device in
            Button(action: {
                setOutputDevice(device.ID)
                COD = getCurrentOutputDeviceID()
            }) {
                Text(device.name)
                if device.ID == COD {
                    Image(systemName: "checkmark")
                }
            }
            .onAppear {
                COD = getCurrentOutputDeviceID()
            }
        }
    }
    
    func getOutputDevice() -> [(ID:UInt32,name:String)] {
        var result: [(ID: UInt32, name: String)] = []
        if let devices = getAllAbleOutputDevice() {
            for id in devices.keys {
                if devices[id]?.type == .input{continue}
                if devices[id]?.type == .unkown{continue}
                result.append((ID: id, name: devices[id]?.name) as! (ID: UInt32,name: String))
            }
        }
        return result
    }
}

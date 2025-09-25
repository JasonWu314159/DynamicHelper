//
//  MusicPlaying.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/25.
//

import SwiftUI

struct MusicPlaying:View{
    @State var artwork: NSImage? = MusicInfo.artwork
    @State private var isPlay:Bool = MusicInfo.isPlay
    @State private var isVisible = false
    @State private var firstTime:Bool = true
    @State private var NoPlayingTime:Int = 0
    
    var body: some View {
        HStack{
            Group {
                if let image = artwork {
                    Image(nsImage: image).resizable()
                } else {
                    Image("MusicDefault").resizable()
                }
            }
            .frame(width: 25, height: 25)
            .padding(5)
            .scaledToFit()
            .cornerRadius(10)
            .onAppear{
                isVisible = true
                updateMusicInfo()
            }
            .onDisappear{
                isVisible = false
            }
            Spacer()
            AudioSpectrumView(isPlaying: $isPlay)
                .frame(width: 25, height: 25)
                .padding(.bottom,10)
            
        }.frame(maxWidth: .infinity,maxHeight: .infinity)
    }
    
    func updateMusicInfo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !isVisible {return}
            DispatchQueue.global().async {
                let playing = isMusicPlaying()  // AppleScript
                DispatchQueue.main.async {
                    self.isPlay = playing ?? false
                }
            }
            if !isPlay{
                NoPlayingTime += 1;
                if NoPlayingTime > 4 { islandTypeManager.OutsideChangeIslandType(to: .hide) ;return }
            }else{
                NoPlayingTime = 0
            }
            if let img = loadMusicArtworkImage() {
                artwork = img
            }
            updateMusicInfo()
        }
    }
}



//
//  FileDropper.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 4/23/25.
//

import SwiftUI
import AppKit

struct DroppableIslandView: View {
    @ObservedObject var storedFiles:FileStorage = fileStorage
    @ObservedObject var fileDropViewSpace = FileDropViewSpace
    var width:CGFloat = 360
    var height:CGFloat = 100
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack() {
                FileContainerView(storedFiles:storedFiles)
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        Color(red: 0.5, green: 0.5, blue: 0.5),
                        lineWidth: FileDropViewSpace.isHovering ? 10 : 5
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if(storedFiles.Files.isEmpty ){
                    Text("將檔案拖曳到這裡").foregroundColor(.gray)
                }
            }
            .padding()
            .cornerRadius(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                FileDropViewSpace.isHovering = false
            }
            .onChange(of: geo.frame(in: .global)) { 
                FileDropViewSpace.frame = geo.frame(in: .global)
            }
        }
    }

    
}


struct FileContainerView: View {
    @ObservedObject var storedFiles:FileStorage
    var body: some View {
        if !storedFiles.Files.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(storedFiles.Files) { file in
                        FileInfoView(file: file, storedFiles: storedFiles)
                            
                    }
                }
                .padding()
            }
            .frame(maxHeight: .infinity)
            .scrollIndicators(.hidden)
            .clipped()
        }
    }
}


struct FileInfoView: View  {
    let file:FileEntry
    @ObservedObject var storedFiles:FileStorage
    @State private var isHovered: Bool = false
    var body: some View {
        ZStack{
            if(isHovered){
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            VStack {
                Image(nsImage: file.icon)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
                MarqueeText(text: file.url.lastPathComponent, speed: 0.05, delay: 0.5,font: .system(size: 13))
                    .padding(.vertical,0)
            }
            .padding(.horizontal,6)
            .onDrag {
                let f = file
                let provider = NSItemProvider(contentsOf: f.url)
//                let provider = createUnifiedItemProvider(for:f.url)
                provider?.suggestedName = f.url.deletingPathExtension().lastPathComponent
//                provider.suggestedName = f.url.deletingPathExtension().lastPathComponent
                if(NSEvent.modifierFlags.contains(.command)){
                    storedFiles.Files.removeAll { $0 == file }
                }
                return provider!
            }
            .onTapGesture {
                if NSEvent.modifierFlags.contains(.command) {
                    NSWorkspace.shared.open(file.url)
                }
                else if NSEvent.modifierFlags.contains(.option) {
                    NSWorkspace.shared.activateFileViewerSelecting([file.url])
                }else if NSEvent.modifierFlags.contains(.shift) {
                    
                }
            }
            
            if(isHovered){
                HStack{
                    Spacer()
                    VStack{
                        ZStack{
                            Circle()
                                .fill(Color.black) // 填滿藍色
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                            Image(systemName: "x.circle.fill")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundStyle(.gray)
                                .onTapGesture {
                                    storedFiles.Files.removeAll { $0 == file }
                                }
                        }.frame(width: 16, height: 16)
                            .offset(x:8, y:-8)
                        Spacer()
                    }
                }
            }
        }
        .contextMenu {
            Button("打開") {
                NSWorkspace.shared.open(file.url)
            }
            Divider()
            Button("顯示於Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([file.url])
            }
            Divider()
            Button("移除") {
                storedFiles.Files.removeAll { $0 == file }
            }
        }
        .onHover{ hovering in
            isHovered = hovering
        }
    }
}

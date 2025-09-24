//
//  CopyBookSetting.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/24.
//


import SwiftUI


struct CopyBookSetting: View {
    @State private var shouldSaveCopyBook_: Bool = false
    var body: some View {
        VStack{
            HStack{
                Text("結束是否儲存剪貼簿")
                Spacer()
                Picker("", selection: $shouldSaveCopyBook_) {
                    Text("是").tag(true)
                    Text("否").tag(false)
                }.onAppear {
                    saveSettings()
                    shouldSaveCopyBook_ = shouldSaveCopyBook
                }
                .onChange(of: shouldSaveCopyBook_) { _ ,newValue in
                    shouldSaveCopyBook = newValue
                    saveSettings()
                }
                .frame(width: 100)
            }
            
            HStack{
                Text("清除剪貼簿")
                Spacer()
                Button(action: {
                    StringStorage.shared.Item = []
                    saveSettings()
                }) {
                    Text("清除")
                }
            }
            Spacer()
        }
        .navigationTitle("剪貼簿設定")
    }
}

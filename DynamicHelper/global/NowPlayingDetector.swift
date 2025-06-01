////
////  NowPlayingDetector.swift
////  DynamicHelper
////
////  Created by 吳佳昇 on 2025/5/19.
////
//
//import Foundation
//
//class NowPlayingDetector {
//    static let shared = NowPlayingDetector()
//
//    private init() {
//        // 啟動偵測
//        startListening()
//    }
//
//    func startListening() {
//        let queue = DispatchQueue.main
//        MRMediaRemoteRegisterForNowPlayingNotifications(queue)
//
//        // 監聽播放狀態變更
//        NotificationCenter.default.addObserver(
//            forName: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
//            object: nil,
//            queue: .main
//        ) { _ in
//            self.fetchNowPlayingInfo()
//        }
//
//        fetchNowPlayingInfo()
//    }
//
//    func fetchNowPlayingInfo() {
//        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { info in
//            guard let info = info as? [String: Any] else {
//                print("無播放資訊")
//                return
//            }
//
//            if let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String,
//               let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String {
//                print("正在播放：\(title) - \(artist)")
//            } else {
//                print("正在播放未知內容")
//            }
//        }
//    }
//}

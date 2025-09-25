//
//  MusicAudioCapture.swift
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/9/25.
//

import AppKit
import SwiftUI

final class AudioSpectrum: NSView {
    private var barLayers: [CAShapeLayer] = []
    private var animationTimer: Timer?
    private let barWidth: CGFloat = 2
    private let barCount: Int = 4
    private let spacing: CGFloat = 2
    private let totalHeight: CGFloat = 14
    private let minScale: CGFloat = 0.35

    private(set) var isAnimating = false

    // MARK: - Init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupBars()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupBars()
    }

    deinit {
        stopAnimating()
        barLayers.removeAll()
    }

    // MARK: - Lifecycle hooks
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if newWindow == nil {
            stopAnimating()
        }
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview == nil {
            stopAnimating()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // 進入視窗後才允許啟動
        if window != nil, isAnimating {
            startAnimating()
        }
    }

    // MARK: - Public API
    func setPlaying(_ playing: Bool) {
        if playing {
            if !isAnimating {
                isAnimating = true
                if window != nil { startAnimating() }
            }
        } else {
            isAnimating = false
            stopAnimating()
        }
    }

    // MARK: - Setup
    private func setupBars() {
        guard let container = layer else { return }

        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(max(0, barCount - 1)) * spacing
        setFrameSize(.init(width: totalWidth, height: totalHeight))

        barLayers.forEach { $0.removeFromSuperlayer() }
        barLayers.removeAll()

        for i in 0..<barCount {
            let x = CGFloat(i) * (barWidth + spacing)
            let bar = CAShapeLayer()
            bar.frame = CGRect(x: x, y: 0, width: barWidth, height: totalHeight)
            bar.anchorPoint = CGPoint(x: 0.5, y: 0.0)   // 由底部向上縮放
            bar.position = CGPoint(x: x + barWidth/2, y: 0)
            bar.fillColor = NSColor.white.cgColor
            bar.transform = CATransform3DMakeScale(1, minScale, 1)

            let path = CGPath(roundedRect: CGRect(x: 0, y: 0, width: barWidth, height: totalHeight),
                              cornerWidth: barWidth/2, cornerHeight: barWidth/2, transform: nil)
            bar.path = path

            container.addSublayer(bar)
            barLayers.append(bar)
        }
    }

    // MARK: - Animation control
    private func startAnimating() {
        guard animationTimer == nil, window != nil else { return }
        // 用 Common 模式，避免在追蹤/轉場時暫停（造成卡頓）
        let timer = Timer(timeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.updateBars()
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
        // 立即更新一次，避免首幀停在 minScale
        updateBars()
    }

    private func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
        removeAllBarAnimations()
        resetBars()
    }

    private func removeAllBarAnimations() {
        barLayers.forEach { $0.removeAllAnimations() }
    }

    private func resetBars() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        barLayers.forEach { $0.transform = CATransform3DMakeScale(1, minScale, 1) }
        CATransaction.commit()
    }

    // MARK: - Tick
    private func updateBars() {
        guard window != nil, let _ = layer else { return }

        for (idx, bar) in barLayers.enumerated() {
            // 讀取當前呈現值，如讀不到則使用 minScale
            let current = (bar.presentation()?.value(forKeyPath: "transform.scale.y") as? CGFloat) ?? minScale
            let target = CGFloat.random(in: minScale ... 1.0)

            let anim = CABasicAnimation(keyPath: "transform.scale.y")
            anim.fromValue = current
            anim.toValue = target
            anim.duration = 0.3
            anim.autoreverses = true
            anim.fillMode = .forwards
            anim.isRemovedOnCompletion = false
            if #available(macOS 13.0, *) {
                anim.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
            }
            // 為每根 bar 使用固定 key，避免動畫堆積
            bar.add(anim, forKey: "scaleY_\(idx)")
        }
    }
}

// SwiftUI 包裝
struct AudioSpectrumView: NSViewRepresentable {
    @Binding var isPlaying: Bool

    func makeNSView(context: Context) -> AudioSpectrum {
        let v = AudioSpectrum()
        v.setPlaying(isPlaying)
        return v
    }

    func updateNSView(_ nsView: AudioSpectrum, context: Context) {
        nsView.setPlaying(isPlaying)
    }
}
#Preview {
    AudioSpectrumView(isPlaying: .constant(true))
        .frame(width: 16, height: 20)
        .padding()
}

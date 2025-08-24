//
//  SearchBarView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchText: String
    @ObservedObject var speechManager: SpeechRecognitionManager
    @FocusState private var isTextFieldFocused: Bool
    let placeholder: String
    let isSearching: Bool
    let onSearchSubmit: () -> Void
    let onSearchTextChange: (String) -> Void
    
    init(
        searchText: Binding<String>,
        speechManager: SpeechRecognitionManager,
        placeholder: String = "",
        isSearching: Bool = false,
        onSearchSubmit: @escaping () -> Void,
        onSearchTextChange: @escaping (String) -> Void
    ) {
        self._searchText = searchText
        self.speechManager = speechManager
        self.placeholder = placeholder
        self.isSearching = isSearching
        self.onSearchSubmit = onSearchSubmit
        self.onSearchTextChange = onSearchTextChange
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 搜尋框
            HStack(spacing: 12) {
                // 放大鏡圖示
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary)
                    .font(.system(size: 18))
                
                // 輸入框
                TextField(placeholder, text: $searchText)
                    .foregroundColor(.primary)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        isTextFieldFocused = false // 提交後失焦
                        onSearchSubmit()
                    }
                    .onChange(of: searchText) { _, newValue in
                        onSearchTextChange(newValue)
                    }
                
                Spacer()
                
                // 語音輸入按鈕
                Button(action: {
                    isTextFieldFocused = false // 點擊語音按鈕時讓輸入框失焦
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        speechManager.toggleRecording()
                    }
                }) {
                    VoiceRecordingButton(isRecording: speechManager.isRecording)
                }
                .disabled(isSearching)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray5))
            .cornerRadius(50)
            
            // 錄音狀態指示器
            if speechManager.isRecording {
                HStack {
                    AnimatedWaveformView()
                    Text("正在聆聽...")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: speechManager.isRecording)
            }
        }
        .padding(.horizontal)
        .onTapGesture {
            // 點擊空白區域時讓輸入框失焦
            if isTextFieldFocused {
                isTextFieldFocused = false
            }
        }
        .onReceive(speechManager.$recognizedText) { text in
            if !text.isEmpty && speechManager.isRecording {
                searchText = text
                // 語音識別過程中即時更新搜尋文字
                onSearchTextChange(text)
            }
        }
        .onAppear {
            // 設置自動停止回調
            speechManager.onAutoStop = {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    speechManager.toggleRecording()
                }
            }
        }
    }
}

// MARK: - Voice Recording Button
struct VoiceRecordingButton: View {
    let isRecording: Bool
    @State private var animationScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // 外圍的脈衝圓環動畫
            if isRecording {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .scaleEffect(animationScale)
                    .opacity(pulseOpacity)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                        value: animationScale
                    )
                
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .scaleEffect(animationScale * 1.3)
                    .opacity(pulseOpacity * 0.7)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                        value: animationScale
                    )
            }
            
            // 麥克風圖示
            Image(systemName: "mic.fill")
                .foregroundColor(isRecording ? .red : .primary)
                .font(.system(size: 18, weight: .medium))
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
        }
        .frame(width: 32, height: 32)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startListeningAnimation()
            } else {
                stopListeningAnimation()
            }
        }
    }
    
    private func startListeningAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            animationScale = 1.4
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.8
        }
    }
    
    private func stopListeningAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            animationScale = 1.0
            pulseOpacity = 0.0
        }
    }
}

// MARK: - Animated Waveform View
struct AnimatedWaveformView: View {
    @State private var waveHeights: [CGFloat] = Array(repeating: 2, count: 5)
    @State private var animationTimer: Timer?
    @State private var isAnimating: Bool = false
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<waveHeights.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.red)
                    .frame(width: 2, height: waveHeights[index])
                    .scaleEffect(isAnimating ? 1.0 : 0.3)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(
                        .easeInOut(duration: 0.3 + Double(index) * 0.1)
                        .delay(Double(index) * 0.05),
                        value: waveHeights[index]
                    )
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                        .delay(Double(index) * 0.05),
                        value: isAnimating
                    )
            }
        }
        .frame(height: 14)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            startWaveAnimation()
        }
        .onDisappear {
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = false
            }
            stopWaveAnimation()
        }
    }
    
    private func startWaveAnimation() {
        // 初始化隨機波形高度
        updateWaveHeights()
        
        // 創建定時器來模擬語音輸入的波形變化
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            updateWaveHeights()
        }
    }
    
    private func stopWaveAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateWaveHeights() {
        guard isAnimating else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            waveHeights = waveHeights.enumerated().map { index, _ in
                // 生成隨機高度，中間的波形通常較高
                let baseHeight: CGFloat = 3
                let maxHeight: CGFloat = 12
                let centerBoost = index == 2 ? 1.5 : 1.0 // 中間的波形較高
                let randomMultiplier = CGFloat.random(in: 0.3...1.0) * centerBoost
                return baseHeight + (maxHeight - baseHeight) * randomMultiplier
            }
        }
    }
}

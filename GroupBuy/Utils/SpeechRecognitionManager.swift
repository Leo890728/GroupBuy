//
//  SpeechRecognitionManager.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/18.
//

import Foundation
import Speech
import AVFoundation
import SwiftUI

@MainActor
class SpeechRecognitionManager: ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var speechAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // 自動停止計時器相關
    private var autoStopTimer: Timer?
    private let autoStopTimeInterval: TimeInterval = 10.0 // 10秒
    private var lastRecognitionTime: Date = Date()
    
    var onRecognitionComplete: ((String) -> Void)?
    var onAutoStop: (() -> Void)?
    
    init() {
        setupSpeechRecognizer()
    }
    
    deinit {
        // 在 deinit 中，需要直接清理資源，不能調用 @MainActor 方法
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 重設音訊會話
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("重設音訊會話失敗: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func requestPermissionIfNeeded() {
        guard speechAuthorizationStatus == .notDetermined else { return }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.speechAuthorizationStatus = status
                print("語音識別權限狀態: \(status.rawValue)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSpeechRecognizer() {
        speechAuthorizationStatus = SFSpeechRecognizer.authorizationStatus()
        
        guard speechRecognizer?.isAvailable == true else {
            print("語音識別不可用")
            return
        }
        
        if speechAuthorizationStatus == .notDetermined {
            requestPermissionIfNeeded()
        }
    }
    
    private func startRecording() {
        guard speechAuthorizationStatus == .authorized else {
            print("語音識別權限未授權")
            if speechAuthorizationStatus == .notDetermined {
                requestPermissionIfNeeded()
            }
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("語音識別器不可用")
            return
        }
        
        stopRecording() // 停止之前的錄音任務
        
        setupAudioSession()
        setupRecognitionRequest()
        setupAudioEngine()
        
        startRecognitionTask()
        
        // 啟動自動停止計時器
        startAutoStopTimer()
        
        isRecording = true
        print("開始語音輸入")
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("音訊會話設定失敗: \(error)")
        }
    }
    
    private func setupRecognitionRequest() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
    }
    
    private func setupAudioEngine() {
        guard let recognitionRequest = recognitionRequest else {
            print("無法建立識別請求")
            return
        }
        
        let inputNode = audioEngine.inputNode
        _ = inputNode.outputFormat(forBus: 0)
        
        // 安裝音訊輸入
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // 啟動音訊引擎
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("音訊引擎成功啟動")
        } catch {
            print("音訊引擎啟動失敗: \(error)")
            retryStartAudioEngine()
        }
    }
    
    private func retryStartAudioEngine() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try audioEngine.start()
            print("重新啟動音訊引擎成功")
        } catch {
            print("重新啟動也失敗: \(error)")
        }
    }
    
    private func startRecognitionTask() {
        guard let speechRecognizer = speechRecognizer,
              let recognitionRequest = recognitionRequest else { return }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result: result, error: error)
            }
        }
    }
    
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            let recognizedText = result.bestTranscription.formattedString
            print("識別結果: \(recognizedText)")
            
            if isRecording {
                self.recognizedText = recognizedText
                
                // 有識別到語音內容時，重置計時器
                if !recognizedText.trimmingCharacters(in: .whitespaces).isEmpty {
                    lastRecognitionTime = Date()
                    resetAutoStopTimer()
                }
                
                if result.isFinal {
                    stopRecording()
                    onRecognitionComplete?(recognizedText)
                }
            }
        } else if let error = error {
            print("語音識別錯誤: \(error)")
            if isRecording {
                stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        print("停止語音輸入")
        
        // 停止自動停止計時器
        stopAutoStopTimer()
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 重設音訊會話
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("重設音訊會話失敗: \(error)")
        }
    }
    
    // MARK: - Auto Stop Timer Methods
    
    private func startAutoStopTimer() {
        lastRecognitionTime = Date()
        autoStopTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAutoStop()
            }
        }
    }
    
    private func stopAutoStopTimer() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
    }
    
    private func resetAutoStopTimer() {
        stopAutoStopTimer()
        startAutoStopTimer()
    }
    
    private func checkAutoStop() {
        let timeSinceLastRecognition = Date().timeIntervalSince(lastRecognitionTime)
        
        if timeSinceLastRecognition >= autoStopTimeInterval && isRecording {
            print("語音輸入自動停止：超過\(autoStopTimeInterval)秒沒有識別到語音")
            // 通知 UI 需要觸發動畫
            onAutoStop?()
        }
    }
}

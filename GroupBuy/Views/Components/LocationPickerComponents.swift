//
//  LocationPickerComponents.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/18.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchText: String
    @ObservedObject var speechManager: SpeechRecognitionManager
    let isSearching: Bool
    let onSearchSubmit: () -> Void
    let onSearchTextChange: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 搜尋框
            HStack(spacing: 12) {
                // 放大鏡圖示
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary)
                    .font(.system(size: 18))
                
                // 輸入框
                TextField("輸入地點", text: $searchText)
                    .foregroundColor(.primary)
                    .onSubmit {
                        print("用戶提交搜尋: '\(searchText)'")
                        onSearchSubmit()
                    }
                    .onChange(of: searchText) { newValue in
                        print("搜尋文字變更: '\(newValue)'")
                        onSearchTextChange(newValue)
                    }
                
                Spacer()
                
                // 語音輸入按鈕
                Button(action: {
                    speechManager.toggleRecording()
                }) {
                    VoiceRecordingButton(isRecording: speechManager.isRecording)
                }
                .disabled(isSearching)
                
                // 搜尋進度指示器
                if isSearching {
                    ProgressView()
                        .tint(.primary)
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGray5))
            .cornerRadius(25)
            
            // 錄音狀態指示器
            if speechManager.isRecording {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                    Text("正在聆聽...")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
        .onReceive(speechManager.$recognizedText) { text in
            print("收到語音識別文字: '\(text)', 是否正在錄音: \(speechManager.isRecording)")
            if !text.isEmpty && speechManager.isRecording {
                searchText = text
                // 語音識別過程中即時更新搜尋文字
                onSearchTextChange(text)
            }
        }

        Divider()
            .background(Color.gray)
            .frame(height: 2)
            .padding(.horizontal, 16)
    }
}

// MARK: - Location Status View
struct LocationStatusView: View {
    let isLocationAuthorized: Bool
    let onRequestPermission: (() -> Void)?
    
    var body: some View {
        if !isLocationAuthorized {
            HStack {
                Image(systemName: "location.slash")
                    .foregroundColor(.orange)
                Text("開啟定位以搜尋附近地點")
                    .font(.caption)
                    .foregroundColor(.orange)
                Spacer()
                
                if let onRequestPermission = onRequestPermission {
                    Button("允許定位") {
                        onRequestPermission()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .onAppear {
                print("LocationStatusView 顯示：權限狀態 = \(isLocationAuthorized)")
            }
        }
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let searchResults: [MKMapItem]
    let searchText: String
    let isSearching: Bool
    @Binding var selectedAddress: String
    @Binding var isPresented: Bool
    let isLocationAuthorized: Bool
    let onLocationRequest: () -> Void
    let onLocationSelect: (MKMapItem) -> Void

    var body: some View {
        let _ = print("SearchResultsView 狀態: searchResults.count=\(searchResults.count), searchText='\(searchText)', isSearching=\(isSearching), isLocationAuthorized=\(isLocationAuthorized)")
        
        // 當輸入為空且沒有搜尋結果時：若有定位權限，顯示包含「附近的店家」按鈕的 List；否則顯示 EmptySearchView
        if searchResults.isEmpty && searchText.isEmpty && !isSearching {
            if isLocationAuthorized {
                List {
                    Section {
                        Button(action: {
                            print("用戶點擊附近店家按鈕 (空搜尋)")
                            onLocationRequest()
                        }) {
                            HStack {
                                Image(systemName: "map")
                                    .foregroundColor(.blue)
                                Text("附近的店家")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                EmptySearchView()
            }
        } else if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
            // 有搜尋文字但沒有結果且不在搜尋中時顯示無結果
            NoResultsView()
        } else if isSearching {
            // 搜尋中顯示載入畫面
            VStack {
                Spacer()
                ProgressView("搜尋中...")
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                Spacer()
            }
        } else {
            // 有搜尋結果時顯示列表
            List {
                // 建議輸入為地址的操作放在同一 List
                if !searchText.isEmpty && searchText != "附近的店家" {
                    Section {
                        Button(action: {
                            selectedAddress = searchText
                            isPresented = false
                        }) {
                            HStack {
                                Text("將 \(searchText) 設為地址")
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 8)
                    }
                }

                // 附近的商家按鈕也在同一 List
                if isLocationAuthorized {
                    Section {
                        Button(action: {
                            print("用戶點擊附近店家按鈕 (有搜尋結果)")
                            onLocationRequest()
                        }) {
                            HStack {
                                Image(systemName: "map")
                                    .foregroundColor(.blue)
                                Text("附近的店家")
                                    .foregroundColor(.primary)
                                Spacer()
                                if isSearching {
                                    ProgressView()
                                        .tint(.blue)
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 8)
                    }
                }

                // 搜尋結果放在名為「地圖地點」的 Section
                if !searchResults.isEmpty {
                    Section(header: Text("地圖地點").font(.headline)) {
                        ForEach(searchResults, id: \.self) { item in
                            LocationRowView(item: item, onSelect: onLocationSelect)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// MARK: - Location Row View
struct LocationRowView: View {
    let item: MKMapItem
    let onSelect: (MKMapItem) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            LocationIconView(category: item.pointOfInterestCategory)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "未知地點")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if let address = item.placemark.title {
                    Text(address)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(item)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Location Icon View
struct LocationIconView: View {
    let category: MKPointOfInterestCategory?
    
    var body: some View {
        Image(systemName: Store.spotlightIcon(for: category))
            .foregroundColor(.white)
            .font(.system(size: 14, weight: .medium))
            .frame(width: 24, height: 24)
            .background(Store.spotlightColor(for: category))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Empty States
struct EmptySearchView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "location.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    Text("輸入地點名稱開始搜尋")
                        .foregroundColor(.primary)
                        .font(.headline)
                    Text("或點擊定位圖示搜尋附近地點")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Text("選擇地點後將自動填入商店資訊")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            
            Spacer()
        }
    }
}

struct NoResultsView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("找不到相關地點")
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Navigation Title View
struct NavigationTitleView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("選擇地點")
                .font(.headline)
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
        .onChange(of: isRecording) { newValue in
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

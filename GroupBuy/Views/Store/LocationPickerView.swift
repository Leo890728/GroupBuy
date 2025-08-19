//
//  LocationPickerView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/18.
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    // MARK: - Bindings
    @Binding var selectedAddress: String
    @Binding var selectedName: String
    @Binding var selectedPhoneNumber: String
    @Binding var selectedCategory: MKPointOfInterestCategory?
    @Binding var isPresented: Bool
    
    // MARK: - Callback
    var onLocationSelected: (() -> Void)?
    
    // MARK: - Managers
    @StateObject private var locationManager = LocationManager()
    @StateObject private var speechManager = SpeechRecognitionManager()
    // 直接觀察搜尋管理器，讓 @Published 更新能觸發 View 重新繪製
    @StateObject private var searchManager = LocationSearchManager(locationManager: LocationManager())
    
    // MARK: - State Properties
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBarView(
                    searchText: $searchText,
                    speechManager: speechManager,
                    placeholder: "輸入地點",
                    isSearching: searchManager.isSearching,
                    onSearchSubmit: {
                        searchManager.searchPlaces()
                        isSearchFieldFocused = false
                    },
                    onSearchTextChange: { newValue in
                        searchText = newValue
                        searchManager.handleSearchTextChange(newValue)
                    }
                )
                .focused($isSearchFieldFocused)
                
                LocationStatusView(
                    isLocationAuthorized: locationManager.isLocationAuthorized,
                    onRequestPermission: {
                        locationManager.requestLocationPermission()
                    }
                )
                
                SearchResultsView(
                    searchResults: searchManager.searchResults,
                    searchText: searchManager.searchText,
                    isSearching: searchManager.isSearching,
                    selectedAddress: $selectedAddress,
                    isPresented: $isPresented,
                    isLocationAuthorized: locationManager.isLocationAuthorized,
                    isSearchFieldFocused: $isSearchFieldFocused,
                    onLocationRequest: {
                        searchManager.searchNearbyPlaces()
                    },
                    onLocationSelect: selectLocation
                )
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItemGroup(placement: .principal) {
                    NavigationTitleView()
                }
            }
            .onAppear {
                print("LocationPickerView onAppear")
                // 將搜尋管理器的 LocationManager 指向同一個實例，避免權限/位置不同步
                searchManager.setLocationManager(locationManager)
                setupSpeechRecognitionCallback()
                
                // 如果已有選定的地址，將其設置到搜索框中
                if !selectedAddress.isEmpty {
                    searchText = selectedAddress
                    searchManager.handleSearchTextChange(selectedAddress)
                }
                
                // 主動檢查並請求位置權限
                if locationManager.authorizationStatus == .notDetermined {
                    print("首次啟動，請求位置權限")
                    locationManager.requestLocationPermission()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // 當 app 重新進入前台時，重新檢查權限狀態
                print("App 重新進入前台，檢查權限狀態")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 稍微延遲一下再檢查，確保系統有時間更新權限狀態
                    locationManager.requestLocationPermission()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSpeechRecognitionCallback() {
        speechManager.onRecognitionComplete = { recognizedText in
            let cleanText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanText.isEmpty {
                print("語音識別完成: '\(cleanText)'，準備搜尋")
                self.searchText = cleanText
                searchManager.handleSearchTextChange(cleanText)
                // 語音識別完成後立即執行搜尋
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    searchManager.searchPlaces()
                }
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        setLocationData(from: item)
        logSelectedLocation()
        onLocationSelected?()
        isPresented = false
    }
    
    private func setLocationData(from item: MKMapItem) {
        // 設定商店名稱
        selectedName = item.name ?? ""
        
        // 設定電話號碼
        selectedPhoneNumber = item.phoneNumber ?? ""
        
        // 設定分類
        selectedCategory = item.pointOfInterestCategory
        
        // 設定地址
        selectedAddress = item.placemark.title ?? ""
    }
    
    private func logSelectedLocation() {
        print("選擇的地點：")
        print("  名稱: \(selectedName)")
        print("  地址: \(selectedAddress)")
        print("  電話: \(selectedPhoneNumber)")
        print("  分類: \(selectedCategory?.rawValue ?? "無")")
    }
}
#Preview {
    LocationPickerView(
        selectedAddress: .constant(""),
        selectedName: .constant(""),
        selectedPhoneNumber: .constant(""),
        selectedCategory: .constant(nil),
        isPresented: .constant(true)
    )
}

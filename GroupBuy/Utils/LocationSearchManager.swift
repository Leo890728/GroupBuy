//
//  LocationSearchManager.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/18.
//

import Foundation
import MapKit
import CoreLocation
import SwiftUI
import Combine

@MainActor
class LocationSearchManager: ObservableObject {
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    @Published var searchText = ""
    
    private var searchTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 500_000_000 // 0.5秒
    
    private var locationManager: LocationManager
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    // 新增方法來更新位置管理器
    func setLocationManager(_ manager: LocationManager) {
        self.locationManager = manager
    }
    
    deinit {
        searchTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    func handleSearchTextChange(_ newValue: String) {
        // 取消上一個等待中的 debounce 任務
        searchTask?.cancel()
        searchText = newValue

        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // 空字串：清空結果並不發起搜尋
            searchResults = []
            return
        }

        print("處理搜尋文字變更（debounce）: '\(trimmed)'")

        // 使用 debounce：延遲一小段時間再觸發搜尋，期間若文字再變更會取消並重啟
        let delay = debounceDelay
        searchTask = Task {
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            await searchPlaces()
        }
    }
    
    func searchPlaces() {
        let trimmedText = searchText.trimmingCharacters(in: .whitespaces)
        print("執行搜尋: '\(trimmedText)'")
        
        guard !trimmedText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true

        let request = createSearchRequest()
        let search = MKLocalSearch(request: request)

        Task { @MainActor in
            do {
                let response = try await search.start()
                self.isSearching = false
                self.handleSearchResponse(response, error: nil)
            } catch {
                self.isSearching = false
                self.handleSearchResponse(nil, error: error)
            }
        }
    }
    
    func searchNearbyPlaces() {
        print("開始附近地點搜尋，權限狀態: \(locationManager.isLocationAuthorized)")
        
        guard locationManager.isLocationAuthorized else {
            print("沒有位置權限，請求權限")
            handleLocationPermissionDenied()
            return
        }
        
        // 先檢查是否有當前位置，如果沒有則主動請求
        if let currentLocation = locationManager.currentLocation {
            print("使用現有位置進行附近搜尋")
            performNearbySearch(from: currentLocation)
        } else {
            print("沒有目前位置，開始定位並等待位置更新")
            locationManager.requestLocation()

            Task { @MainActor in
                if let location = await self.waitForCurrentLocation(timeout: 5.0) {
                    print("收到位置更新，開始附近搜尋")
                    self.performNearbySearch(from: location)
                } else {
                    print("等待目前位置逾時，取消附近搜尋")
                }
            }
        }
    }
    
    func clearResults() {
        searchResults = []
        searchText = ""
    }
    
    // MARK: - Private Methods
    
    private func createSearchRequest() -> MKLocalSearch.Request {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = locationManager.getCurrentRegion()
        
        if let currentLocation = locationManager.currentLocation {
            print("使用目前位置搜尋: \(currentLocation.coordinate), 搜尋詞: \(searchText)")
        } else {
            print("使用預設區域搜尋 (台北101): \(LocationManager.defaultRegion.center), 搜尋詞: \(searchText)")
        }
        
        return request
    }
    
    private func handleSearchResponse(_ response: MKLocalSearch.Response?, error: Error?) {
        if let response = response {
            print("搜尋結果: \(response.mapItems.count) 個地點")
            for (index, item) in response.mapItems.enumerated() {
                print("  \(index): \(item.name ?? "無名稱") - \(item.placemark.title ?? "無地址")")
            }
            searchResults = response.mapItems
            print("searchResults 已更新，count=\(searchResults.count)")
        } else {
            if let error = error {
                print("搜尋錯誤: \(error.localizedDescription)")
            } else {
                print("搜尋沒有回應")
            }
            searchResults = []
            print("searchResults 已清空")
        }
    }
    
    private func handleLocationPermissionDenied() {
        print("沒有位置權限")
        locationManager.requestLocationPermission()
    }
    
    private func performNearbySearch(from location: CLLocation) {
        print("使用目前位置搜尋附近店家: \(location.coordinate)")

        let request = createNearbySearchRequest(center: location.coordinate)
        let search = MKLocalSearch(request: request)

        Task { @MainActor in
            self.isSearching = true
            do {
                let response = try await search.start()
                self.isSearching = false
                self.handleNearbySearchResponse(response, error: nil, from: location)
            } catch {
                self.isSearching = false
                self.handleNearbySearchResponse(nil, error: error, from: location)
            }
        }
    }
    
    private func createNearbySearchRequest(center: CLLocationCoordinate2D) -> MKLocalSearch.Request {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "餐廳 飲料 咖啡 小吃 麵包 甜點"
        request.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        return request
    }
    
    private func handleNearbySearchResponse(_ response: MKLocalSearch.Response?, error: Error?, from location: CLLocation) {
        if let response = response {
            print("附近店家搜尋結果: \(response.mapItems.count) 個地點")
            let sortedResults = sortResultsByDistance(response.mapItems, from: location)
            searchResults = sortedResults
            // 取消任何進行中的搜尋任務，避免文字變更觸發新搜尋
            searchTask?.cancel()
            searchText = "附近的店家"
        } else if let error = error {
            print("搜尋錯誤: \(error.localizedDescription)")
            searchResults = []
        } else {
            print("搜尋沒有結果")
            searchResults = []
        }
    }

    private func waitForCurrentLocation(timeout: TimeInterval) async -> CLLocation? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let loc = locationManager.currentLocation { return loc }
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 秒輪詢
        }
        return nil
    }
    
    private func sortResultsByDistance(_ items: [MKMapItem], from location: CLLocation) -> [MKMapItem] {
        return items.sorted { item1, item2 in
            let distance1 = location.distance(from: CLLocation(
                latitude: item1.placemark.coordinate.latitude,
                longitude: item1.placemark.coordinate.longitude
            ))
            let distance2 = location.distance(from: CLLocation(
                latitude: item2.placemark.coordinate.latitude,
                longitude: item2.placemark.coordinate.longitude
            ))
            return distance1 < distance2
        }
    }
}

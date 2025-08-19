//
//  LocationManager.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/18.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var isLocationAuthorized = false
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    
    // MARK: - Constants
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654), // 台北101
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            print("請求位置權限")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("位置權限被拒絕，需要到設定開啟")
        default:
            break
        }
    }
    
    func requestLocation() {
        guard isLocationAuthorized else {
            print("沒有位置權限")
            requestLocationPermission()
            return
        }
        
        print("請求目前位置")
        locationManager.requestLocation()
    }
    
    func getCurrentRegion() -> MKCoordinateRegion {
        if let currentLocation = currentLocation {
            return MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            return Self.defaultRegion
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        print("設置 LocationManager")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        authorizationStatus = locationManager.authorizationStatus
        print("目前授權狀態: \(authorizationStatus.rawValue)")

        handleAuthorizationStatus(authorizationStatus)
    }
    
    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("位置權限未確定")
            updateLocationState(location: nil, isAuthorized: false)
        case .authorizedWhenInUse, .authorizedAlways:
            print("已有位置權限，更新狀態")
            updateLocationState(location: locationManager.location, isAuthorized: true)
            if currentLocation == nil {
                locationManager.requestLocation()
            }
        case .denied, .restricted:
            print("位置權限被拒絕或受限")
            updateLocationState(location: nil, isAuthorized: false)
        @unknown default:
            print("未知授權狀態")
            updateLocationState(location: nil, isAuthorized: false)
        }
    }
    
    private func updateLocationState(location: CLLocation?, isAuthorized: Bool) {
        self.currentLocation = location
        self.isLocationAuthorized = isAuthorized
        
        if let location = location {
            print("位置已更新: \(location.coordinate)")
        }
        print("授權狀態已更新: \(isAuthorized)")
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("定位成功: \(location.coordinate)")
        updateLocationState(location: location, isAuthorized: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失敗: \(error.localizedDescription)")
        // 定位失敗不應改變授權狀態
        // 授權狀態的變更應僅由 locationManagerDidChangeAuthorization 處理
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        print("授權狀態變更: \(newStatus.rawValue)")
        
        authorizationStatus = newStatus
        handleAuthorizationStatus(newStatus)
    }
}

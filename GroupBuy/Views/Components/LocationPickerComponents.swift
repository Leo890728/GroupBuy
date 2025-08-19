//
//  LocationPickerComponents.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/18.
//

import SwiftUI
import MapKit
import CoreLocation

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
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        } else {
                            // 如果無法打開設定，則使用原來的權限請求方法
                            onRequestPermission()
                        }
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
    let isSearchFieldFocused: FocusState<Bool>.Binding
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
                .dismissKeyboardOnScroll(focus: isSearchFieldFocused)
            } else {
                EmptySearchView()
            }
        } else if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
            // 有搜尋文字但沒有結果且不在搜尋中時顯示無結果
            NoResultsView()
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
                        if isSearching {
                            HStack {
                                Spacer()
                                ProgressView("搜尋中...")
                                    .progressViewStyle(.circular)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else {
                            ForEach(searchResults, id: \.self) { item in
                                LocationRowView(item: item, onSelect: onLocationSelect)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .dismissKeyboardOnScroll(focus: isSearchFieldFocused)
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

//
//  StoreDetailView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/20.
//

import SwiftUI
import MapKit

/// 商店詳細資訊視圖
struct StoreDetailView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var showingActionSheet = false
    @State private var showingMap = false
    @State private var showingEditStore = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 商店圖片輪播區域
                    StoreImagesCarousel(store: store)
                    
                    // 商店主要資訊
                    VStack(spacing: 16) {
                        StoreHeaderSection(store: store, viewModel: viewModel)
                        
                        Divider()
                        
                        // 聯絡資訊區塊
                        StoreContactSection(store: store, showingMap: $showingMap)
                        
                        Divider()
                        
                        // 操作按鈕區塊
                        StoreActionButtons(store: store, viewModel: viewModel, showingActionSheet: $showingActionSheet)
                    }
                    .padding()
                }
            }
            .navigationTitle(store.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("商店選項", isPresented: $showingActionSheet, titleVisibility: .visible) {
                StoreActionSheet(store: store, viewModel: viewModel, showingEditStore: $showingEditStore)
            }
            .sheet(isPresented: $showingMap) {
                StoreMapView(store: store)
            }
            .sheet(isPresented: $showingEditStore) {
                AddStoreView(viewModel: viewModel, storeToEdit: store)
            }
        }
    }
}

// MARK: - Store Images Carousel
/// 商店圖片輪播組件
struct StoreImagesCarousel: View {
    let store: Store
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 主要圖片區域
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Store.spotlightColor(for: store.category).opacity(0.3),
                        Store.spotlightColor(for: store.category).opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 240)
                .overlay(
                    // 大型圖示作為背景
                    Image(systemName: store.imageURL)
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.white.opacity(0.8))
                )
            
            // 商店分類標籤
            HStack {
                Text(store.categoryDisplayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(Store.spotlightColor(for: store.category))
                    .clipShape(Capsule())
                
                if store.isCustom {
                    CustomStoreBadge()
                        .background(Color.white.opacity(0.9))
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Store Header Section  
/// 商店標題區塊
struct StoreHeaderSection: View {
    let store: Store
    @ObservedObject var viewModel: GroupBuyViewModel
    
    // 計算屬性來獲取最新的商店狀態
    private var currentStore: Store {
        viewModel.stores.first(where: { $0.id == store.id }) ?? store
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !store.description.isEmpty {
                        Text(store.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 釘選按鈕
                Button(action: {
                    viewModel.toggleStorePin(store)
                }) {
                    Image(systemName: currentStore.isPinned ? "pin.fill" : "pin")
                        .font(.title3)
                        .foregroundColor(currentStore.isPinned ? .orange : .gray)
                }
            }
            
            // 評分和距離（模擬資料）
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < 4 ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    Text("4.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("約 0.8 公里")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
}

// MARK: - Store Contact Section
/// 商店聯絡資訊區塊
struct StoreContactSection: View {
    let store: Store
    @Binding var showingMap: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // 地址資訊
            if !store.address.isEmpty {
                ContactRow(
                    icon: "location.fill",
                    title: "地址",
                    content: store.address,
                    action: {
                        showingMap = true
                    }
                )
            }
            
            // 電話資訊
            if !store.phoneNumber.isEmpty {
                ContactRow(
                    icon: "phone.fill",
                    title: "電話",
                    content: store.phoneNumber,
                    action: {
                        if let url = URL(string: "tel:\(store.phoneNumber)") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
            
            // 網站資訊
            if !store.website.isEmpty {
                ContactRow(
                    icon: "safari.fill",
                    title: "官方網站",
                    content: store.website,
                    action: {
                        if let url = URL(string: store.website) {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
            
            // 營業時間（模擬資料）
            ContactRow(
                icon: "clock.fill",
                title: "營業時間",
                content: "週一至週日 09:00-21:00"
            )
        }
    }
}

// MARK: - Contact Row
/// 聯絡資訊行組件
struct ContactRow: View {
    let icon: String
    let title: String
    let content: String
    let action: (() -> Void)?
    
    init(icon: String, title: String, content: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.content = content
        self.action = action
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(content)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - Store Action Buttons
/// 商店操作按鈕區塊
struct StoreActionButtons: View {
    let store: Store
    @ObservedObject var viewModel: GroupBuyViewModel
    @Binding var showingActionSheet: Bool
    @Environment(\.dismiss) private var dismiss
    
    // 計算屬性來獲取最新的商店狀態
    private var currentStore: Store {
        viewModel.stores.first(where: { $0.id == store.id }) ?? store
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 主要操作按鈕
            Button(action: {
                // 關閉當前視圖，然後觸發發起團購
                dismiss()
                // 這裡可以透過通知或回調來觸發主畫面的發起團購功能
                NotificationCenter.default.post(
                    name: NSNotification.Name("CreateOrderWithStore"),
                    object: store
                )
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("使用此商店發起團購")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 次要操作按鈕
            HStack(spacing: 12) {
                // 分享按鈕
                Button(action: {
                    shareStore()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private func shareStore() {
        let shareText = "\(store.name)\n地址：\(store.address)\n電話：\(store.phoneNumber)"
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
}

// MARK: - Store Action Sheet
/// 商店操作選單
struct StoreActionSheet: View {
    let store: Store
    @ObservedObject var viewModel: GroupBuyViewModel
    @Binding var showingEditStore: Bool
    
    // 計算屬性來獲取最新的商店狀態
    private var currentStore: Store {
        viewModel.stores.first(where: { $0.id == store.id }) ?? store
    }
    
    var body: some View {
        Group {
            Button(currentStore.isPinned ? "取消釘選" : "釘選商店") {
                viewModel.toggleStorePin(store)
            }
            
            Button("分享商店") {
                // 分享功能
            }
            
            if store.isCustom {
                Button("編輯商店") {
                    showingEditStore = true
                }
                
                Button("刪除商店", role: .destructive) {
                    viewModel.stores.removeAll(where: { $0.id == store.id })
                }
            }
            
            Button("取消", role: .cancel) { }
        }
    }
}

// MARK: - Store Map View
/// 商店地圖視圖
struct StoreMapView: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654), // 台北市預設座標
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 地圖區域
                Map {
                    Annotation(store.name, coordinate: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654)) {
                        VStack {
                            Image(systemName: store.imageURL)
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Store.spotlightColor(for: store.category))
                                .clipShape(Circle())
                            
                            Text(store.name)
                                .font(.caption)
                                .padding(4)
                                .background(Color.white)
                                .cornerRadius(4)
                                .shadow(radius: 2)
                        }
                    }
                }
                .frame(height: 300)
                .cornerRadius(12)
                
                // 商店基本資訊
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(store.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !store.phoneNumber.isEmpty {
                        Text(store.phoneNumber)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // 操作按鈕
                HStack(spacing: 12) {
                    Button("導航") {
                        openInMaps()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("致電") {
                        if let url = URL(string: "tel:\(store.phoneNumber)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("商店位置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = store.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// MARK: - Preview
#Preview {
    StoreDetailView(
        viewModel: GroupBuyViewModel(),
        store: Store.sampleStores[0]
    )
}

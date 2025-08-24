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
                    
                    // 照片網格區塊
                    StorePhotosGrid(store: store)
                    
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
            StoreFormView(viewModel: viewModel, storeToEdit: store)
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
//            HStack(spacing: 16) {
//                HStack(spacing: 4) {
//                    ForEach(0..<5) { index in
//                        Image(systemName: index < 4 ? "star.fill" : "star")
//                            .font(.caption)
//                            .foregroundColor(.yellow)
//                    }
//                    Text("4.0")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                
//                Text("•")
//                    .foregroundColor(.secondary)
//                
//                Text("約 0.8 公里")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                
//                Spacer()
//            }
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
            // ContactRow(
            //     icon: "clock.fill",
            //     title: "營業時間",
            //     content: "週一至週日 09:00-21:00"
            // )
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

// MARK: - Store Photos Grid
/// 商店照片網格組件
struct StorePhotosGrid: View {
    let store: Store
    @State private var showingPhotoDetail = false
    @State private var selectedPhotoIndex = 0
    
    var body: some View {
        if let photos = store.photos, !photos.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("商店照片")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(photos.count) 張照片")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(Array(photos.prefix(6).enumerated()), id: \.offset) { index, photoURL in
                        Button(action: {
                            selectedPhotoIndex = index
                            showingPhotoDetail = true
                        }) {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Store.spotlightColor(for: store.category).opacity(0.2))
                                    .overlay(
                                        ProgressView()
                                            .tint(Store.spotlightColor(for: store.category))
                                    )
                            }
                            .frame(height: 80)
                            .clipped()
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // 顯示更多照片的按鈕
                    if photos.count > 6 {
                        Button(action: {
                            selectedPhotoIndex = 6
                            showingPhotoDetail = true
                        }) {
                            Rectangle()
                                .fill(Color.black.opacity(0.7))
                                .frame(height: 80)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                        Text("+\(photos.count - 6)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 查看所有照片按鈕
                Button(action: {
                    selectedPhotoIndex = 0
                    showingPhotoDetail = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("查看所有照片")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .fullScreenCover(isPresented: $showingPhotoDetail) {
                PhotoDetailView(photos: photos, currentIndex: selectedPhotoIndex)
            }
        }
    }
}

// MARK: - Photo Detail View
/// 照片詳細檢視
struct PhotoDetailView: View {
    let photos: [URL]
    let currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex: Int
    @State private var showingShareSheet = false
    
    init(photos: [URL], currentIndex: Int) {
        self.photos = photos
        self.currentIndex = currentIndex
        self._selectedIndex = State(initialValue: currentIndex)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                TabView(selection: $selectedIndex) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, photoURL in
                        ZoomableImageView(url: photoURL)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // 頂部工具列
                VStack {
                    HStack {
                        Button("完成") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // 底部照片計數
                    HStack {
                        Spacer()
                        Text("\(selectedIndex + 1) / \(photos.count)")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingShareSheet) {
            if selectedIndex < photos.count {
                ShareSheet(items: [photos[selectedIndex]])
            }
        }
    }
}

// MARK: - Zoomable Image View
/// 可縮放的圖片視圖
struct ZoomableImageView: View {
    let url: URL
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale *= delta
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1.0 {
                                withAnimation {
                                    scale = 1.0
                                    offset = .zero
                                }
                            } else if scale > 3.0 {
                                withAnimation {
                                    scale = 3.0
                                }
                            }
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    ProgressView()
                        .tint(.white)
                )
        }
    }
}

// MARK: - Share Sheet
/// 分享功能表
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Store Action Buttons
/// 商店操作按鈕區塊
struct StoreActionButtons: View {
    let store: Store
    @ObservedObject var viewModel: GroupBuyViewModel
    @Binding var showingActionSheet: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var isCreatingOrder = false
    
    // 計算屬性來獲取最新的商店狀態
    private var currentStore: Store {
        viewModel.stores.first(where: { $0.id == store.id }) ?? store
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 主要操作按鈕
            Button(action: {
                createOrderWithStore()
            }) {
                HStack {
                    if isCreatingOrder {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text(isCreatingOrder ? "正在開啟..." : "使用此商店發起團購")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCreatingOrder ? Color.blue.opacity(0.7) : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isCreatingOrder)
            
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
    
    private func createOrderWithStore() {
        isCreatingOrder = true
        
        // 添加輕微延遲以顯示載入狀態
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 發送通知觸發團購建立
            NotificationCenter.default.post(
                name: NSNotification.Name("CreateOrderWithStore"),
                object: store
            )
            
            // 關閉當前視圖
            dismiss()
            
            // 重置載入狀態
            isCreatingOrder = false
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
    let sampleStore = Store(
        name: "測試餐廳",
        address: "台北市信義區信義路五段7號",
        phoneNumber: "02-1234-5678",
        website: "https://example.com",
        photos: [
            URL(string: "https://picsum.photos/400/300?random=1"),
            URL(string: "https://picsum.photos/400/300?random=2"),
            URL(string: "https://picsum.photos/400/300?random=3"),
            URL(string: "https://picsum.photos/400/300?random=4"),
            URL(string: "https://picsum.photos/400/300?random=5"),
            URL(string: "https://picsum.photos/400/300?random=6"),
            URL(string: "https://picsum.photos/400/300?random=7"),
            URL(string: "https://picsum.photos/400/300?random=8")
        ].compactMap { $0 },
        imageURL: "fork.knife",
        category: .restaurant,
        description: "美味的測試餐廳，提供各種精緻料理"
    )
    
    NavigationView {
        StoreDetailView(
            viewModel: GroupBuyViewModel(),
            store: sampleStore
        )
    }
}

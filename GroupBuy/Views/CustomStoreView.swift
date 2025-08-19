//
//  CustomStoreView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI
import PhotosUI
import MapKit

struct CustomStoreView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: GroupBuyViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Store Information State
    @State private var storeName = ""
    @State private var storeDescription = ""
    @State private var storeAddress = ""
    @State private var storePhoneNumber = ""
    @State private var selectedCategory: MKPointOfInterestCategory? = nil
    
    // MARK: - Photo State
    @State private var storePhotoItems: [PhotosPickerItem] = []
    @State private var storePhotos: [UIImage] = []
    private let maxStorePhotos: Int = 5
    
    // MARK: - UI State
    @State private var showingLocationPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAutoFilled = false
    
    // MARK: - Constants
    private let iconOptions: [(category: MKPointOfInterestCategory?, displayName: String)] = [
        (nil, "自訂"),
        (.restaurant, Store.categoryDisplayName(for: .restaurant)),
        (.cafe, Store.categoryDisplayName(for: .cafe)),
        (.bakery, Store.categoryDisplayName(for: .bakery)),
        (.store, Store.categoryDisplayName(for: .store)),
        (.foodMarket, Store.categoryDisplayName(for: .foodMarket))
    ]
    
    var body: some View {
        NavigationView {
            Form {
                storeInformationSection
                storePhotosSection
                iconSelectionSection
                previewSection
            }
            .navigationTitle("自訂商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                navigationBarItems
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingLocationPicker) {
                locationPickerSheet
            }
        }
    }
    
    // MARK: - Store Information Section
    private var storeInformationSection: some View {
        Section("商店資訊") {
            locationSelectionButton
            storeNameField
            phoneNumberField
            
            TextField("商店描述", text: $storeDescription)
            
            categoryPicker
        }
    }
    
    // MARK: - Location Selection Button
    private var locationSelectionButton: some View {
        Button(action: {
            showingLocationPicker = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if !storeAddress.isEmpty {
                        Text(storeAddress)
                            .foregroundColor(.primary)
                            .font(.body)
                    } else {
                        Text("地點")
                            .foregroundColor(.secondary)
                            .font(.body)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Store Name Field
    private var storeNameField: some View {
        HStack {
            TextField("商店名稱", text: $storeName)
            if !storeName.isEmpty && isAutoFilled {
                autoFilledIndicator
            }
        }
    }
    
    // MARK: - Phone Number Field
    private var phoneNumberField: some View {
        HStack {
            TextField("聯絡電話", text: $storePhoneNumber)
            if !storePhoneNumber.isEmpty && isAutoFilled {
                autoFilledIndicator
            }
        }
    }
    
    // MARK: - Auto-filled Indicator
    private var autoFilledIndicator: some View {
        Image(systemName: "location.fill")
            .foregroundColor(.green)
            .font(.caption)
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        Picker("分類", selection: $selectedCategory) {
            Text("自訂").tag(nil as MKPointOfInterestCategory?)
            ForEach(Store.commonCategories, id: \.self) { category in
                Text(Store.categoryDisplayName(for: category))
                    .tag(category as MKPointOfInterestCategory?)
            }
        }
    }

    
    // MARK: - Store Photos Section
    private var storePhotosSection: some View {
        Section(
            header: storePhotosSectionHeader
        ) {
            if !storePhotos.isEmpty {
                photoScrollView
            }
            photoCountIndicator
        }
    }
    
    // MARK: - Store Photos Section Header
    private var storePhotosSectionHeader: some View {
        HStack {
            Text("商店圖片")
            Spacer()
            PhotosPicker(
                selection: $storePhotoItems,
                maxSelectionCount: maxStorePhotos,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Image(systemName: "plus.circle")
            }
            .onChange(of: storePhotoItems) { _, newItems in
                loadSelectedPhotos(from: newItems)
            }
        }
    }
    
    // MARK: - Photo Scroll View
    private var photoScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(storePhotos.indices, id: \.self) { index in
                    photoThumbnail(at: index)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Photo Thumbnail
    private func photoThumbnail(at index: Int) -> some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: storePhotos[index])
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 140)
                .clipped()
                .cornerRadius(8)

            Button {
                withAnimation {
                    removePhoto(at: index)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(6)
        }
    }
    
    // MARK: - Photo Count Indicator
    private var photoCountIndicator: some View {
        HStack {
            Spacer()
            Text("已選 \(storePhotos.count) / \(maxStorePhotos) 張")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // MARK: - Icon Selection Section
    private var iconSelectionSection: some View {
        Section("選擇圖示") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(iconOptions, id: \.displayName) { option in
                    iconOptionButton(for: option)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Icon Option Button
    private func iconOptionButton(for option: (category: MKPointOfInterestCategory?, displayName: String)) -> some View {
        Button(action: {
            selectedCategory = option.category
        }) {
            VStack(spacing: 8) {
                // Spotlight 風格圖示
                Image(systemName: Store.spotlightIcon(for: option.category))
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 28, height: 28)
                    .background(Store.spotlightColor(for: option.category))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(option.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedCategory == option.category ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedCategory == option.category ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        Section(Store.categoryDisplayName(for: selectedCategory)) {
            HStack {
                // Spotlight 風格圖示預覽
                Image(systemName: Store.spotlightIcon(for: selectedCategory))
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 28, height: 28)
                    .background(Store.spotlightColor(for: selectedCategory))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading) {
                    Text(storeName.isEmpty ? "商店名稱" : storeName)
                        .font(.headline)
                    Text(storeDescription.isEmpty ? "商店描述" : storeDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .cornerRadius(8)
        }
    }
    
    // MARK: - Navigation Bar Items
    private var navigationBarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("新增") {
                    addCustomStore()
                }
                .disabled(storeName.isEmpty)
            }
        }
    }
    
    // MARK: - Location Picker Sheet
    private var locationPickerSheet: some View {
        LocationPickerView(
            selectedAddress: $storeAddress,
            selectedName: $storeName,
            selectedPhoneNumber: $storePhoneNumber,
            selectedCategory: $selectedCategory,
            isPresented: $showingLocationPicker,
            onLocationSelected: {
                isAutoFilled = true
            }
        )
    }
    
    // MARK: - Helper Methods
    
    /// 載入選擇的照片
    private func loadSelectedPhotos(from items: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            for item in items {
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        images.append(uiImage)
                    }
                } catch {
                    print("載入照片失敗: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                storePhotos = images
            }
        }
    }
    
    /// 移除指定索引的照片
    private func removePhoto(at index: Int) {
        if storePhotoItems.indices.contains(index) {
            storePhotoItems.remove(at: index)
        }
        if storePhotos.indices.contains(index) {
            storePhotos.remove(at: index)
        }
    }
    
    /// 新增自訂商店
    private func addCustomStore() {
        let customStore = Store(
            name: storeName,
            address: storeAddress,
            phoneNumber: storePhoneNumber,
            imageURL: Store.spotlightIcon(for: selectedCategory),
            category: selectedCategory,
            description: storeDescription,
            isCustom: true
        )
        
        viewModel.addCustomStore(customStore)
        
        alertMessage = "商店新增成功！"
        showingAlert = true
        
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 秒
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CustomStoreView(viewModel: GroupBuyViewModel())
}

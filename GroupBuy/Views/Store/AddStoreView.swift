//
//  CustomStoreView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI
import PhotosUI
import MapKit

struct AddStoreView: View {
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
    

    
    var body: some View {
        NavigationView {
            Form {
                storeInformationSection
                storePhotosSection
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
        Menu {
            // 自訂選項
            Button(action: {
                selectedCategory = nil
            }) {
                HStack(spacing: 12) {
                    Image(systemName: Store.spotlightIcon(for: nil))
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(Store.spotlightColor(for: nil))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("自訂")
                        .font(.body)
                    Spacer()
                }
            }
            
            // 其他分類選項
            ForEach(Store.commonCategories, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: Store.spotlightIcon(for: category))
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 32, height: 32)
                            .background(Store.spotlightColor(for: category))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(Store.categoryDisplayName(for: category))
                            .font(.body)
                        Spacer()
                    }
                }
            }
        } label: {
            HStack {
                Text("分類")
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 8) {
                    if let selectedCategory = selectedCategory {
                        Image(systemName: Store.spotlightIcon(for: selectedCategory))
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 24, height: 24)
                            .background(Store.spotlightColor(for: selectedCategory))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text(Store.categoryDisplayName(for: selectedCategory))
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: Store.spotlightIcon(for: nil))
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 24, height: 24)
                            .background(Store.spotlightColor(for: nil))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("自訂")
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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
    AddStoreView(viewModel: GroupBuyViewModel())
}

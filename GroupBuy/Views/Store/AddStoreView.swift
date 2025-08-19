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
    
    // MARK: - Edit Mode Support
    let storeToEdit: Store?
    private var isEditMode: Bool { storeToEdit != nil }
    
    // MARK: - Store Information State
    @State private var storeName = ""
    @State private var storeDescription = ""
    @State private var storeAddress = ""
    @State private var storePhoneNumber = ""
    @State private var storeWebsite = ""
    @State private var selectedCategory: MKPointOfInterestCategory? = nil
    
    // MARK: - Photo State
    @State private var storePhotoItems: [PhotosPickerItem] = []
    @State private var storePhotos: [UIImage] = []
    @State private var existingPhotos: [UIImage] = [] // 從編輯模式載入的現有照片
    @State private var newPhotos: [UIImage] = [] // 新選擇的照片
    private let maxStorePhotos: Int = 5
    
    // MARK: - UI State
    @State private var showingLocationPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAutoFilled = false
    @State private var isLoading = false
    
    // MARK: - Initializer
    init(viewModel: GroupBuyViewModel, storeToEdit: Store? = nil) {
        self.viewModel = viewModel
        self.storeToEdit = storeToEdit
    }
    

    
    var body: some View {
        NavigationView {
            Form {
                storeInformationSection
                storePhotosSection
            }
            .navigationTitle(isEditMode ? "編輯商店" : "自訂商店")
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
            .onAppear {
                loadStoreDataIfEditing()
            }
        }
    }
    
    // MARK: - Store Information Section
    private var storeInformationSection: some View {
        Section("商店資訊") {
            locationSelectionButton
            storeNameField
            phoneNumberField
            websiteField
            
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
    
    // MARK: - Text Field with Auto-fill Indicator
    private func textFieldWithAutoFillIndicator(
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences,
        autocorrection: Bool = true
    ) -> some View {
        HStack {
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(!autocorrection)
            if !text.wrappedValue.isEmpty && isAutoFilled {
                autoFilledIndicator
            }
        }
    }
    
    // MARK: - Store Name Field
    private var storeNameField: some View {
        textFieldWithAutoFillIndicator(placeholder: "商店名稱", text: $storeName)
    }
    
    // MARK: - Phone Number Field
    private var phoneNumberField: some View {
        textFieldWithAutoFillIndicator(placeholder: "聯絡電話", text: $storePhoneNumber)
    }
    
    // MARK: - Website Field
    private var websiteField: some View {
        textFieldWithAutoFillIndicator(
            placeholder: "官方網站", 
            text: $storeWebsite,
            keyboardType: .URL,
            autocapitalization: .never,
            autocorrection: false
        )
    }
    
    // MARK: - Auto-filled Indicator
    private var autoFilledIndicator: some View {
        Image(systemName: "location.fill")
            .foregroundColor(.green)
            .font(.caption)
    }
    
    // MARK: - Category Icon View
    private func categoryIconView(for category: MKPointOfInterestCategory?, size: CGFloat = 32, cornerRadius: CGFloat = 8) -> some View {
        Image(systemName: Store.spotlightIcon(for: category))
            .foregroundColor(.white)
            .font(.system(size: size * 0.5, weight: .medium))
            .frame(width: size, height: size)
            .background(Store.spotlightColor(for: category))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    // MARK: - Category Menu Item
    private func categoryMenuItem(for category: MKPointOfInterestCategory?) -> some View {
        Button(action: {
            selectedCategory = category
        }) {
            HStack(spacing: 12) {
                categoryIconView(for: category)
                Text(category == nil ? "自訂" : Store.categoryDisplayName(for: category!))
                    .font(.body)
                Spacer()
            }
        }
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        Menu {
            // 自訂選項
            categoryMenuItem(for: nil)
            
            // 其他分類選項
            ForEach(Store.commonCategories, id: \.self) { category in
                categoryMenuItem(for: category)
            }
        } label: {
            HStack {
                Text("分類")
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 8) {
                    categoryIconView(for: selectedCategory, size: 24, cornerRadius: 6)
                    Text(selectedCategory == nil ? "自訂" : Store.categoryDisplayName(for: selectedCategory!))
                        .foregroundColor(.secondary)
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
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                PhotosPicker(
                    selection: $storePhotoItems,
                    maxSelectionCount: max(0, maxStorePhotos - existingPhotos.count),
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "plus.circle")
                }
                .disabled(storePhotos.count >= maxStorePhotos)
                .onChange(of: storePhotoItems) { _, newItems in
                    loadSelectedPhotos(from: newItems)
                }
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
                .foregroundColor(storePhotos.count >= maxStorePhotos ? .orange : .secondary)
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
                Button(isEditMode ? "儲存" : "新增") {
                    if isEditMode {
                        updateStore()
                    } else {
                        addCustomStore()
                    }
                }
                .disabled(storeName.isEmpty || isLoading)
            }
        }
    }
    
    // MARK: - Location Picker Sheet
    private var locationPickerSheet: some View {
        LocationPickerView(
            selectedAddress: $storeAddress,
            selectedName: $storeName,
            selectedPhoneNumber: $storePhoneNumber,
            selectedWebsite: $storeWebsite,
            selectedCategory: $selectedCategory,
            isPresented: $showingLocationPicker,
            onLocationSelected: {
                isAutoFilled = true
            }
        )
    }
    
    // MARK: - Helper Methods
    
    /// 載入編輯模式的商店資料
    private func loadStoreDataIfEditing() {
        guard let store = storeToEdit else { return }
        
        storeName = store.name
        storeDescription = store.description
        storeAddress = store.address
        storePhoneNumber = store.phoneNumber
        storeWebsite = store.website
        selectedCategory = store.category
        
        // 載入現有照片
        if let photoURLs = store.photos {
            loadImagesFromURLs(photoURLs)
        }
    }
    
    /// 從 URL 陣列載入圖片
    private func loadImagesFromURLs(_ urls: [URL]) {
        Task {
            var images: [UIImage] = []
            for url in urls {
                do {
                    let data = try Data(contentsOf: url)
                    if let uiImage = UIImage(data: data) {
                        images.append(uiImage)
                    }
                } catch {
                    print("載入照片失敗: \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                existingPhotos = images
                updateCombinedPhotos()
            }
        }
    }
    
    // MARK: - File Management
    
    /// 取得商店照片目錄路徑
    private var storePhotosDirectory: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent("StorePhotos")
    }
    
    /// 確保目錄存在
    private func ensureDirectoryExists() throws {
        guard let directory = storePhotosDirectory else {
            throw FileError.directoryNotFound
        }
        
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    
    /// 將 UIImage 陣列保存為本地文件並返回 URL 陣列
    private func savePhotosToLocalFiles(_ images: [UIImage]) -> [URL] {
        var photoURLs: [URL] = []
        
        guard let storePhotosDirectory = storePhotosDirectory else {
            print("無法獲取文檔目錄")
            return photoURLs
        }
        
        do {
            try ensureDirectoryExists()
        } catch {
            print("創建目錄失敗: \(error.localizedDescription)")
            return photoURLs
        }
        
        // 保存每張圖片
        for (index, image) in images.enumerated() {
            let fileName = "\(UUID().uuidString)_\(index).jpg"
            let fileURL = storePhotosDirectory.appendingPathComponent(fileName)
            
            // 將 UIImage 轉換為 JPEG 數據
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                do {
                    try imageData.write(to: fileURL)
                    photoURLs.append(fileURL)
                } catch {
                    print("保存照片失敗: \(error.localizedDescription)")
                }
            }
        }
        
        return photoURLs
    }
    
    /// 刪除舊的照片文件
    private func deleteOldPhotoFiles(_ urls: [URL]) {
        for url in urls {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("刪除舊照片失敗: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - File Error Types
    private enum FileError: LocalizedError {
        case directoryNotFound
        
        var errorDescription: String? {
            switch self {
            case .directoryNotFound:
                return "無法找到文檔目錄"
            }
        }
    }
    
    /// 載入選擇的照片
    private func loadSelectedPhotos(from items: [PhotosPickerItem]) {
        // 檢查是否會超過限制
        let availableSlots = maxStorePhotos - existingPhotos.count
        let itemsToProcess = Array(items.prefix(availableSlots))
        
        Task {
            var images: [UIImage] = []
            
            await MainActor.run {
                isLoading = true
            }
            
            for item in itemsToProcess {
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        images.append(uiImage)
                    }
                } catch {
                    print("載入照片失敗: \(error.localizedDescription)")
                    await MainActor.run {
                        alertMessage = "載入照片失敗，請重試"
                        showingAlert = true
                    }
                }
            }

            await MainActor.run {
                isLoading = false
                newPhotos = images
                updateCombinedPhotos()
                
                // 更新 PhotosPicker 選擇項目
                storePhotoItems = itemsToProcess
            }
        }
    }
    
    /// 更新合併後的照片陣列
    private func updateCombinedPhotos() {
        storePhotos = existingPhotos + newPhotos
    }
    
    /// 移除指定索引的照片
    private func removePhoto(at index: Int) {
        // 判斷是現有照片還是新選擇的照片
        if index < existingPhotos.count {
            // 移除現有照片
            if isEditMode,
               let originalPhotos = storeToEdit?.photos,
               index < originalPhotos.count {
                let urlToDelete = originalPhotos[index]
                do {
                    try FileManager.default.removeItem(at: urlToDelete)
                } catch {
                    print("刪除照片文件失敗: \(error.localizedDescription)")
                }
            }
            existingPhotos.remove(at: index)
        } else {
            // 移除新選擇的照片
            let newPhotoIndex = index - existingPhotos.count
            if newPhotoIndex < newPhotos.count && newPhotoIndex < storePhotoItems.count {
                newPhotos.remove(at: newPhotoIndex)
                storePhotoItems.remove(at: newPhotoIndex)
            }
        }
        
        // 更新合併後的照片陣列
        updateCombinedPhotos()
    }
    
    /// 新增自訂商店
    private func addCustomStore() {
        isLoading = true
        
        Task {
            let photoURLs = savePhotosToLocalFiles(storePhotos)
            
            let customStore = Store(
                name: storeName,
                address: storeAddress,
                phoneNumber: storePhoneNumber,
                website: storeWebsite,
                photos: photoURLs.isEmpty ? nil : photoURLs,
                imageURL: Store.spotlightIcon(for: selectedCategory),
                category: selectedCategory,
                description: storeDescription,
                isCustom: true
            )
            
            await MainActor.run {
                viewModel.addCustomStore(customStore)
                showSuccessAndDismiss(message: "商店新增成功！")
            }
        }
    }
    
    /// 更新現有商店
    private func updateStore() {
        guard let originalStore = storeToEdit else { return }
        
        isLoading = true
        
        Task {
            // 刪除舊的照片文件（如果存在）
            if let oldPhotoURLs = originalStore.photos {
                deleteOldPhotoFiles(oldPhotoURLs)
            }
            
            // 將新照片保存為本地文件
            let photoURLs = savePhotosToLocalFiles(storePhotos)
            
            let updatedStore = Store(
                id: originalStore.id,
                name: storeName,
                address: storeAddress,
                phoneNumber: storePhoneNumber,
                website: storeWebsite,
                photos: photoURLs.isEmpty ? nil : photoURLs,
                imageURL: Store.spotlightIcon(for: selectedCategory),
                category: selectedCategory,
                description: storeDescription,
                isCustom: originalStore.isCustom,
                isPinned: originalStore.isPinned
            )
            
            await MainActor.run {
                viewModel.updateStore(updatedStore)
                showSuccessAndDismiss(message: "商店更新成功！")
            }
        }
    }
    
    /// 顯示成功訊息並關閉視圖
    private func showSuccessAndDismiss(message: String) {
        isLoading = false
        alertMessage = message
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
#Preview("新增商店") {
    AddStoreView(viewModel: GroupBuyViewModel())
}

#Preview("編輯商店") {
    AddStoreView(viewModel: GroupBuyViewModel(), storeToEdit: Store.sampleStores[0])
}

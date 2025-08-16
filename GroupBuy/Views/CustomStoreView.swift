//
//  CustomStoreView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI
import PhotosUI

struct CustomStoreView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var storePhotoItems: [PhotosPickerItem] = []
    @State private var storePhotos: [UIImage] = []
    @State private var maxStorePhotos: Int = 5
    @State private var storeName = ""
    @State private var storeDescription = ""
    @State private var storeAddress = ""
    @State private var storePhoneNumber = ""
    @State private var selectedCategory: Store.StoreCategory = .custom
    @State private var selectedIcon = "bag.fill"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let iconOptions = [
        "bag.fill", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill",
        "birthday.cake.fill", "fork.knife", "wineglass.fill",
        "leaf.fill", "flame.fill", "snowflake", "rectangle.portrait.and.arrow.forward"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("商店資訊") {
                    TextField("商店名稱", text: $storeName)
                    TextField("商店描述", text: $storeDescription)
                    TextField("商店地址", text: $storeAddress)
                    TextField("商店電話", text: $storePhoneNumber)
                    
                    Picker("分類", selection: $selectedCategory) {
                        ForEach(Store.StoreCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }

                Section("菜單圖片") {
                    if !storePhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(storePhotos.indices, id: \.self) { idx in
                                    ZStack(alignment: .topLeading) {
                                        Image(uiImage: storePhotos[idx])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 140)
                                            .clipped()
                                            .cornerRadius(8)

                                        Button {
                                            withAnimation {
                                                // 先移除 PhotosPickerItem（若存在），再移除 image
                                                if storePhotoItems.indices.contains(idx) {
                                                    storePhotoItems.remove(at: idx)
                                                }
                                                if storePhotos.indices.contains(idx) {
                                                    storePhotos.remove(at: idx)
                                                }
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
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    PhotosPicker(
                        selection: $storePhotoItems,
                        maxSelectionCount: maxStorePhotos, matching: .images,
                        photoLibrary: .shared()) {
                            Text("選擇菜單圖片")
                        }
                        .onChange(of: storePhotoItems) { newItems in
                            // 當選取改變時，載入所有圖片 (非同步)
                            Task {
                                var images: [UIImage] = []
                                for item in newItems {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        images.append(uiImage)
                                    }
                                }

                                // 更新主執行緒的 state
                                await MainActor.run {
                                    storePhotos = images
                                }
                            }
                        }

                    // 顯示已選張數 / 上限
                    HStack {
                        Spacer()
                        Text("已選 \(storePhotos.count) / \(maxStorePhotos) 張")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                Section("選擇圖示") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .foregroundColor(selectedIcon == icon ? .blue : .primary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain) // 僅讓按鈕本身可點，避免整個列成為可點擊區域
                .listRowBackground(Color.clear) // 移除列背景高亮，避免誤觸感
                
                Section(selectedCategory.rawValue) {
                    HStack {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundColor(.blue)
                        
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
            .navigationTitle("自訂商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            .alert("提示", isPresented: $showingAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addCustomStore() {
        let customStore = Store(
            name: storeName,
            address: storeAddress,
            phoneNumber: storePhoneNumber,
            imageURL: selectedIcon,
            category: selectedCategory,
            description: storeDescription,
            isCustom: true
        )
        
        viewModel.addCustomStore(customStore)
        alertMessage = "商店新增成功！"
        showingAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

#Preview {
    CustomStoreView(viewModel: GroupBuyViewModel())
}

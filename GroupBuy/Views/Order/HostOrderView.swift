//
//  HostOrderView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct HostOrderView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStore: Store?
    @State private var showingStoreSheet = false
    @State private var orderTitle = ""
    @State private var organizerName = ""
    @State private var startDate = Date() // 開始時間，預設為現在
    @State private var endDate = Date().addingTimeInterval(3600) // 預設1小時後
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAllDay = false
    @State private var isPublic = true // 新增：公開或私人選項
    
    // 支援預選商店的初始化器
    let preselectedStore: Store?
    
    init(viewModel: GroupBuyViewModel, preselectedStore: Store? = nil) {
        self.viewModel = viewModel
        self.preselectedStore = preselectedStore
        
        // 如果有預選商店，在初始化時就設置一些預設值
        if let store = preselectedStore {
            self._selectedStore = State(initialValue: store)
            self._orderTitle = State(initialValue: "\(store.name) 團購")
        }
        
        // 若有目前登入使用者，預設發起人姓名為該使用者的 name
        if let currentName = viewModel.userManager.currentUser?.name {
            self._organizerName = State(initialValue: currentName)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("可見性") {
                    // 公開或私人
                    Picker("可見性", selection: $isPublic) {
                        Text("公開").tag(true)
                        Text("私人").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                    
                Section("選擇商店") {
                    Button(action: {
                        showingStoreSheet = true
                    }) {
                        HStack {
                            if let selectedStore = selectedStore {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedStore.name)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    if !selectedStore.description.isEmpty {
                                        Text(selectedStore.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                Text("請選擇商店")
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            Image(systemName: selectedStore == nil ? "chevron.right" : "checkmark.circle.fill")
                                .foregroundColor(selectedStore == nil ? .gray : .green)
                        }
                    }
                }
                
                Section("團購資訊") {
                    TextField("團購標題", text: $orderTitle)
                    TextField("備註事項", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("時間設定") {
                    // 整日開關
                    HStack {
                        Text("整日")
                        Spacer()
                        Toggle("", isOn: $isAllDay)
                    }
                    
                    // 開始時間
                    HStack {
                        Text("開始時間")
                        Spacer()
                        
                        if isAllDay {
                            DatePicker("", selection: $startDate, displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: startDate) { newValue in
                                    // 確保結束日期不早於開始日期
                                    if endDate < newValue {
                                        endDate = Calendar.current.date(byAdding: .day, value: 1, to: newValue) ?? newValue
                                    }
                                }
                        } else {
                            DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: startDate) { newValue in
                                    // 確保結束時間不早於開始時間
                                    if endDate < newValue {
                                        endDate = newValue.addingTimeInterval(3600) // 預設1小時後
                                    }
                                }
                        }
                    }
                    
                    // 結束時間
                    HStack {
                        Text("結束時間")
                        Spacer()
                        
                        if isAllDay {
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                        } else {
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                    }
                }
            }
            .navigationTitle("發起團購")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("發起") {
                        createOrder()
                    }
                    .disabled(!canCreateOrder)
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingStoreSheet) {
                StoreListView(viewModel: viewModel, selectedStore: $selectedStore)
            }
            .onAppear {
                // 如果有預選商店但當前沒有選中商店，設置為選中狀態
                // 這是為了處理狀態初始化可能失敗的情況
                if let preselected = preselectedStore, selectedStore == nil {
                    selectedStore = preselected
                    if orderTitle.isEmpty {
                        orderTitle = "\(preselected.name) 團購"
                    }
                }
            }
        }
    }
    
    private var canCreateOrder: Bool {
        selectedStore != nil && !orderTitle.isEmpty && !organizerName.isEmpty
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
    
    private func createOrder() {
        guard let store = selectedStore else {
            alertMessage = "請選擇商店"
            showingAlert = true
            return
        }
        // 優先使用當前登入使用者作為發起人，若無則根據輸入的 organizerName 建立一個臨時 User
        let organizerUser: User
        if let current = viewModel.userManager.currentUser {
            organizerUser = current
        } else {
            // 假設 email 為 placeholder（必要欄位），可由使用者後續編輯
            let emailPlaceholder = organizerName.isEmpty ? "user@example.com" : "\(organizerName.lowercased())@example.com"
            organizerUser = User(name: organizerName.isEmpty ? "匿名" : organizerName, email: emailPlaceholder)
        }

        let order = GroupBuyOrder(
            title: orderTitle,
            store: store,
            organizer: organizerUser,
            endTime: endDate, // 使用結束時間作為主要時間
            notes: notes,
            participants: [],
            isPublic: isPublic,
            status: .active,
            createdAt: startDate // 使用開始時間作為建立時間
        )
        
        viewModel.createGroupBuyOrder(order)
        alertMessage = "團購發起成功！"
        showingAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

#Preview {
    HostOrderView(viewModel: GroupBuyViewModel(), preselectedStore: nil)
}

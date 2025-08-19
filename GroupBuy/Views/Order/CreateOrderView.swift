//
//  CreateOrderView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct CreateOrderView: View {
    @ObservedObject var viewModel: GroupBuyViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStore: Store?
    @State private var orderTitle = ""
    @State private var organizerName = ""
    @State private var endDate = Date().addingTimeInterval(3600) // 預設1小時後
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("選擇商店") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(viewModel.stores) { store in
                            StoreCardView(store: store, isSelected: selectedStore?.id == store.id, viewModel: viewModel) {
                                selectedStore = store
                            }
                        }
                    }
                }
                
                Section("團購資訊") {
                    TextField("團購標題", text: $orderTitle)
                    TextField("發起人姓名", text: $organizerName)
                    
                    DatePicker("結束時間", selection: $endDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("備註事項", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
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
        }
    }
    
    private var canCreateOrder: Bool {
        selectedStore != nil && !orderTitle.isEmpty && !organizerName.isEmpty
    }
    
    private func createOrder() {
        guard let store = selectedStore else {
            alertMessage = "請選擇商店"
            showingAlert = true
            return
        }
        
        let order = GroupBuyOrder(
            title: orderTitle,
            store: store,
            organizer: organizerName,
            endTime: endDate,
            notes: notes,
            participants: [],
            status: .active,
            createdAt: Date()
        )
        
        viewModel.createGroupBuyOrder(order)
        alertMessage = "團購發起成功！"
        showingAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - StoreCardView 已移至 StoreComponents.swift

#Preview {
    CreateOrderView(viewModel: GroupBuyViewModel())
}

//
//  JoinOrderDetailView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct OrderDetailView: View {
    let order: GroupBuyOrder
    @ObservedObject var viewModel: GroupBuyViewModel
    @Environment(\.dismiss) private var dismiss
    
    // 可以選擇使用本地狀態或 ViewModel 狀態
    private let useLocalState: Bool
    @State private var orderItems: [OrderItem] = []
    @State private var participantNotes = ""
    @State private var didPrefill = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingLeaveConfirmation = false
    
    // 初始化器，允許選擇狀態管理方式
    init(order: GroupBuyOrder, viewModel: GroupBuyViewModel, useLocalState: Bool = true) {
        self.order = order
        self.viewModel = viewModel
        self.useLocalState = useLocalState
    }
    
    // 計算屬性：根據 useLocalState 決定使用哪個狀態
    private var currentOrderItems: Binding<[OrderItem]> {
        useLocalState ? $orderItems : $viewModel.currentOrderItems
    }
    
    private var currentParticipantNotes: Binding<String> {
        useLocalState ? $participantNotes : $viewModel.currentParticipantNotes
    }
    
    var body: some View {
        Form {
            Section("團購資訊") {
                HStack {
                    StoreIconView(store: order.store)

                    VStack(alignment: .leading) {
                        Text(order.title)
                            .font(.headline)
                        Text(order.store.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                    
                HStack {
                    Text("發起人")
                    Spacer()
                    Text(order.organizer.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("結束時間")
                    Spacer()
                    Text(order.endTime, formatter: DateFormatter.shortDateTime)
                        .foregroundColor(.secondary)
                }
                
                if !order.notes.isEmpty {
                    VStack(alignment: .leading) {
                        Text("備註事項")
                            .font(.subheadline)
                        Text(order.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
            }
                
            Section(header: VStack(alignment: .leading) {
                let name = viewModel.userManager.currentUser?.name ?? ""
                HStack {
                    Text("\(name) 選購的商品")
                    Spacer()
                }
            }) {
                ItemsOrderView(
                    items: currentOrderItems,
                    notes: currentParticipantNotes
                )
                .listRowSeparator(.hidden)
            }
            
            
            Section("參與者名單") {
                if order.participants.isEmpty {
                    Text("目前還沒有人參加")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(order.participants) { participant in
                        ParticipantRowView(participant: participant)
                    }
                }
            }

            // 最下面的操作區：退出團購（只對已參加且非建立者顯示）
            if isAlreadyParticipant && (viewModel.userManager.currentUser?.id != order.organizer.id) {
                Section {
                    VStack(spacing: 8) {

                        Button(role: .destructive) {
                            showingLeaveConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                Text("退出團購")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .padding(.top, 8)
                    .confirmationDialog("確認退出團購？", isPresented: $showingLeaveConfirmation, titleVisibility: .visible) {
                        Button("取消", role: .cancel) { }
                        Button("退出", role: .destructive) {
                            // 執行離開並顯示提示
                            viewModel.leaveOrderAsCurrentUser(order)
                            alertMessage = "已成功退出團購"
                            showingAlert = true
                        }
                    } message: {
                        Text("確定要從「\(order.title)」退出嗎？")
                    }
                }
                .listRowBackground(Color.clear)
                .background(Color.clear)
            }
        }
        .navigationTitle("參加團購")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isAlreadyParticipant ? "更新訂單" : "參加") {
                    joinOrder()
                }
                .disabled(!canJoin)
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("確定", role: .cancel) {
                if alertMessage.contains("成功") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            prefillIfNeeded()
        }
    }
    
    private var canJoin: Bool {
        // 改進參加按鈕判斷：檢查商品是否有效且用戶已登入
        guard viewModel.userManager.currentUser != nil else { return false }
        
        let items = useLocalState ? orderItems : viewModel.currentOrderItems
        guard !items.isEmpty else { return false }
        
        // 檢查每個商品數量 > 0
        guard items.allSatisfy({ $0.quantity > 0 }) else { return false }
        
        // 檢查是否超過團購結束時間
        guard order.endTime > Date() else { return false }
        
        return true
    }

    // 判斷目前使用者是否已參加此團購
    private var isAlreadyParticipant: Bool {
        guard let currentUser = viewModel.userManager.currentUser else { return false }
        return order.participants.contains { $0.user.id == currentUser.id }
    }
    
    private func joinOrder() {
        let items = useLocalState ? orderItems : viewModel.currentOrderItems
        let notes = useLocalState ? participantNotes : viewModel.currentParticipantNotes
        
        guard !items.isEmpty else {
            alertMessage = "請至少新增一個商品"
            showingAlert = true
            return
        }
        
        guard items.allSatisfy({ $0.quantity > 0 }) else {
            alertMessage = "所有商品數量必須大於 0"
            showingAlert = true
            return
        }
        
        guard order.endTime > Date() else {
            alertMessage = "團購已結束，無法參加"
            showingAlert = true
            return
        }
        
        // 使用多商品 API 參加團購
        viewModel.joinOrderAsCurrentUserWithItems(order, items: items, notes: notes)
        
    alertMessage = isAlreadyParticipant ? "成功更新訂單！" : "成功參加團購！"
        showingAlert = true
        
        // 清空表單
        clearOrderData()
    }

    /// 若使用者已參加該團購，將其先前的 items/notes 預填到表單以供編輯
    private func prefillIfNeeded() {
        guard !didPrefill else { return }
        didPrefill = true

        guard let currentUser = viewModel.userManager.currentUser else { return }

        if let existing = order.participants.first(where: { $0.user.id == currentUser.id }) {
            if useLocalState {
                orderItems = existing.items
                participantNotes = existing.notes
            } else {
                viewModel.setCurrentOrderState(items: existing.items, notes: existing.notes)
            }
        }
    }
    
    private func clearOrderData() {
        if useLocalState {
            orderItems.removeAll()
            participantNotes = ""
        } else {
            viewModel.clearCurrentOrderState()
        }
    }
}

// MARK: - Participant Row View
private struct ParticipantRowView: View {
    let participant: Participant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 參與者姓名和總價
            HStack {
                Text(participant.name)
                    .font(.headline)
                Spacer()
                Text("$\(Int(participant.totalPrice))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            // 統一的商品顯示邏輯 - 移除單商品/多商品的判斷
            VStack(alignment: .leading, spacing: 4) {
                ForEach(participant.items) { item in
                    HStack {
                        Text("• \(item.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if item.quantity > 1 {
                            Text("x\(item.quantity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Text("$\(Int(item.totalPrice))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !item.notes.isEmpty {
                        Text("  \(item.notes)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            
            // 整體備註
            if !participant.notes.isEmpty {
                Text(participant.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
        }
    }
}

#Preview {
    let sampleUser = User(name: "小明", email: "ming@example.com")
    let participantUser = User(name: "小華", email: "hua@example.com")
    
    let order = GroupBuyOrder(
        title: "下午茶團購",
        store: Store.sampleStores[0],
        organizer: sampleUser,
        endTime: Date().addingTimeInterval(3600),
        notes: "請在備註欄填寫甜度和冰塊",
        participants: [
            Participant(user: participantUser, order: "珍珠奶茶 大杯", price: 65, notes: "半糖少冰", joinedAt: Date())
        ],
    isPublic: true,
    status: .active,
    createdAt: Date()
    )
    
    OrderDetailView(order: order, viewModel: GroupBuyViewModel())
}

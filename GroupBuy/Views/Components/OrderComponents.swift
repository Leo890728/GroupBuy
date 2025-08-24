//
//  OrderComponents.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

// MARK: - Order Status Badge
/// 訂單狀態徽章組件
struct OrderStatusBadge: View {
    let status: GroupBuyOrder.OrderStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return .green
        case .closed:
            return .orange
        case .completed:
            return .gray
        }
    }
}

// MARK: - Order Row View
/// 訂單列表行組件，用於我的訂單列表
struct OrderRowView: View {
    let order: GroupBuyOrder
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(order.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    OrderStatusBadge(status: order.status)
                }
                
                Text(order.store.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("發起人: \(order.organizer.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 操作選單
            if onEdit != nil || onDelete != nil {
                Menu {
                    if let onEdit = onEdit {
                        Button {
                            onEdit()
                        } label: {
                            Label("編輯", systemImage: "pencil")
                        }
                    }
                    
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(10)
                        .contentShape(Rectangle())
                        .accessibilityLabel("更多選項")
                }
                .padding(.leading, 6)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        // 增強陰影：較大 radius 與 y 偏移讓陰影更明顯
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
        .padding(.horizontal, 8)
    }
}

// MARK: - Order Summary Card
/// 訂單統計卡片組件
struct OrderSummaryCard: View {
    let orderCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cart.badge.plus")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("進行中的團購")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(orderCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            if orderCount > 0 {
                Text("點擊訂單查看詳情並參加團購")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.1),
                    Color.accentColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Order Card View
/// 訂單卡片組件，用於參加團購的卡片顯示
struct OrderCardView: View {
    let order: GroupBuyOrder
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(order.title)
                        .font(.headline)
                    
                    HStack {
                        // 修復圖片顯示問題：使用 AsyncImage 替代 Label with systemName
                        if let url = URL(string: order.store.imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure(_):
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                case .empty:
                                    ProgressView()
                                        .scaleEffect(0.5)
                                @unknown default:
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                                .frame(width: 16, height: 16)
                        }
                        
                        Text(order.store.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    OrderStatusBadge(status: order.status)
                    
                    Text("\(order.participants.count) 人參與")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label("發起人", systemImage: "person.fill")
                    .font(.caption)
                Text(order.organizer.name)
                    .font(.caption)
                
                Spacer()
                
                Label("結束時間", systemImage: "clock.fill")
                    .font(.caption)
                Text(order.endTime, style: .time)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            if !order.notes.isEmpty {
                Text(order.notes)
                    .font(.caption)
                    .padding(.top, 4)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Order Info Section
/// 訂單詳細資訊區塊組件
struct OrderInfoSection: View {
    let order: GroupBuyOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(order.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                OrderStatusBadge(status: order.status)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "storefront.fill", title: "商店", content: order.store.name)
                InfoRow(icon: "person.fill", title: "發起人", content: order.organizer.name)
                InfoRow(icon: "clock.fill", title: "結束時間", content: order.endTime.formatted(date: .abbreviated, time: .shortened))
                InfoRow(icon: "person.2.fill", title: "參與人數", content: "\(order.participants.count) 人")
                
                if !order.notes.isEmpty {
                    InfoRow(icon: "note.text", title: "備註", content: order.notes)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Info Row
/// 資訊行組件，顯示圖示、標題和內容
struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(content)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - Previews
#Preview("Order Status Badge") {
    VStack(spacing: 8) {
        OrderStatusBadge(status: .active)
        OrderStatusBadge(status: .closed)
        OrderStatusBadge(status: .completed)
    }
}

#Preview("Order Row") {
    OrderRowView(order: GroupBuyOrder(
        title: "午餐團購",
        store: Store.sampleStores[0],
        organizer: User(name: "小明", email: "ming@example.com"),
        endTime: Date().addingTimeInterval(3600),
        notes: "請準時取餐",
        participants: [],
        isPublic: true,
        status: .active,
        createdAt: Date()
    ))
}

#Preview("Order Card") {
    OrderCardView(order: GroupBuyOrder(
        title: "下午茶團購",
        store: Store.sampleStores[0],
        organizer: User(name: "小華", email: "hua@example.com"),
        endTime: Date().addingTimeInterval(7200),
        notes: "請在備註欄填寫甜度和冰塊需求",
        participants: [],
        isPublic: true,
        status: .active,
        createdAt: Date()
    )) {
        print("Join order tapped")
    }
}

// MARK: - Edit Order Sheet
/// 編輯團購訂單的 Sheet
struct EditOrderSheet: View {
    @Binding var order: GroupBuyOrder
    /// 可選的儲存回呼，父層可接收更新後的訂單
    var onSave: ((GroupBuyOrder) -> Void)? = nil
    /// 可選的取消（移除）回呼，父層可傳入刪除函式
    var onCancel: ((GroupBuyOrder) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var orderTitle = ""
    @State private var orderNotes = ""
    @State private var selectedStore: Store?
    @State private var endTime = Date()
    @State private var isPublic = true
    @State private var status: GroupBuyOrder.OrderStatus = .active
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 基本資訊 Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("基本資訊")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        OrderFormField(label: "團購標題", placeholder: "請輸入團購標題", text: $orderTitle)
                        
                        // 商店選擇 - 簡化為顯示目前商店名稱
                        VStack(alignment: .leading, spacing: 6) {
                            Text("商店")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(selectedStore?.name ?? "未選擇商店")
                                .font(.body)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // 結束時間
                        VStack(alignment: .leading, spacing: 6) {
                            Text("結束時間")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
                    
                    // 設定 Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("團購設定")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // 狀態選擇
                        VStack(alignment: .leading, spacing: 8) {
                            Text("狀態")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Picker("狀態", selection: $status) {
                                ForEach(GroupBuyOrder.OrderStatus.allCases, id: \.self) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // 可見性設定
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("公開團購")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(isPublic ? "其他人可以看到並參加" : "僅限受邀人員參加")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isPublic)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
                    
                    // 備註 Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("備註")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("團購說明或特殊要求")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $orderNotes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 1))
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))

                    VStack(spacing: 12) {
                        Button(role: .destructive) {
                            showingCancelConfirmation = true
                        } label: {
                            Text("取消舉辦團購")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                }
                .padding()
            }
            .navigationTitle("編輯團購")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveOrder()
                        // 在儲存後通知父層
                        onSave?(order)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canSaveOrder ? .accentColor : .secondary)
                    .disabled(!canSaveOrder)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            loadCurrentOrder()
        }
    // 確認對話框
    .background(cancelConfirmationDialog())
    }
    
    private var canSaveOrder: Bool {
        !orderTitle.isEmpty && selectedStore != nil
    }

    @State private var showingCancelConfirmation = false

    
    private func loadCurrentOrder() {
        orderTitle = order.title
        orderNotes = order.notes
        selectedStore = order.store
        endTime = order.endTime
        isPublic = order.isPublic
        status = order.status
    }

    // 取消舉辦的處理
    private func cancelOrder() {
        // 呼叫父層回呼
        onCancel?(order)
        dismiss()
    }

    // 在 View 的底部加入確認對話框
    @ViewBuilder
    private func cancelConfirmationDialog() -> some View {
        EmptyView()
            .confirmationDialog("確認取消團購？", isPresented: $showingCancelConfirmation, titleVisibility: .visible) {
                Button("確認取消", role: .destructive) {
                    cancelOrder()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("取消後此團購會被移除，參加者將無法再查看。此操作無法復原。")
            }
    }

    
    private func saveOrder() {
        guard let store = selectedStore else { return }
        
        order.title = orderTitle
        order.notes = orderNotes
        order.store = store
        order.endTime = endTime
        order.isPublic = isPublic
        order.status = status
        
        dismiss()
    }
}

// MARK: - Order Form Field
/// 團購表單輸入欄位組件
private struct OrderFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 1))
        }
    }
}

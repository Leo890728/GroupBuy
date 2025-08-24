//
//  ItemsOrderView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/23.
//

import SwiftUI

struct ItemsOrderView: View {
    @Binding var items: [OrderItem]
    @Binding var notes: String
    @State private var showingAddItem = false
    
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 商品列表區域
            VStack(spacing: 16) {
                if items.isEmpty {
                    EmptyItemsView {
                        showingAddItem = true
                    }
                } else {
                    ItemsListView(items: $items)
                    Divider()
                        .padding(.horizontal, 4)
                    // 總計區域
                    TotalSummaryView(totalPrice: totalPrice, itemCount: items.count)
                }
            }
            .padding(.top, 8)
            
            // 新增商品按鈕
            AddItemButton {
                showingAddItem = true
            }
            
            // 整體備註區域
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.accentColor)
                        .font(.headline)
                    Text("整體備註")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .stroke(Color(.systemGray4), lineWidth: 1)
                    
                    if notes.isEmpty {
                        Text("請輸入特殊需求或備註...")
                            .foregroundColor(.secondary)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $notes)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(minHeight: 80)
                }
                .frame(height: 80)
                .clipped()
            }
            .padding(.horizontal, 4)
        }
        .allowsHitTesting(true)
        .sheet(isPresented: $showingAddItem, ) {
            AddItemSheet(items: $items)
                .presentationDetents([.height(600), .large])
        }
    }
}

// MARK: - Sub Components

private struct EmptyItemsView: View {
    let onAddItem: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 圖示區域
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.1),
                                Color.accentColor.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "cart.badge.plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 8) {
                Text("還沒有加入任何商品")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("點擊下方按鈕開始新增您的第一個商品")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("新增第一個商品") {
                onAddItem()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .fontWeight(.semibold)
        }
        .padding(.vertical, 50)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1.5)
                        .fill(Color.clear)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private struct ItemsListView: View {
    @Binding var items: [OrderItem]
    // keep track of the editing index instead of passing a copied item
    @State private var editingIndex: Int?

    // Approximate single row height (adjust if your row design changes)
    private let approxRowHeight: CGFloat = 80
    // Maximum height for the list (so it doesn't take whole screen)
    private let maxListHeight: CGFloat = 400

    var body: some View {
        let listHeight = min(max(approxRowHeight * CGFloat(max(items.count, 1)), approxRowHeight), maxListHeight)

        List {
            ForEach(items) { item in
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    ItemRowView(item: $items[index])
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                // set the index so we can pass a direct binding to the array element
                                editingIndex = index
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .regular))
                            }
                            .tint(.blue)
                            .accessibilityLabel("編輯")
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    items.removeAll { $0.id == item.id }
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .regular))
                            }
                            .accessibilityLabel("刪除")
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(height: listHeight)
        // present sheet using isPresented, and pass a direct binding to the array element
        .sheet(isPresented: Binding(get: { editingIndex != nil }, set: { newValue in
            if !newValue { editingIndex = nil }
        })) {
            if let idx = editingIndex, items.indices.contains(idx) {
                EditItemSheet(item: $items[idx])
                    .onDisappear {
                        // clear index when sheet dismissed
                        editingIndex = nil
                    }
            } else {
                // defensive fallback: clear index
                EmptyView()
                    .onAppear { editingIndex = nil }
            }
        }
    }
}

// MARK: - Item Row View

private struct ItemRowView: View {
    @Binding var item: OrderItem
    
    var body: some View {
        HStack(spacing: 16) {
            // 商品圖示
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.8),
                                Color.accentColor.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                    Image(systemName: "bag.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
            }
            
            // 商品資訊
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if item.quantity > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "multiply")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(item.quantity)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                
                if !item.notes.isEmpty {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(item.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            // 價格資訊
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(item.totalPrice))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if item.quantity > 1 {
                    Text("$\(Int(item.price)) / 個")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    .padding(.horizontal, 12)
    .frame(minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
        )
    }
}

private struct TotalSummaryView: View {
    let totalPrice: Double
    let itemCount: Int
    
    var body: some View {
        HStack(spacing: 16) {

            VStack(alignment: .leading, spacing: 2) {
                Text("總計")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(itemCount) 項商品")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 右側價格
            Text("$\(Int(totalPrice))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(10)
    }
}

private struct AddItemButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text("新增商品")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add/Edit Item Sheets

private struct AddItemSheet: View {
    @Binding var items: [OrderItem]
    @Environment(\.dismiss) private var dismiss
    
    @State private var itemName = ""
    @State private var itemPrice = ""
    @State private var itemQuantity = 1
    @State private var itemNotes = ""
    
    var body: some View {
        NavigationView {
            ItemFormView(
                itemName: $itemName,
                itemPrice: $itemPrice,
                itemQuantity: $itemQuantity,
                itemNotes: $itemNotes,
                title: "新增商品"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { 
                        dismiss() 
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新增") {
                        addItem()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canAddItem ? .accentColor : .secondary)
                    .disabled(!canAddItem)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var canAddItem: Bool {
        !itemName.isEmpty && !itemPrice.isEmpty && Double(itemPrice) != nil && itemQuantity > 0
    }
    
    private func addItem() {
        guard let price = Double(itemPrice) else { return }
        
        let newItem = OrderItem(
            name: itemName,
            price: price,
            quantity: itemQuantity,
            notes: itemNotes
        )
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            items.append(newItem)
        }
        dismiss()
    }
}

private struct EditItemSheet: View {
    @Binding var item: OrderItem
    @Environment(\.dismiss) private var dismiss
    
    @State private var itemName = ""
    @State private var itemPrice = ""
    @State private var itemQuantity = 1
    @State private var itemNotes = ""
    
    var body: some View {
        NavigationView {
            ItemFormView(
                itemName: $itemName,
                itemPrice: $itemPrice,
                itemQuantity: $itemQuantity,
                itemNotes: $itemNotes,
                title: "編輯商品"
            )
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
                        saveItem()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canSaveItem ? .accentColor : .secondary)
                    .disabled(!canSaveItem)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            loadCurrentItem()
        }
    }
    
    private var canSaveItem: Bool {
        !itemName.isEmpty && !itemPrice.isEmpty && Double(itemPrice) != nil && itemQuantity > 0
    }
    
    private func loadCurrentItem() {
        itemName = item.name
        itemPrice = String(item.price)
        itemQuantity = item.quantity
        itemNotes = item.notes
    }
    
    private func saveItem() {
        guard let price = Double(itemPrice) else { return }
        
        item.name = itemName
        item.price = price
        item.quantity = itemQuantity
        item.notes = itemNotes
        
        dismiss()
    }
}

private struct ItemFormView: View {
    @Binding var itemName: String
    @Binding var itemPrice: String
    @Binding var itemQuantity: Int
    @Binding var itemNotes: String
    let title: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 商品資訊 Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("商品資訊")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    InputField(label: "商品名稱", placeholder: "請輸入商品名稱", text: $itemName)

                    InputField(label: "單價", placeholder: "請輸入價格", text: $itemPrice, keyboardType: .decimalPad)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("數量")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        HStack {
                            Button {
                                if itemQuantity > 1 { itemQuantity -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(itemQuantity > 1 ? .accentColor : .gray)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            .disabled(itemQuantity <= 1)

                            Spacer()

                            Text("\(itemQuantity)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(minWidth: 40)
                                .allowsHitTesting(false)

                            Spacer()

                            Button {
                                if itemQuantity < 99 { itemQuantity += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(itemQuantity < 99 ? .accentColor : .gray)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            .disabled(itemQuantity >= 99)
                        }
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

                    Text("特殊需求")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    TextEditor(text: $itemNotes)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 1))
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

// Helper: simple labeled input with rounded background
private struct InputField: View {
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

// MARK: - Previews

#Preview("Items Order View - Empty") {
    ItemsOrderView(
        items: .constant([]),
        notes: .constant("")
    )
    .padding()
}

#Preview("Items Order View - With Items") {
    ItemsOrderView(
        items: .constant([
            OrderItem(name: "珍珠奶茶", price: 55, quantity: 2, notes: "半糖少冰"),
            OrderItem(name: "雞排便當", price: 85, quantity: 1, notes: "要辣椒")
        ]),
        notes: .constant("請幫忙分裝")
    )
    .padding()
}

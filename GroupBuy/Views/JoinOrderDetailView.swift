//
//  JoinOrderDetailView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct JoinOrderDetailView: View {
    let order: GroupBuyOrder
    @ObservedObject var viewModel: GroupBuyViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var participantName = ""
    @State private var participantOrder = ""
    @State private var participantPrice = ""
    @State private var participantNotes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("團購資訊") {
                    HStack {
                        Image(systemName: order.store.imageURL)
                            .foregroundColor(.blue)
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
                        Text(order.organizer)
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
                
                Section("我的訂單") {
                    TextField("您的姓名", text: $participantName)
                    TextField("訂購內容", text: $participantOrder, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("金額", text: $participantPrice)
                        .keyboardType(.decimalPad)
                    TextField("備註", text: $participantNotes)
                }
                
                Section("已參加的人") {
                    if order.participants.isEmpty {
                        Text("目前還沒有人參加")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(order.participants) { participant in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(participant.name)
                                        .font(.headline)
                                    Spacer()
                                    Text("$\(Int(participant.price))")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                                
                                Text(participant.order)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if !participant.notes.isEmpty {
                                    Text(participant.notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("參加團購")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("參加") {
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
        }
    }
    
    private var canJoin: Bool {
        !participantName.isEmpty && !participantOrder.isEmpty && !participantPrice.isEmpty
    }
    
    private func joinOrder() {
        guard let price = Double(participantPrice) else {
            alertMessage = "請輸入正確的金額"
            showingAlert = true
            return
        }
        
        let participant = Participant(
            name: participantName,
            order: participantOrder,
            price: price,
            notes: participantNotes,
            joinedAt: Date()
        )
        
        viewModel.joinOrder(order, participant: participant)
        alertMessage = "成功參加團購！"
        showingAlert = true
    }
}

#Preview {
    let order = GroupBuyOrder(
        title: "下午茶團購",
        store: Store.sampleStores[0],
        organizer: "小明",
        endTime: Date().addingTimeInterval(3600),
        notes: "請在備註欄填寫甜度和冰塊",
        participants: [
            Participant(name: "小華", order: "珍珠奶茶 大杯", price: 65, notes: "半糖少冰", joinedAt: Date())
        ],
        status: .active,
        createdAt: Date()
    )
    
    return JoinOrderDetailView(order: order, viewModel: GroupBuyViewModel())
}

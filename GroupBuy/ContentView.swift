//
//  ContentView.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/16.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GroupBuyViewModel()

    var body: some View {
        HomeView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}

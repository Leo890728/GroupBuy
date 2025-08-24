//
//  UserManager.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/23.
//

import Foundation

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    private let userDefaultsKey = "GroupBuy_CurrentUser"
    
    init() {
        loadCurrentUser()
    }
    
    // MARK: - User Authentication
    
    func login(user: User) {
        self.currentUser = user
        self.isLoggedIn = true
        saveCurrentUser()
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
        clearCurrentUser()
    }
    
    func updateUser(_ user: User) {
        self.currentUser = user
        saveCurrentUser()
    }
    
    // MARK: - User Registration
    
    func registerUser(name: String, email: String, phone: String? = nil) -> User {
        let newUser = User(name: name, email: email, phone: phone)
        login(user: newUser)
        return newUser
    }
    
    // MARK: - Persistence
    
    private func saveCurrentUser() {
        guard let user = currentUser else { return }
        
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadCurrentUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            // 如果沒有儲存的使用者，先登入示例使用者
            login(user: User.sampleUser)
            return
        }
        
        self.currentUser = user
        self.isLoggedIn = true
    }
    
    private func clearCurrentUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - User Preferences
    
    func updatePreferences(_ preferences: UserPreferences) {
        guard var user = currentUser else { return }
        user.preferences = preferences
        updateUser(user)
    }
    
    func toggleFavoriteStore(_ storeId: UUID) {
        guard var user = currentUser else { return }
        
        if user.preferences.favoriteStores.contains(storeId) {
            user.preferences.favoriteStores.removeAll { $0 == storeId }
        } else {
            user.preferences.favoriteStores.append(storeId)
        }
        
        updateUser(user)
    }
    
    // MARK: - Order Participation
    
    func isParticipatingInOrder(_ order: GroupBuyOrder) -> Bool {
        guard let currentUser = currentUser else {
            return false
        }
        return order.participants.contains { $0.user.id == currentUser.id }
    }
    
    func canParticipateInOrder(_ order: GroupBuyOrder) -> Bool {
        // 檢查是否可以參加訂單
        guard order.status == .active else { return false }
        guard order.endTime > Date() else { return false }
        return !isParticipatingInOrder(order)
    }
    
    func getParticipationInOrder(_ order: GroupBuyOrder) -> Participant? {
        guard let currentUser = currentUser else { return nil }
        return order.participants.first { $0.user.id == currentUser.id }
    }
    
    // MARK: - Testing Helper
    static func createTestUser() -> UserManager {
        let userManager = UserManager()
        let testUser = User(name: "測試使用者", email: "testUser@example.com")
        userManager.login(user: testUser)
        return userManager
    }
}

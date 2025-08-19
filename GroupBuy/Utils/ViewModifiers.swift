//
//  ViewModifiers.swift
//  GroupBuy
//
//  Created by 林政佑 on 2025/8/19.
//

import SwiftUI

// MARK: - Dismiss Keyboard on Scroll Modifier
struct DismissKeyboardOnScrollModifier: ViewModifier {
    let focusBinding: FocusState<Bool>.Binding
    
    func body(content: Content) -> some View {
        content
            .onScrollPhaseChange { oldPhase, newPhase in
                // 當開始滾動時讓搜尋框失焦
                if newPhase == .animating || newPhase == .decelerating {
                    focusBinding.wrappedValue = false
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        // 當用戶開始拖拽滾動時立即讓搜尋框失焦
                        if focusBinding.wrappedValue {
                            focusBinding.wrappedValue = false
                        }
                    }
            )
    }
}

// MARK: - Dismiss Keyboard on Scroll (for regular Binding<Bool>)
struct DismissKeyboardOnScrollBindingModifier: ViewModifier {
    @Binding var isFieldFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .onScrollPhaseChange { oldPhase, newPhase in
                // 當開始滾動時讓搜尋框失焦
                if newPhase == .animating || newPhase == .decelerating {
                    isFieldFocused = false
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        // 當用戶開始拖拽滾動時立即讓搜尋框失焦
                        if isFieldFocused {
                            isFieldFocused = false
                        }
                    }
            )
    }
}

// MARK: - View Extensions
extension View {
    /// 在滾動時自動讓搜尋框失焦 (適用於 FocusState)
    func dismissKeyboardOnScroll(focus: FocusState<Bool>.Binding) -> some View {
        modifier(DismissKeyboardOnScrollModifier(focusBinding: focus))
    }
    
    /// 在滾動時自動讓搜尋框失焦 (適用於 Binding<Bool>)
    func dismissKeyboardOnScroll(isFieldFocused: Binding<Bool>) -> some View {
        modifier(DismissKeyboardOnScrollBindingModifier(isFieldFocused: isFieldFocused))
    }
}

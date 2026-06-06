//
//  AIChatIslandOverlay.swift
//  ExcalidrawZ
//
//  Created by Codex on 2026/06/05.
//

import SwiftUI
import ChocofordUI
#if os(iOS)
import UIKit
#endif

struct AIChatIslandOverlay: View {
    @Environment(\.containerHorizontalSizeClass) private var containerHorizontalSizeClass

    @EnvironmentObject private var layoutState: LayoutState
    @EnvironmentObject private var fileState: FileState
    @ObservedObject private var aiChatPreferences = AIChatPreferences.shared

    let canvasSize: CGSize
#if os(iOS)
    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardAnimationDuration: TimeInterval = 0.25
#endif

    private var isCompactIOS: Bool {
#if os(iOS)
        containerHorizontalSizeClass == .compact
#else
        false
#endif
    }

    private var isVisible: Bool {
        layoutState.isAIChatIslandMode &&
        AIChatAvailability.isAvailable &&
        aiChatPreferences.isAIEnabled &&
        !fileState.currentActiveFileIsInTrash
    }

    var body: some View {
        if isVisible {
#if os(iOS)
            if isCompactIOS {
                compactIOSOverlay
            } else {
                regularOverlay
            }
#else
            regularOverlay
#endif
        }
    }

    private var regularOverlay: some View {
        AIChatIslandView(canvasSize: canvasSize)
            .padding(.bottom, 24)
            .transition(.scale.combined(with: .opacity))
    }

#if os(iOS)
    private var compactIOSOverlay: some View {
        AIChatIslandView(canvasSize: canvasSize)
            .padding(.bottom, compactIOSBottomPadding)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeOut(duration: keyboardAnimationDuration), value: keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                updateKeyboardHeight(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
                updateKeyboardHeight(notification, isHiding: true)
            }
    }

    private var compactIOSBottomPadding: CGFloat {
        keyboardHeight > 0 ? keyboardHeight + 8 : 88
    }

    private func updateKeyboardHeight(_ notification: Notification, isHiding: Bool = false) {
        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            keyboardAnimationDuration = duration
        }

        guard !isHiding,
              let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            keyboardHeight = 0
            return
        }

        let screenHeight = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.height }
            .first ?? UIScreen.main.bounds.height
        keyboardHeight = max(0, screenHeight - frame.minY)
    }
#endif
}

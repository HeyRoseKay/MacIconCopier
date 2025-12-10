//
//  􀑋 MacIconCopierApp.swift
//  MacIconCopier
//
//  Created by Rose Kay on 7/11/25.
//

import SwiftUI

@main
struct MacIconCopierApp: App {
    @State private var iconManager = IconManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.iconManager, iconManager)
                .focusedSceneValue(\.clearImagesAction, iconManager.droppedIcons.isEmpty ? nil : iconManager.clearImages)
                .focusedSceneValue(\.copyToClipboardAction, iconManager.droppedIcons.isEmpty ? nil : iconManager.copyToClipboard)
        }
        .windowResizability(.contentSize)
        .windowLevel(.normal)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Clear Images") {
                    clearImagesAction?()
                }
                .keyboardShortcut("k", modifiers: .command)
                .disabled(clearImagesAction == nil)

                Button("Copy to Clipboard") {
                    copyToClipboardAction?()
                }
                .keyboardShortcut("c", modifiers: .command)
                .disabled(copyToClipboardAction == nil)
            }
        }
    }

    @FocusedValue(\.clearImagesAction) private var clearImagesAction
    @FocusedValue(\.copyToClipboardAction) private var copyToClipboardAction
}

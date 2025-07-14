//
//  IconManager.swift
//  MacIconCopier
//
//  Created by Rose Kay on 7/12/25.
//

import SwiftUI
import Observation

// MARK: - Icon Manager Environment
private struct IconManagerKey: EnvironmentKey {
    static let defaultValue = IconManager()
}

extension EnvironmentValues {
    var iconManager: IconManager {
        get { self[IconManagerKey.self] }
        set { self[IconManagerKey.self] = newValue }
    }
}

// MARK: - Focused Bindings for Commands
struct ClearImagesActionKey: FocusedValueKey {
    static var defaultValue: (() -> Void)? = nil
    typealias Value = () -> Void
}
extension FocusedValues {
    var clearImagesAction: (() -> Void)? {
        get { self[ClearImagesActionKey.self] }
        set { self[ClearImagesActionKey.self] = newValue }
    }
}

struct CopyToClipboardActionKey: FocusedValueKey {
    static var defaultValue: (() -> Void)? = nil
    typealias Value = () -> Void
}
extension FocusedValues {
    var copyToClipboardAction: (() -> Void)? {
        get { self[CopyToClipboardActionKey.self] }
        set { self[CopyToClipboardActionKey.self] = newValue }
    }
}

// MARK: - Icon Manager Observable
@Observable class IconManager {
    static let shared = IconManager()

    var droppedIcons: [NSImage] = []
    var iconURLs: [URL] = []

    func clearImages() {
        droppedIcons = []
        iconURLs = []
    }

    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(droppedIcons)
    }
}
//
//  SaveButton.swift
//  MacIconCopier
//
//  Created by Rose Kay on 7/11/25.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

// MARK: - Save Button
struct SaveButton: NSViewRepresentable {
    let images: [NSImage]
    let appURLs: [URL]
    let imageDimensions: CGFloat

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.title = "Save Icons"
        button.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.bezelStyle = .rounded
        button.target = context.coordinator
        button.action = #selector(Coordinator.saveAction)
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.images = images
        context.coordinator.appURLs = appURLs
        context.coordinator.imageDimensions = imageDimensions
        nsView.title = images.count == 1 ? "Save Icon" : "Save Icons"
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(images: images, appURLs: appURLs, imageDimensions: imageDimensions)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UNUserNotificationCenterDelegate {
        var images: [NSImage]
        var appURLs: [URL]
        var imageDimensions: CGFloat
        private var lastSavedFolderURL: URL?

        init(images: [NSImage], appURLs: [URL], imageDimensions: CGFloat) {
            self.images = images
            self.appURLs = appURLs
            self.imageDimensions = imageDimensions
            super.init()
            setupNotifications()
        }
        
        // MARK: - Notification Setup
        private func setupNotifications() {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    print("Notification authorization error: \(error)")
                }
            }
        }

        @objc func saveAction(_ sender: NSButton) {
            if images.count == 1 {
                showSaveDialog()
            } else {
                showBatchSaveDialog()
            }
        }
        
        // MARK: - Save Dialog Methods
        private func showSaveDialog() {
            let savePanel = NSSavePanel()
            
            savePanel.title = "Save Icon"
            savePanel.prompt = "Save"
            savePanel.allowedContentTypes = [.png]
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            
            let appName = appURLs.first?.deletingPathExtension().lastPathComponent ?? "App"
            savePanel.nameFieldStringValue = "\(appName)_Icon_\(Int(imageDimensions))x\(Int(imageDimensions)).png"
            
            if let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                savePanel.directoryURL = downloadsURL
            }
            
            savePanel.begin { response in
                guard response == .OK, let fileURL = savePanel.url else { return }
                self.saveImage(self.images[0], to: fileURL)
            }
        }
        
        private func showBatchSaveDialog() {
            let openPanel = NSOpenPanel()
            openPanel.title = "Choose Folder for Icons"
            openPanel.prompt = "Choose"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = true
            
            if let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                openPanel.directoryURL = downloadsURL
            }
            
            openPanel.begin { response in
                guard response == .OK, let folderURL = openPanel.url else { return }
                self.saveBatchImages(to: folderURL)
            }
        }
        
        // MARK: - Save Implementation
        private func saveBatchImages(to folderURL: URL) {
            for (index, image) in images.enumerated() {
                let appName = index < appURLs.count ? 
                    appURLs[index].deletingPathExtension().lastPathComponent : "App_\(index + 1)"
                let filename = "\(appName)_Icon_\(Int(imageDimensions))x\(Int(imageDimensions)).png"
                let fileURL = folderURL.appendingPathComponent(filename)
                
                saveImage(image, to: fileURL)
            }
            
            self.saveCompletion(folderURL: folderURL, savedCount: images.count)
        }
        
        private func saveImage(_ image: NSImage, to fileURL: URL) {
            image.size = NSSize(width: imageDimensions, height: imageDimensions)
            
            guard let rep = createUnscaledBitmapRep(for: image) else {
                print("Could not create unscaled bitmap representation")
                return
            }
            
            guard let pngData = rep.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
                print("Could not convert bitmap to PNG data")
                return
            }
            
            do {
                try pngData.write(to: fileURL)
                print("Icon saved to: \(fileURL.path)")
            } catch {
                print("Error saving icon: \(error.localizedDescription)")
            }
        }
        
        private func createUnscaledBitmapRep(for image: NSImage) -> NSBitmapImageRep? {
            guard let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(imageDimensions),
                pixelsHigh: Int(imageDimensions),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else {
                return nil
            }
            
            rep.size = NSSize(width: imageDimensions, height: imageDimensions)
            
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
            
            image.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1.0)
            
            NSGraphicsContext.restoreGraphicsState()
            
            return rep
        }
        
        // MARK: - Notification Methods
        private func saveCompletion(folderURL: URL, savedCount: Int) {
            lastSavedFolderURL = folderURL
            showSaveNotification(savedCount: savedCount, folderName: folderURL.lastPathComponent)
        }
        
        private func showSaveNotification(savedCount: Int, folderName: String) {
            let content = UNMutableNotificationContent()
            content.title = "Icons Saved Successfully"
            content.body = "Saved \(savedCount) icon\(savedCount == 1 ? "" : "s") to \(folderName)"
            content.sound = .default
            
            // Add action button
            let showInFinderAction = UNNotificationAction(
                identifier: "SHOW_IN_FINDER",
                title: "Show in Finder",
                options: [.foreground]
            )
            
            let category = UNNotificationCategory(
                identifier: "ICON_SAVED",
                actions: [showInFinderAction],
                intentIdentifiers: [],
                options: []
            )
            
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = "ICON_SAVED"
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error showing notification: \(error)")
                }
            }
        }
        
        // MARK: - UNUserNotificationCenterDelegate
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            
            if response.actionIdentifier == "SHOW_IN_FINDER", let folderURL = lastSavedFolderURL {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderURL.path)
            }
            
            completionHandler()
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            // Show notification even when app is in foreground
            completionHandler([.banner, .sound])
        }
    }
}

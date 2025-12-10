//
//  􀈂 ShareButton.swift
//  MacIconCopier
//
//  Created by Rose Kay on 7/11/25.
//

import AppKit
import SwiftUI

// MARK: - Share Button
struct ShareButton: NSViewRepresentable {
    let images: [NSImage]
    let appURLs: [URL]
    let imageDimensions: CGFloat

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.title = "Share Icons"
        button.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.bezelStyle = .rounded
        button.target = context.coordinator
        button.action = #selector(Coordinator.shareAction)
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.images = images
        context.coordinator.appURLs = appURLs
        context.coordinator.imageDimensions = imageDimensions
        nsView.title = images.count == 1 ? "Share Icon" : "Share Icons"
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(images: images, appURLs: appURLs, imageDimensions: imageDimensions)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject {
        var images: [NSImage]
        var appURLs: [URL]
        var imageDimensions: CGFloat

        init(images: [NSImage], appURLs: [URL], imageDimensions: CGFloat) {
            self.images = images
            self.appURLs = appURLs
            self.imageDimensions = imageDimensions
        }

        @objc func shareAction(_ sender: NSButton) {
            let tempURLs = createTemporaryFiles()
            let sharingServicePicker = NSSharingServicePicker(items: tempURLs)
            sharingServicePicker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
        
        // MARK: - Temporary File Creation
        private func createTemporaryFiles() -> [URL] {
            var tempURLs: [URL] = []
            let tempDirectory = FileManager.default.temporaryDirectory
            
            for (index, image) in images.enumerated() {
                let appName = index < appURLs.count ? 
                    appURLs[index].deletingPathExtension().lastPathComponent : "App_\(index + 1)"
                let filename = "\(appName)_Icon_\(Int(imageDimensions))x\(Int(imageDimensions)).png"
                let tempURL = tempDirectory.appendingPathComponent(filename)
                
                if saveImageToTempFile(image, to: tempURL) {
                    tempURLs.append(tempURL)
                }
            }
            
            return tempURLs
        }
        
        private func saveImageToTempFile(_ image: NSImage, to fileURL: URL) -> Bool {
            image.size = NSSize(width: imageDimensions, height: imageDimensions)
            
            guard let rep = createUnscaledBitmapRep(for: image) else {
                return false
            }
            
            guard let pngData = rep.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
                return false
            }
            
            do {
                try pngData.write(to: fileURL)
                return true
            } catch {
                return false
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
    }
}

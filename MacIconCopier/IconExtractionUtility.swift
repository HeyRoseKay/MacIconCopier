//
//  IconExtractionUtility.swift
//  MacIconCopier
//
//  Created by Rose Kay on 7/11/25.
//

import AppKit
import Foundation

// MARK: - Icon Extraction Utility
struct IconExtractionUtility {
    static func extractIcon(from url: URL, dimensions: CGFloat = 1024) -> NSImage? {
        print(" Extracting icon from: \(url.path)")
        print(" File extension: \(url.pathExtension)")
        
        let icon: NSImage?
        
        // Handle .app bundles
        if url.pathExtension == "app" {
            print(" Treating as .app bundle")
            icon = NSWorkspace.shared.icon(forFile: url.path)
        }
        // Handle image files directly
        else if ["png", "jpg", "jpeg", "gif", "bmp", "tiff"].contains(url.pathExtension.lowercased()) {
            print(" Treating as image file")
            icon = NSImage(contentsOf: url)
        }
        // Handle other file types
        else {
            print(" Treating as other file type")
            icon = NSWorkspace.shared.icon(forFile: url.path)
        }
        
        if let icon = icon {
            print(" Icon extracted successfully, setting size to \(dimensions)x\(dimensions)")
            // Set to specified dimensions
            icon.size = NSSize(width: dimensions, height: dimensions)
            return icon
        } else {
            print(" Failed to extract icon")
            return nil
        }
    }
}
//
//  DropToCopyIconView.swift
//  MacIconCopier
//
//  Created by Rose Kay on 7/11/25.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drop to Copy Icon View
struct DropToCopyIconView: View {
    @Environment(\.iconManager) var iconManager
    @State private var isTargeted = false
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0
    
    private let imageDimensions: CGFloat = 1024

    var body: some View {
        VStack {
            ZStack {
                // MARK: - Drop Zone
                dropZone

                // MARK: - Progress View
                if isProcessing {
                    progressView
                }
            }

            // MARK: - Action Buttons
            actionButtons
        }
        .padding(.bottom, 10)
        .padding()
    }
    
    // MARK: - Drop Zone
    private var dropZone: some View {
        ZStack {
            GlassEffectContainer {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 6, dash: [11]))
                    .foregroundColor(isTargeted ? .accentColor : .secondary)
                    .aspectRatio(1, contentMode: .fit)
                    .background(isTargeted ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))

            }.clipShape(RoundedRectangle(cornerRadius: 12))

            if let firstIcon = iconManager.droppedIcons.first {
                backgroundIconStack
                iconDisplay(firstIcon)
            } else {
                placeholderContent
            }
        }
        .scaleEffect(isTargeted ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTargeted)
        .onDrop(of: [
            UTType.fileURL.identifier,
            UTType.application.identifier,
            "com.apple.application-file",
            "public.file-url"
        ], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
        .contextMenu {
            if !iconManager.droppedIcons.isEmpty {
                contextMenuItems
            }
        }
    }

    // MARK: - Background Icon Stack
    private var backgroundIconStack: some View {
        ZStack {
            ForEach(Array(iconManager.droppedIcons.dropFirst().enumerated()), id: \.offset) { index, icon in
                backgroundIconDisplay(icon, layerIndex: index)
            }
        }
    }

    // MARK: - Icon Display
    private func iconDisplay(_ firstIcon: NSImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: firstIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            if iconManager.droppedIcons.count > 1 {
                Text("+\(iconManager.droppedIcons.count - 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                    .offset(x: -8, y: 8)
            }
        }
    }

    // MARK: - Background Icon Display
    private func backgroundIconDisplay(_ icon: NSImage, layerIndex: Int) -> some View {
        let maxBackgroundIcons = 100
        let maxCurrentItems = Double(min(maxBackgroundIcons - 1, iconManager.droppedIcons.count))
        let adjustedIndex = Double(min(layerIndex, maxBackgroundIcons - 1))

        let rotationAngle = (Double(adjustedIndex + 1) / maxCurrentItems) * 90
        let opacityValue = ((maxCurrentItems - Double(adjustedIndex)) / maxCurrentItems) * 0.69

        return Image(nsImage: icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .opacity(opacityValue)
            .rotationEffect(Angle(degrees: rotationAngle))
            .zIndex(-Double(adjustedIndex + 1))
    }

    // MARK: - Placeholder Content
    private var placeholderContent: some View {
        VStack {
            Image(systemName: "app.grid")
                .font(.system(size: 42))
                .foregroundColor(isTargeted ? .accentColor : .secondary)
                .padding(.bottom, 2)
            Text(isTargeted ? "Drop Now!" : "Drop Apps Here")
                .font(isTargeted ? .title2 : .body)
                .foregroundColor(isTargeted ? .accentColor : .secondary)
        }
    }

    // MARK: - Progress View
    private var progressView: some View {
        VStack {
            ProgressView(value: processingProgress)
                .progressViewStyle(LinearProgressViewStyle())
            Text("Thinking Really Hard...")
                .font(.title)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack {
            if !iconManager.droppedIcons.isEmpty {
                ShareButton(images: iconManager.droppedIcons, appURLs: iconManager.iconURLs, imageDimensions: imageDimensions)
                SaveButton(images: iconManager.droppedIcons, appURLs: iconManager.iconURLs, imageDimensions: imageDimensions)
            } else {
                Button("Share Icons") { }
                    .disabled(true)
                    .buttonStyle(.bordered)
                
                Button("Save Icons") { }
                    .disabled(true)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Context Menu Items
    private var contextMenuItems: some View {
        Group {
            Button(action: iconManager.clearImages) {
                Label("Clear Images", systemImage: "trash")
            }
            .keyboardShortcut("k", modifiers: [.command])
            
            Button(action: iconManager.copyToClipboard) {
                Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
            }
            .keyboardShortcut("c", modifiers: [.command])
        }
    }

    // MARK: - Drop Handler
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        isProcessing = true
        processingProgress = 0
        
        var newIcons: [NSImage] = []
        var newURLs: [URL] = []
        let group = DispatchGroup()
        
        let totalProviders = providers.count
        var processedCount = 0
        
        for provider in providers {
            group.enter()
            
            if provider.hasItemConformingToTypeIdentifier("com.apple.application-file") {
                provider.loadItem(forTypeIdentifier: "com.apple.application-file", options: nil) { (item, error) in
                    defer {
                        processedCount += 1
                        DispatchQueue.main.async {
                            self.processingProgress = Double(processedCount) / Double(totalProviders)
                        }
                        group.leave()
                    }
                    
                    guard error == nil else { return }
                    
                    if let url = item as? URL {
                        self.processURL(url, newIcons: &newIcons, newURLs: &newURLs)
                    } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        self.processURL(url, newIcons: &newIcons, newURLs: &newURLs)
                    }
                }
            } else if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    defer {
                        processedCount += 1
                        DispatchQueue.main.async {
                            self.processingProgress = Double(processedCount) / Double(totalProviders)
                        }
                        group.leave()
                    }
                    
                    guard error == nil, let url = url else { return }
                    self.processURL(url, newIcons: &newIcons, newURLs: &newURLs)
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    defer {
                        processedCount += 1
                        DispatchQueue.main.async {
                            self.processingProgress = Double(processedCount) / Double(totalProviders)
                        }
                        group.leave()
                    }
                    
                    guard error == nil else { return }
                    
                    if let url = item as? URL {
                        self.processURL(url, newIcons: &newIcons, newURLs: &newURLs)
                    } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        self.processURL(url, newIcons: &newIcons, newURLs: &newURLs)
                    }
                }
            } else {
                processedCount += 1
                DispatchQueue.main.async {
                    self.processingProgress = Double(processedCount) / Double(totalProviders)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            withObservationTracking {
                iconManager.droppedIcons = newIcons
                iconManager.iconURLs = newURLs
            } onChange: {
                print("Done")
            }
            self.isProcessing = false
        }
        
        return !providers.isEmpty
    }
    
    private func processURL(_ url: URL, newIcons: inout [NSImage], newURLs: inout [URL]) {
        if let icon = IconExtractionUtility.extractIcon(from: url, dimensions: self.imageDimensions) {
            newIcons.append(icon)
            newURLs.append(url)
        }
    }
}

//
//  AIChatAttachmentMenu.swift
//  ExcalidrawZ
//
//  Attachment source menu shared by the regular prompt input and the compact
//  iOS island input. It owns picker presentation and image decoding; callers
//  only decide whether images are allowed and where accepted images should go.
//

import SwiftUI
import ChocofordUI
import SFSafeSymbols
import UniformTypeIdentifiers

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if os(iOS)
import PhotosUI
#endif

struct AIChatAttachmentMenu<MenuLabel: View>: View {
    let canInsertImages: Bool
    @Binding var isFileImporterPresented: Bool
    let onBeginPickerPresentation: @MainActor () -> Void
    let onFilePickerDismiss: @MainActor () -> Void
    let onImagesPicked: @MainActor ([PendingPastedImage]) -> Void
    let onImageInputUnavailable: @MainActor () -> Void
    let label: () -> MenuLabel

#if os(iOS)
    @Binding var selectedPhotoPickerItems: [PhotosPickerItem]
    @Binding var isPhotoLibraryPickerPresented: Bool
    @Binding var isCameraPickerPresented: Bool
    let onPhotoPickerDismiss: @MainActor () -> Void
    let onCameraPickerDismiss: @MainActor () -> Void

    init(
        canInsertImages: Bool,
        isFileImporterPresented: Binding<Bool>,
        selectedPhotoPickerItems: Binding<[PhotosPickerItem]>,
        isPhotoLibraryPickerPresented: Binding<Bool>,
        isCameraPickerPresented: Binding<Bool>,
        onBeginPickerPresentation: @escaping @MainActor () -> Void = {},
        onFilePickerDismiss: @escaping @MainActor () -> Void = {},
        onPhotoPickerDismiss: @escaping @MainActor () -> Void = {},
        onCameraPickerDismiss: @escaping @MainActor () -> Void = {},
        onImagesPicked: @escaping @MainActor ([PendingPastedImage]) -> Void,
        onImageInputUnavailable: @escaping @MainActor () -> Void,
        @ViewBuilder label: @escaping () -> MenuLabel
    ) {
        self.canInsertImages = canInsertImages
        _isFileImporterPresented = isFileImporterPresented
        _selectedPhotoPickerItems = selectedPhotoPickerItems
        _isPhotoLibraryPickerPresented = isPhotoLibraryPickerPresented
        _isCameraPickerPresented = isCameraPickerPresented
        self.onBeginPickerPresentation = onBeginPickerPresentation
        self.onFilePickerDismiss = onFilePickerDismiss
        self.onPhotoPickerDismiss = onPhotoPickerDismiss
        self.onCameraPickerDismiss = onCameraPickerDismiss
        self.onImagesPicked = onImagesPicked
        self.onImageInputUnavailable = onImageInputUnavailable
        self.label = label
    }
#else
    init(
        canInsertImages: Bool,
        isFileImporterPresented: Binding<Bool>,
        onBeginPickerPresentation: @escaping @MainActor () -> Void = {},
        onFilePickerDismiss: @escaping @MainActor () -> Void = {},
        onImagesPicked: @escaping @MainActor ([PendingPastedImage]) -> Void,
        onImageInputUnavailable: @escaping @MainActor () -> Void,
        @ViewBuilder label: @escaping () -> MenuLabel
    ) {
        self.canInsertImages = canInsertImages
        _isFileImporterPresented = isFileImporterPresented
        self.onBeginPickerPresentation = onBeginPickerPresentation
        self.onFilePickerDismiss = onFilePickerDismiss
        self.onImagesPicked = onImagesPicked
        self.onImageInputUnavailable = onImageInputUnavailable
        self.label = label
    }
#endif

    var body: some View {
        ZStack {
            Menu {
                menuItems
            } label: {
                label()
            }
            .labelStyle(.iconOnly)
            .menuIndicator(.hidden)

#if os(iOS)
            Color.clear
                .frame(width: 0, height: 0)
                .photosPicker(
                    isPresented: $isPhotoLibraryPickerPresented,
                    selection: $selectedPhotoPickerItems,
                    matching: .images
                )
#endif
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            onFilePickerDismiss()
            handleFileImporterResult(result)
        }
#if os(iOS)
        .sheet(isPresented: $isCameraPickerPresented, onDismiss: onCameraPickerDismiss) {
            AIChatCameraImagePicker { image in
                handleCameraImage(image)
            }
            .ignoresSafeArea()
        }
        .watch(value: isPhotoLibraryPickerPresented) { _, isPresented in
            guard !isPresented else { return }
            onPhotoPickerDismiss()
        }
        .watch(value: selectedPhotoPickerItems.map(\.itemIdentifier)) { _ in
            handlePhotoPickerItems(selectedPhotoPickerItems)
        }
#endif
    }

    @ViewBuilder
    private var menuItems: some View {
#if os(iOS)
        Button {
            onBeginPickerPresentation()
            isFileImporterPresented = true
        } label: {
            Label(.localizable(.exportSheetButtonFile), systemSymbol: .doc)
        }
        .disabled(!canInsertImages)

        Button {
            presentPhotoLibraryPicker()
        } label: {
            Label(.localizable(.aiChatInputAttachmentMenuItemPhotoLibrary), systemSymbol: .photoOnRectangle)
        }
        .disabled(!canInsertImages)

        Button {
            presentCameraPicker()
        } label: {
            Label(.localizable(.aiChatInputAttachmentMenuItemCamera), systemSymbol: .camera)
        }
        .disabled(
            !canInsertImages ||
            !UIImagePickerController.isSourceTypeAvailable(.camera)
        )
#else
        Button {
            onBeginPickerPresentation()
            isFileImporterPresented = true
        } label: {
            Label(.localizable(.aiChatInputAttachmentMenuItemImage), systemSymbol: .photo)
        }
        .disabled(!canInsertImages)
#endif
    }

    @MainActor
    private func handleFileImporterResult(_ result: Result<[URL], Error>) {
        guard canInsertImages else {
            onImageInputUnavailable()
            return
        }
        guard case .success(let urls) = result else { return }
        appendImages(urls.compactMap(AIChatAttachmentFileImporter.pendingImage))
    }

    @MainActor
    private func appendImages(_ images: [PendingPastedImage]) {
        guard !images.isEmpty else { return }
        guard canInsertImages else {
            onImageInputUnavailable()
            return
        }
        onImagesPicked(images)
    }

#if os(iOS)
    @MainActor
    private func presentPhotoLibraryPicker() {
        onBeginPickerPresentation()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard canInsertImages else {
                onImageInputUnavailable()
                onPhotoPickerDismiss()
                return
            }
            isPhotoLibraryPickerPresented = true
        }
    }

    @MainActor
    private func presentCameraPicker() {
        onBeginPickerPresentation()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard canInsertImages,
                  UIImagePickerController.isSourceTypeAvailable(.camera)
            else {
                onImageInputUnavailable()
                onCameraPickerDismiss()
                return
            }
            isCameraPickerPresented = true
        }
    }

    @MainActor
    private func handlePhotoPickerItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        guard canInsertImages else {
            selectedPhotoPickerItems = []
            onImageInputUnavailable()
            return
        }

        Task {
            let images = await AIChatAttachmentImageImporter.pendingImages(from: items)
            await MainActor.run {
                appendImages(images)
                selectedPhotoPickerItems = []
            }
        }
    }

    @MainActor
    private func handleCameraImage(_ image: UIImage?) {
        guard let image else { return }
        appendImages([
            AIChatAttachmentImageImporter.pendingImage(from: image)
        ])
    }
#endif
}

private enum AIChatAttachmentFileImporter {
    static func pendingImage(from url: URL) -> PendingPastedImage? {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }

#if canImport(AppKit)
        guard let image = NSImage(contentsOf: url) else { return nil }
        return PendingPastedImage(id: UUID(), image: image)
#elseif canImport(UIKit)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data)
        else { return nil }
        return PendingPastedImage(id: UUID(), image: image)
#else
        return nil
#endif
    }
}

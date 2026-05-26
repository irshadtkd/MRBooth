//
//  ScanView.swift
//  MRBooth
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ScanView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = ScanViewModel()
    @State private var showCamera = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showDocumentPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scanOptions
                if viewModel.showReview {
                    reviewSection
                }
            }
            .padding(AppTheme.paddingMedium)
        }
        .background(AppTheme.background)
        .navigationTitle(AppStrings.scanTitle)
        .loadingOverlay(viewModel.isProcessing, message: AppStrings.processingOCR)
        .loadingOverlay(viewModel.isSaving, message: AppStrings.savingToSheet)
        .errorAlert(error: $viewModel.activeError)
        #if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { data in
                showCamera = false
                Task { await viewModel.processImage(data: data, coordinator: coordinator) }
            } onCancel: { showCamera = false }
        }
        #endif
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.processImage(data: data, coordinator: coordinator)
                }
            }
        }
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task { await viewModel.processFile(url: url, coordinator: coordinator) }
            }
        }
    }

    private var scanOptions: some View {
        VStack(spacing: 12) {
            #if os(iOS)
            Button { showCamera = true } label: {
                Label(AppStrings.cameraScan, systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary.opacity(0.1))
                    .foregroundStyle(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            }
            #endif
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(AppStrings.uploadImage, systemImage: "photo.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.secondary.opacity(0.1))
                    .foregroundStyle(AppTheme.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            }
            Button { showDocumentPicker = true } label: {
                Label(AppStrings.uploadPDF, systemImage: "doc.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent.opacity(0.1))
                    .foregroundStyle(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            }
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.reviewExtracted)
                .font(AppFonts.headline())
            ForEach(viewModel.drafts) { draft in
                scanDraftRow(draft: draft)
            }
            HStack(spacing: 12) {
                Button(AppStrings.discardScan) {
                    viewModel.discard()
                }
                .secondaryButtonStyle()
                Button(AppStrings.saveToSheet) {
                    Task { await viewModel.saveSelected(coordinator: coordinator) }
                }
                .primaryButtonStyle()
            }
        }
        .cardStyle()
    }

    private func scanDraftRow(draft: ScanDraft) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle(
                "",
                isOn: Binding(
                    get: { viewModel.isDraftSelected(id: draft.id) },
                    set: { viewModel.setDraftSelected(id: draft.id, isSelected: $0) }
                )
            )
            .labelsHidden()
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.voter.name)
                    .font(AppFonts.subheadline(.semibold))
                Text(draft.voter.voterID)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppTheme.textSecondary)
                if draft.isDuplicate {
                    Text(AppStrings.duplicateVoter)
                        .font(AppFonts.caption2(.bold))
                        .foregroundStyle(AppTheme.error)
                }
                if !draft.voter.missingFields.isEmpty {
                    Text("\(AppStrings.missingFields): \(draft.voter.missingFields.joined(separator: ", "))")
                        .font(AppFonts.caption2())
                        .foregroundStyle(AppTheme.warning)
                }
            }
        }
        .padding(8)
        .background(AppTheme.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
    }
}

#if os(iOS)
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        init(_ parent: CameraCaptureView) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.85) {
                parent.onCapture(data)
            } else {
                parent.onCancel()
            }
        }
    }
}
#endif

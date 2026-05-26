//
//  ScanViewModel.swift
//  MRBooth
//

import Foundation

@MainActor
final class ScanViewModel: ObservableObject, ErrorPresenting {
    @Published var drafts: [ScanDraft] = []
    @Published var isProcessing = false
    @Published var isSaving = false
    @Published var showReview = false
    @Published var activeError: AppError?

    func processImage(data: Data, coordinator: AppCoordinator) async {
        guard coordinator.services.sessionStore.loadGeminiAPIKey() != nil else {
            present(.validationFailed(AppStrings.geminiAPIKeyMissing))
            return
        }
        isProcessing = true
        defer { isProcessing = false }
        do {
            let extracted = try await coordinator.services.ocrService.extractVoters(from: data)
            drafts = extracted.map { voter in
                ScanDraft(
                    voter: voter,
                    isDuplicate: coordinator.services.voterRepository.isDuplicate(voterID: voter.voterID)
                )
            }
            showReview = !drafts.isEmpty
            if drafts.isEmpty {
                present(.ocrFailed("No voter rows found. Try a clearer image or PDF page."))
            }
        } catch {
            handle(error)
        }
    }

    func processFile(url: URL, coordinator: AppCoordinator) async {
        guard coordinator.services.sessionStore.loadGeminiAPIKey() != nil else {
            present(.validationFailed(AppStrings.geminiAPIKeyMissing))
            return
        }
        isProcessing = true
        defer { isProcessing = false }
        do {
            let extracted = try await coordinator.services.ocrService.extractVoters(from: url)
            drafts = extracted.map { voter in
                ScanDraft(
                    voter: voter,
                    isDuplicate: coordinator.services.voterRepository.isDuplicate(voterID: voter.voterID)
                )
            }
            showReview = !drafts.isEmpty
            if drafts.isEmpty {
                present(.ocrFailed("No voter rows found. Try a clearer image or PDF page."))
            }
        } catch {
            handle(error)
        }
    }

    func saveSelected(coordinator: AppCoordinator) async {
        guard let session = coordinator.session else {
            present(.notAuthenticated)
            return
        }
        let selected = drafts.filter(\.isSelected).map(\.voter)
        guard !selected.isEmpty else {
            present(.validationFailed("Select at least one voter to save"))
            return
        }
        let duplicates = selected.filter { coordinator.services.voterRepository.isDuplicate(voterID: $0.voterID) && !$0.voterID.isEmpty }
        if !duplicates.isEmpty {
            present(.duplicateVoter(duplicates.first?.voterID ?? ""))
            return
        }

        // Remove review UI before async work so ForEach is not active during save.
        showReview = false
        drafts = []

        isSaving = true
        defer { isSaving = false }
        do {
            try await coordinator.services.voterRepository.addVoters(selected, session: session)
        } catch {
            handle(error)
        }
    }

    func discard() {
        showReview = false
        drafts = []
    }

    func setDraftSelected(id: String, isSelected: Bool) {
        guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts[index].isSelected = isSelected
    }

    func isDraftSelected(id: String) -> Bool {
        drafts.first(where: { $0.id == id })?.isSelected ?? false
    }
}

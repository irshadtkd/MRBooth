//
//  EditVoterViewModel.swift
//  MRBooth
//

import Foundation

@MainActor
final class EditVoterViewModel: ObservableObject, ErrorPresenting {
    @Published var voter: Voter
    @Published var isSaving = false
    @Published var activeError: AppError?
    @Published var didSave = false

    init(voter: Voter) {
        self.voter = voter
    }

    func save(coordinator: AppCoordinator) async {
        if voter.name.trimmingCharacters(in: .whitespaces).isEmpty {
            present(.validationFailed("Name is required"))
            return
        }
        if coordinator.services.voterRepository.isDuplicate(voterID: voter.voterID, excluding: voter.id) {
            present(.duplicateVoter(voter.voterID))
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await coordinator.services.voterRepository.update(voter, session: coordinator.session!)
            didSave = true
        } catch {
            handle(error)
        }
    }
}

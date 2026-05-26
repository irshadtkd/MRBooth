//
//  RegistrationViewModel.swift
//  MRBooth
//

import Foundation

@MainActor
final class RegistrationViewModel: ObservableObject, ErrorPresenting {
    @Published var electionLevel: ElectionLevel = .localBody {
        didSet {
            guard !isApplyingDraft else { return }
            onElectionLevelChanged(from: oldValue)
        }
    }
    @Published var district = "" {
        didSet {
            guard !isApplyingDraft else { return }
            onDistrictChanged()
        }
    }
    @Published var areaName = "" {
        didSet {
            guard !isApplyingDraft else { return }
            onAreaNameChanged()
        }
    }
    @Published var ward = ""
    @Published var boothNumber = ""
    @Published var isSubmitting = false
    @Published var showSheetChoiceDialog = false
    @Published var pendingSheetLink: PendingSheetLinkContext?
    @Published var activeError: AppError?

    private var isApplyingDraft = false

    var districtOptions: [String] {
        KeralaElectionCatalog.districts(for: electionLevel)
    }

    var areaOptions: [String] {
        KeralaElectionCatalog.areaOptions(level: electionLevel, district: district)
    }

    var wardOptions: [String] {
        guard electionLevel == .localBody, !district.isEmpty, !areaName.isEmpty else { return [] }
        return KeralaElectionCatalog.wards(district: district, localBodyDisplayName: areaName)
    }

    var areaPickerTitle: String {
        KeralaElectionCatalog.areaPickerTitle(for: electionLevel)
    }

    var areaPickerPlaceholder: String {
        KeralaElectionCatalog.areaPickerPlaceholder(for: electionLevel)
    }

    var isValid: Bool {
        guard !district.isEmpty, !areaName.isEmpty, !boothNumber.isEmpty else { return false }
        switch electionLevel {
        case .lokSabha, .assembly:
            return true
        case .localBody:
            return !ward.isEmpty
        }
    }

    private func onElectionLevelChanged(from previous: ElectionLevel) {
        guard previous != electionLevel else { return }
        district = ""
        areaName = ""
        ward = ""
    }

    private func onDistrictChanged() {
        if !areaOptions.contains(areaName) {
            areaName = ""
        }
        onAreaNameChanged()
    }

    private func onAreaNameChanged() {
        if !wardOptions.contains(ward) {
            ward = ""
        }
    }

    func applySaved(from coordinator: AppCoordinator) {
        if let booth = coordinator.session?.booth {
            apply(draft: RegistrationDraft(booth: booth))
            return
        }
        if let draft = coordinator.services.sessionStore.loadRegistrationDraft() {
            apply(draft: draft)
        }
    }

    func persistDraft(using coordinator: AppCoordinator) {
        guard coordinator.session?.hasActiveRegistration != true else { return }
        coordinator.services.sessionStore.saveRegistrationDraft(currentDraft())
    }

    func submit(coordinator: AppCoordinator) async {
        guard coordinator.session?.isLoggedIn == true else {
            coordinator.phase = .login
            return
        }
        if coordinator.session?.hasActiveRegistration == true {
            coordinator.phase = .main
            return
        }
        guard isValid else {
            present(.validationFailed(validationMessage))
            return
        }
        persistDraft(using: coordinator)
        isSubmitting = true
        defer { isSubmitting = false }
        let pending = await coordinator.registerBooth(draft: currentDraft())
        if let pending {
            pendingSheetLink = pending
            showSheetChoiceDialog = true
        } else if let error = coordinator.activeError {
            present(error)
        }
    }

    func reuseExistingSheet(coordinator: AppCoordinator) async {
        guard let pending = pendingSheetLink else { return }
        showSheetChoiceDialog = false
        isSubmitting = true
        defer {
            isSubmitting = false
            pendingSheetLink = nil
        }
        await coordinator.completeBoothRegistration(choice: .reuseExisting, pending: pending)
        if let error = coordinator.activeError {
            present(error)
        }
    }

    func createNewSheet(coordinator: AppCoordinator) async {
        guard let pending = pendingSheetLink else { return }
        showSheetChoiceDialog = false
        isSubmitting = true
        defer {
            isSubmitting = false
            pendingSheetLink = nil
        }
        await coordinator.completeBoothRegistration(choice: .createNew, pending: pending)
        if let error = coordinator.activeError {
            present(error)
        }
    }

    func cancelSheetChoice() {
        showSheetChoiceDialog = false
        pendingSheetLink = nil
    }

    private var validationMessage: String {
        switch electionLevel {
        case .lokSabha:
            return AppStrings.registrationValidationLokSabha
        case .assembly:
            return AppStrings.registrationValidationAssembly
        case .localBody:
            return AppStrings.registrationValidationLocalBody
        }
    }

    private func apply(draft: RegistrationDraft) {
        isApplyingDraft = true
        defer { isApplyingDraft = false }
        electionLevel = draft.electionLevel
        district = draft.district
        if draft.electionLevel == .localBody, let kind = draft.localBodyKind {
            areaName = "\(draft.areaName) (\(kind.rawValue))"
        } else {
            areaName = draft.areaName
        }
        ward = draft.ward
        boothNumber = draft.boothNumber
    }

    private func currentDraft() -> RegistrationDraft {
        let localBodyKind: LocalBodyKind?
        if electionLevel == .localBody {
            localBodyKind = KeralaElectionCatalog.parseLocalBodyDisplay(areaName)?.kind
        } else {
            localBodyKind = nil
        }
        return RegistrationDraft(
            state: KeralaElectionCatalog.state,
            electionLevel: electionLevel,
            district: district,
            areaName: electionLevel == .localBody
                ? (KeralaElectionCatalog.parseLocalBodyDisplay(areaName)?.name ?? areaName)
                : areaName,
            localBodyKind: localBodyKind,
            ward: ward,
            boothNumber: boothNumber
        )
    }
}

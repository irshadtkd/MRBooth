//
//  RegistrationView.swift
//  MRBooth
//

import SwiftUI

struct RegistrationView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = RegistrationViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                electionLevelPicker
                form
                submitButton
            }
            .padding(AppTheme.paddingLarge)
        }
        .background(AppTheme.background)
        .onAppear {
            guard let session = coordinator.session else {
                coordinator.phase = .login
                return
            }
            if session.hasActiveRegistration {
                coordinator.phase = .main
                return
            }
            guard session.isLoggedIn else {
                coordinator.phase = .login
                return
            }
            viewModel.applySaved(from: coordinator)
        }
        .onChange(of: viewModel.electionLevel) { _, _ in viewModel.persistDraft(using: coordinator) }
        .onChange(of: viewModel.district) { _, _ in viewModel.persistDraft(using: coordinator) }
        .onChange(of: viewModel.areaName) { _, _ in viewModel.persistDraft(using: coordinator) }
        .onChange(of: viewModel.ward) { _, _ in viewModel.persistDraft(using: coordinator) }
        .onChange(of: viewModel.boothNumber) { _, _ in viewModel.persistDraft(using: coordinator) }
        .errorAlert(error: $viewModel.activeError)
        .loadingOverlay(viewModel.isSubmitting, message: AppStrings.registeringBooth)
        .confirmationDialog(
            AppStrings.existingSheetTitle,
            isPresented: $viewModel.showSheetChoiceDialog,
            titleVisibility: .visible
        ) {
            Button(AppStrings.reuseExistingSheet) {
                Task { await viewModel.reuseExistingSheet(coordinator: coordinator) }
            }
            Button(AppStrings.createNewSheet) {
                Task { await viewModel.createNewSheet(coordinator: coordinator) }
            }
            Button(AppStrings.cancel, role: .cancel) {
                viewModel.cancelSheetChoice()
            }
        } message: {
            Text(AppStrings.existingSheetMessage)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppStrings.registrationTitle)
                .font(AppFonts.title2())
                .foregroundStyle(AppTheme.textPrimary)
            Text(AppStrings.registrationSubtitle)
                .font(AppFonts.subheadline())
                .foregroundStyle(AppTheme.warning)
            Text(AppStrings.drivePermissionNote)
                .font(AppFonts.caption())
                .foregroundStyle(AppTheme.info)
            if let email = coordinator.session?.email {
                Text(email)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private var electionLevelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppStrings.electionLevel)
                .font(AppFonts.caption(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Picker(AppStrings.electionLevel, selection: $viewModel.electionLevel) {
                Text(AppStrings.lokSabha).tag(ElectionLevel.lokSabha)
                Text(AppStrings.assembly).tag(ElectionLevel.assembly)
                Text(AppStrings.localBody).tag(ElectionLevel.localBody)
            }
            .pickerStyle(.segmented)
        }
    }

    private var form: some View {
        VStack(spacing: 16) {
            MRBoothTextField(
                title: AppStrings.state,
                text: .constant(KeralaElectionCatalog.state)
            )
            .disabled(true)
            .opacity(0.85)

            MRBoothPicker(
                title: AppStrings.district,
                selection: $viewModel.district,
                options: viewModel.districtOptions,
                placeholder: AppStrings.selectDistrict
            )

            MRBoothPicker(
                title: viewModel.areaPickerTitle,
                selection: $viewModel.areaName,
                options: viewModel.areaOptions,
                placeholder: viewModel.areaPickerPlaceholder,
                isEnabled: !viewModel.district.isEmpty
            )

            if viewModel.electionLevel == .localBody {
                MRBoothPicker(
                    title: AppStrings.ward,
                    selection: $viewModel.ward,
                    options: viewModel.wardOptions,
                    placeholder: AppStrings.selectWard,
                    isEnabled: !viewModel.areaName.isEmpty
                )
            }

            MRBoothTextField(title: AppStrings.boothNumber, text: $viewModel.boothNumber, isNumeric: true)

            Text(AppStrings.registrationNote)
                .font(AppFonts.caption())
                .foregroundStyle(AppTheme.textSecondary)
        }
        .cardStyle()
    }

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit(coordinator: coordinator) }
        } label: {
            Text(AppStrings.submitRegistration)
                .primaryButtonStyle()
        }
        .disabled(!viewModel.isValid)
        .opacity(viewModel.isValid ? 1 : 0.5)
    }
}

#Preview {
    RegistrationView(coordinator: AppCoordinator())
}

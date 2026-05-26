//
//  SettingsView.swift
//  MRBooth
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var isSyncing = false
    @State private var isClearing = false
    @State private var showClearDataConfirm = false
    @State private var clearDataAfterDismiss = false
    @State private var showLogoutConfirm = false
    @State private var logoutAfterDismiss = false
    @State private var geminiAPIKey = ""
    @State private var geminiKeySaved = false

    var body: some View {
        List {
            Section(AppStrings.geminiAPIKeySection) {
                SecureField(AppStrings.geminiAPIKeyPlaceholder, text: $geminiAPIKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                Text(AppStrings.geminiAPIKeyHelp)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppTheme.textSecondary)
                Button(AppStrings.saveGeminiAPIKey) {
                    coordinator.services.sessionStore.saveGeminiAPIKey(geminiAPIKey)
                    geminiKeySaved = true
                }
                .disabled(geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if geminiKeySaved {
                    Text(AppStrings.geminiAPIKeySaved)
                        .font(AppFonts.caption())
                        .foregroundStyle(AppTheme.secondary)
                }
            }
            if let booth = coordinator.session?.booth {
                Section(AppStrings.boothInfo) {
                    LabeledContent(AppStrings.electionLevelLabel, value: booth.electionLevel.rawValue)
                    LabeledContent(AppStrings.state, value: booth.state)
                    LabeledContent(AppStrings.district, value: booth.district)
                    LabeledContent(
                        booth.electionLevel == .localBody ? AppStrings.localBody : AppStrings.constituency,
                        value: booth.areaName
                    )
                    if booth.electionLevel == .localBody, !booth.ward.isEmpty {
                        LabeledContent(AppStrings.ward, value: booth.ward)
                    }
                    LabeledContent(AppStrings.boothNumber, value: booth.boothNumber)
                    LabeledContent("Email", value: booth.userEmail)
                }
            }
            Section {
                Button {
                    Task {
                        isSyncing = true
                        await coordinator.syncData()
                        isSyncing = false
                    }
                } label: {
                    HStack {
                        Label(AppStrings.syncData, systemImage: "arrow.triangle.2.circlepath")
                        if isSyncing { Spacer(); ProgressView() }
                    }
                }
                .disabled(isSyncing)
                if let synced = coordinator.services.voterRepository.lastSyncedAt {
                    Text("\(AppStrings.lastSynced): \(synced.formatted(date: .abbreviated, time: .shortened))")
                        .font(AppFonts.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text(AppStrings.neverSynced)
                        .font(AppFonts.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            if coordinator.session?.hasActiveRegistration == true {
                Section {
                    Button(role: .destructive) {
                        showClearDataConfirm = true
                    } label: {
                        HStack {
                            Label(AppStrings.clearData, systemImage: "trash")
                            if isClearing { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(isClearing || isSyncing)
                }
            }
            Section {
                Button(role: .destructive) {
                    showLogoutConfirm = true
                } label: {
                    Label(AppStrings.logout, systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.textPrimary)
        .navigationTitle(AppStrings.settingsTitle)
        .onAppear {
            if let existing = coordinator.services.sessionStore.loadGeminiAPIKey() {
                geminiAPIKey = existing
            }
        }
        .confirmationDialog(AppStrings.clearDataConfirmTitle, isPresented: $showClearDataConfirm) {
            Button(AppStrings.clearDataConfirmAction, role: .destructive) {
                clearDataAfterDismiss = true
                showClearDataConfirm = false
            }
            Button(AppStrings.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.clearDataConfirmMessage)
        }
        .confirmationDialog(AppStrings.logout, isPresented: $showLogoutConfirm) {
            Button(AppStrings.logout, role: .destructive) {
                logoutAfterDismiss = true
                showLogoutConfirm = false
            }
            Button(AppStrings.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.logoutConfirm)
        }
        .onChange(of: showClearDataConfirm) { _, isPresented in
            guard !isPresented, clearDataAfterDismiss else { return }
            clearDataAfterDismiss = false
            Task { await runClearData() }
        }
        .onChange(of: showLogoutConfirm) { _, isPresented in
            guard !isPresented, logoutAfterDismiss else { return }
            logoutAfterDismiss = false
            Task { await coordinator.signOut() }
        }
    }

    private func runClearData() async {
        isClearing = true
        defer { isClearing = false }
        await coordinator.clearAllVoterData()
    }
}

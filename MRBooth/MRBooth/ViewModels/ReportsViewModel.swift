//
//  ReportsViewModel.swift
//  MRBooth
//

import Foundation

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var partyItems: [PartyReportItem] = []
    @Published var stats = DashboardStats()

    func refresh(repository: VoterRepository) {
        partyItems = repository.partyReport()
        stats = repository.dashboardStats()
    }
}

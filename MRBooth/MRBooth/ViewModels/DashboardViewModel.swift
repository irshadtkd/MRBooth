//
//  DashboardViewModel.swift
//  MRBooth
//

import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var stats = DashboardStats()

    func refresh(from repository: VoterRepository) {
        stats = repository.dashboardStats()
    }
}

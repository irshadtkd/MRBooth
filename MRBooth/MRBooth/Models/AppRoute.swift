//
//  AppRoute.swift
//  MRBooth
//

import Foundation

enum AppRoute: Hashable {
    case scan
    case voterList
    case filters
    case editVoter(Voter)
    case reports
    case settings
}

enum AppPhase: Equatable {
    case splash
    case login
    case registration
    case main
}

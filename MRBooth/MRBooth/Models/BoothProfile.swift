//
//  BoothProfile.swift
//  MRBooth
//

import Foundation

struct BoothProfile: Codable, Equatable {
    var state: String
    var electionLevel: ElectionLevel
    var district: String
    var areaName: String
    var localBodyKind: LocalBodyKind?
    var ward: String
    var boothNumber: String
    var userEmail: String
    var driveFolderID: String?
    var sheetID: String?
    var registeredAt: Date

    /// Legacy field — decoded for older sessions; not written on new registrations.
    private var panchayath: String?

    var boothName: String {
        switch electionLevel {
        case .localBody:
            let wardPart = ward.isEmpty ? "" : "_\(ward)"
            return "Booth_\(boothNumber)\(wardPart)_\(areaName)"
        case .lokSabha, .assembly:
            return "Booth_\(boothNumber)_\(areaName)"
        }
    }

    var displayLocation: String {
        switch electionLevel {
        case .lokSabha:
            return "\(areaName) (Lok Sabha), \(district), \(state)"
        case .assembly:
            return "\(areaName) (Assembly), \(district), \(state)"
        case .localBody:
            let kind = localBodyKind?.rawValue ?? "Local Body"
            if ward.isEmpty {
                return "\(areaName) (\(kind)), \(district), \(state)"
            }
            return "\(areaName), Ward \(ward) (\(kind)), \(district), \(state)"
        }
    }

    var isRegistrationComplete: Bool {
        guard !district.isEmpty, !areaName.isEmpty, !boothNumber.isEmpty else { return false }
        switch electionLevel {
        case .lokSabha, .assembly:
            return true
        case .localBody:
            return !ward.isEmpty
        }
    }

    static let sampleDistricts = [
        "Thiruvananthapuram", "Kollam", "Pathanamthitta", "Alappuzha",
        "Kottayam", "Idukki", "Ernakulam", "Thrissur", "Palakkad",
        "Malappuram", "Kozhikode", "Wayanad", "Kannur", "Kasaragod"
    ]

    init(
        state: String = KeralaElectionCatalog.state,
        electionLevel: ElectionLevel = .localBody,
        district: String,
        areaName: String,
        localBodyKind: LocalBodyKind? = nil,
        ward: String = "",
        boothNumber: String,
        userEmail: String,
        driveFolderID: String? = nil,
        sheetID: String? = nil,
        registeredAt: Date = Date()
    ) {
        self.state = state
        self.electionLevel = electionLevel
        self.district = district
        self.areaName = areaName
        self.localBodyKind = localBodyKind
        self.ward = ward
        self.boothNumber = boothNumber
        self.userEmail = userEmail
        self.driveFolderID = driveFolderID
        self.sheetID = sheetID
        self.registeredAt = registeredAt
    }

    enum CodingKeys: String, CodingKey {
        case state, electionLevel, district, areaName, localBodyKind, ward, boothNumber
        case userEmail, driveFolderID, sheetID, registeredAt, panchayath
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        state = try c.decodeIfPresent(String.self, forKey: .state) ?? KeralaElectionCatalog.state
        electionLevel = try c.decodeIfPresent(ElectionLevel.self, forKey: .electionLevel) ?? .localBody
        district = try c.decodeIfPresent(String.self, forKey: .district) ?? ""
        let legacyPanchayath = try c.decodeIfPresent(String.self, forKey: .panchayath) ?? ""
        areaName = try c.decodeIfPresent(String.self, forKey: .areaName)
            ?? (legacyPanchayath.isEmpty ? "" : legacyPanchayath)
        localBodyKind = try c.decodeIfPresent(LocalBodyKind.self, forKey: .localBodyKind)
        ward = try c.decodeIfPresent(String.self, forKey: .ward) ?? ""
        boothNumber = try c.decodeIfPresent(String.self, forKey: .boothNumber) ?? ""
        userEmail = try c.decode(String.self, forKey: .userEmail)
        driveFolderID = try c.decodeIfPresent(String.self, forKey: .driveFolderID)
        sheetID = try c.decodeIfPresent(String.self, forKey: .sheetID)
        registeredAt = try c.decodeIfPresent(Date.self, forKey: .registeredAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(state, forKey: .state)
        try c.encode(electionLevel, forKey: .electionLevel)
        try c.encode(district, forKey: .district)
        try c.encode(areaName, forKey: .areaName)
        try c.encodeIfPresent(localBodyKind, forKey: .localBodyKind)
        try c.encode(ward, forKey: .ward)
        try c.encode(boothNumber, forKey: .boothNumber)
        try c.encode(userEmail, forKey: .userEmail)
        try c.encodeIfPresent(driveFolderID, forKey: .driveFolderID)
        try c.encodeIfPresent(sheetID, forKey: .sheetID)
        try c.encode(registeredAt, forKey: .registeredAt)
    }
}

/// In-progress booth registration fields (UserDefaults), used before submit completes.
struct RegistrationDraft: Codable, Equatable {
    var state: String
    var electionLevel: ElectionLevel
    var district: String
    var areaName: String
    var localBodyKind: LocalBodyKind?
    var ward: String
    var boothNumber: String

    init(
        state: String = KeralaElectionCatalog.state,
        electionLevel: ElectionLevel = .localBody,
        district: String = "",
        areaName: String = "",
        localBodyKind: LocalBodyKind? = nil,
        ward: String = "",
        boothNumber: String = ""
    ) {
        self.state = state
        self.electionLevel = electionLevel
        self.district = district
        self.areaName = areaName
        self.localBodyKind = localBodyKind
        self.ward = ward
        self.boothNumber = boothNumber
    }

    init(booth: BoothProfile) {
        state = booth.state
        electionLevel = booth.electionLevel
        district = booth.district
        areaName = booth.areaName
        localBodyKind = booth.localBodyKind
        ward = booth.ward
        boothNumber = booth.boothNumber
    }

    func toBoothProfile(userEmail: String) -> BoothProfile {
        BoothProfile(
            state: state,
            electionLevel: electionLevel,
            district: district,
            areaName: areaName,
            localBodyKind: localBodyKind,
            ward: ward,
            boothNumber: boothNumber,
            userEmail: userEmail
        )
    }

    enum CodingKeys: String, CodingKey {
        case state, electionLevel, district, areaName, localBodyKind, ward, boothNumber, panchayath
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        state = try c.decodeIfPresent(String.self, forKey: .state) ?? KeralaElectionCatalog.state
        electionLevel = try c.decodeIfPresent(ElectionLevel.self, forKey: .electionLevel) ?? .localBody
        district = try c.decodeIfPresent(String.self, forKey: .district) ?? ""
        let legacyPanchayath = try c.decodeIfPresent(String.self, forKey: .panchayath) ?? ""
        areaName = try c.decodeIfPresent(String.self, forKey: .areaName)
            ?? (legacyPanchayath.isEmpty ? "" : legacyPanchayath)
        localBodyKind = try c.decodeIfPresent(LocalBodyKind.self, forKey: .localBodyKind)
        ward = try c.decodeIfPresent(String.self, forKey: .ward) ?? ""
        boothNumber = try c.decodeIfPresent(String.self, forKey: .boothNumber) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(state, forKey: .state)
        try c.encode(electionLevel, forKey: .electionLevel)
        try c.encode(district, forKey: .district)
        try c.encode(areaName, forKey: .areaName)
        try c.encodeIfPresent(localBodyKind, forKey: .localBodyKind)
        try c.encode(ward, forKey: .ward)
        try c.encode(boothNumber, forKey: .boothNumber)
    }
}

struct UserSession: Codable, Equatable {
    /// Google sign-in stays valid without re-prompting for this long after `lastLoginAt`.
    static let sessionMaxAge: TimeInterval = 24 * 60 * 60

    var email: String
    var displayName: String
    var profileImageURL: String?
    var accessToken: String?
    /// Stored in UserDefaults for silent token refresh (not Keychain).
    var refreshToken: String?
    var isRegistered: Bool
    var hasGoogleDriveAccess: Bool
    var booth: BoothProfile?
    var lastLoginAt: Date?

    /// Signed in with Google; persists until explicit logout or app reinstall.
    var isLoggedIn: Bool {
        !email.isEmpty
    }

    /// Booth registration is complete with a linked voter sheet.
    var hasActiveRegistration: Bool {
        guard isRegistered, let booth, booth.sheetID != nil else { return false }
        return booth.isRegistrationComplete
    }

    mutating func reconcileRegistration() {
        if let booth, !booth.boothNumber.isEmpty, booth.sheetID != nil {
            isRegistered = true
        } else if isRegistered && (booth == nil || booth?.sheetID == nil) {
            isRegistered = false
        }
    }

    init(
        email: String,
        displayName: String,
        profileImageURL: String? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        isRegistered: Bool = false,
        hasGoogleDriveAccess: Bool = false,
        booth: BoothProfile? = nil,
        lastLoginAt: Date? = nil
    ) {
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.isRegistered = isRegistered
        self.hasGoogleDriveAccess = hasGoogleDriveAccess
        self.booth = booth
        self.lastLoginAt = lastLoginAt
    }

    enum CodingKeys: String, CodingKey {
        case email, displayName, profileImageURL, accessToken, refreshToken
        case isRegistered, hasGoogleDriveAccess, booth, lastLoginAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        email = try c.decode(String.self, forKey: .email)
        displayName = try c.decode(String.self, forKey: .displayName)
        profileImageURL = try c.decodeIfPresent(String.self, forKey: .profileImageURL)
        accessToken = try c.decodeIfPresent(String.self, forKey: .accessToken)
        refreshToken = try c.decodeIfPresent(String.self, forKey: .refreshToken)
        isRegistered = try c.decodeIfPresent(Bool.self, forKey: .isRegistered) ?? false
        hasGoogleDriveAccess = try c.decodeIfPresent(Bool.self, forKey: .hasGoogleDriveAccess) ?? false
        booth = try c.decodeIfPresent(BoothProfile.self, forKey: .booth)
        lastLoginAt = try c.decodeIfPresent(Date.self, forKey: .lastLoginAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(email, forKey: .email)
        try c.encode(displayName, forKey: .displayName)
        try c.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try c.encodeIfPresent(accessToken, forKey: .accessToken)
        try c.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try c.encode(isRegistered, forKey: .isRegistered)
        try c.encode(hasGoogleDriveAccess, forKey: .hasGoogleDriveAccess)
        try c.encodeIfPresent(booth, forKey: .booth)
        try c.encodeIfPresent(lastLoginAt, forKey: .lastLoginAt)
    }
}

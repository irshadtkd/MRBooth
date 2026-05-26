//
//  KeralaElectionCatalog.swift
//  MRBooth
//
//  Offline catalogs sourced from LGD Kerala administrative mappings.
//

import Foundation

private struct ConstituencyDistrictData: Codable {
    let state: String
    let districts: [ConstituencyDistrictNode]
}

private struct ConstituencyDistrictNode: Codable {
    let name: String
    let constituencies: [String]
}

private struct LGDLocalBodyData: Codable {
    let state: String
    let districts: [LGDistrictNode]
}

private struct LGDistrictNode: Codable {
    let name: String
    let localBodies: [LGDLocalBodyNode]
}

private struct LGDLocalBodyNode: Codable {
    let name: String
    let kind: String
    let wards: [String]
}

enum KeralaElectionCatalog {
    private static let lokSabhaData: ConstituencyDistrictData? = load("KeralaLokSabha")
    private static let assemblyData: ConstituencyDistrictData? = load("KeralaAssembly")
    private static let localBodyData: LGDLocalBodyData? = load("KeralaLGDLocalBodies")

    static var state: String { lokSabhaData?.state ?? "Kerala" }

    static func districts(for level: ElectionLevel) -> [String] {
        switch level {
        case .lokSabha:
            return (lokSabhaData?.districts.map(\.name) ?? BoothProfile.sampleDistricts).sorted()
        case .assembly:
            return (assemblyData?.districts.map(\.name) ?? BoothProfile.sampleDistricts).sorted()
        case .localBody:
            return (localBodyData?.districts.map(\.name) ?? BoothProfile.sampleDistricts).sorted()
        }
    }

    static func lokSabhaConstituencies(district: String) -> [String] {
        constituencies(in: lokSabhaData, district: district)
    }

    static func assemblyConstituencies(district: String) -> [String] {
        constituencies(in: assemblyData, district: district)
    }

    static func localBodyDisplayOptions(district: String) -> [String] {
        guard let node = localBodyData?.districts.first(where: { $0.name == district }) else {
            return []
        }
        return node.localBodies
            .map { displayLabel(name: $0.name, kind: $0.kind) }
            .sorted()
    }

    static func wards(district: String, localBodyDisplayName: String) -> [String] {
        guard let node = localBodyData?.districts.first(where: { $0.name == district }),
              let body = node.localBodies.first(where: { displayLabel(name: $0.name, kind: $0.kind) == localBodyDisplayName }) else {
            return []
        }
        return body.wards.sorted { Int($0) ?? 0 < Int($1) ?? 0 }
    }

    static func parseLocalBodyDisplay(_ display: String) -> (name: String, kind: LocalBodyKind)? {
        guard let open = display.lastIndex(of: "("),
              display.hasSuffix(")"),
              open < display.endIndex else {
            return nil
        }
        let name = display[..<open].trimmingCharacters(in: .whitespaces)
        let kindRaw = display[display.index(after: open)..<display.index(before: display.endIndex)]
        guard let kind = LocalBodyKind(rawValue: String(kindRaw)) else { return nil }
        return (String(name), kind)
    }

    static func areaPickerTitle(for level: ElectionLevel) -> String {
        switch level {
        case .lokSabha, .assembly:
            return AppStrings.constituency
        case .localBody:
            return AppStrings.localBody
        }
    }

    static func areaPickerPlaceholder(for level: ElectionLevel) -> String {
        switch level {
        case .lokSabha:
            return AppStrings.selectLokSabhaConstituency
        case .assembly:
            return AppStrings.selectAssemblyConstituency
        case .localBody:
            return AppStrings.selectLocalBody
        }
    }

    static func areaOptions(level: ElectionLevel, district: String) -> [String] {
        guard !district.isEmpty else { return [] }
        switch level {
        case .lokSabha:
            return lokSabhaConstituencies(district: district)
        case .assembly:
            return assemblyConstituencies(district: district)
        case .localBody:
            return localBodyDisplayOptions(district: district)
        }
    }

    // MARK: - Private

    private static func load<T: Decodable>(_ name: String) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func constituencies(in data: ConstituencyDistrictData?, district: String) -> [String] {
        guard let list = data?.districts.first(where: { $0.name == district })?.constituencies else {
            return []
        }
        return list.sorted()
    }

    private static func displayLabel(name: String, kind: String) -> String {
        "\(name) (\(kind))"
    }
}

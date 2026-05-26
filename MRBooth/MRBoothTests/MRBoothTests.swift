//
//  MRBoothTests.swift
//  MRBoothTests
//

import Foundation
import Testing
@testable import MRBooth

struct MRBoothTests {

    @Test func filterCriteriaMatchesParty() {
        var criteria = FilterCriteria()
        criteria.selectedParties = [.ldf]
        let voter = Voter(partyStatus: .ldf)
        #expect(criteria.matches(voter))
        #expect(!criteria.matches(Voter(partyStatus: .udf)))
    }

    @Test func filterCriteriaInactiveMatchesAll() {
        let criteria = FilterCriteria()
        #expect(criteria.matches(Voter()))
    }

    @Test func boothProfileLegacyDecodeMapsPanchayathToAreaName() throws {
        let json = """
        {"state":"Kerala","district":"Kollam","panchayath":"Chavara","ward":"3","boothNumber":"12","userEmail":"a@b.com"}
        """
        let data = Data(json.utf8)
        let booth = try JSONDecoder().decode(BoothProfile.self, from: data)
        #expect(booth.areaName == "Chavara")
        #expect(booth.electionLevel == .localBody)
        #expect(booth.isRegistrationComplete)
    }

    @Test func lokSabhaRegistrationDoesNotRequireWard() {
        let booth = BoothProfile(
            electionLevel: .lokSabha,
            district: "Kollam",
            areaName: "Kollam",
            boothNumber: "1",
            userEmail: "test@example.com",
            sheetID: "sheet123"
        )
        #expect(booth.isRegistrationComplete)
        #expect(booth.ward.isEmpty)
    }
}

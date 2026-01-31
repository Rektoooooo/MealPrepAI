import Testing
import Foundation
@testable import MealPrepAI

struct UserProfileTests {

    @Test func genderEnumProperty() {
        let profile = UserProfile(gender: .female)
        #expect(profile.gender == .female)
        #expect(profile.genderRaw == "Female")
    }

    @Test func activityLevelEnumProperty() {
        let profile = UserProfile(activityLevel: .active)
        #expect(profile.activityLevel == .active)
    }

    @Test func dietaryRestrictionsJSONRoundTrip() {
        let profile = UserProfile(dietaryRestrictions: [.vegetarian, .glutenFree])
        #expect(profile.dietaryRestrictions.count == 2)
        #expect(profile.dietaryRestrictions.contains(.vegetarian))
        #expect(profile.dietaryRestrictions.contains(.glutenFree))
    }

    @Test func allergiesJSONRoundTrip() {
        let profile = UserProfile(allergies: [.peanuts, .shellfish])
        #expect(profile.allergies.count == 2)
        #expect(profile.allergies.contains(.peanuts))
    }

    @Test func preferredCuisinesJSONRoundTrip() {
        let profile = UserProfile(preferredCuisines: [.italian, .japanese])
        #expect(profile.preferredCuisines.count == 2)
        #expect(profile.preferredCuisines.contains(.italian))
    }

    @Test func linkAppleIDSetsProperties() {
        let profile = UserProfile()
        #expect(profile.isGuestAccount)
        #expect(profile.appleUserID == nil)

        profile.linkAppleID("apple-user-123")
        #expect(!profile.isGuestAccount)
        #expect(profile.appleUserID == "apple-user-123")
    }

    @Test func unlinkAppleIDResetsProperties() {
        let profile = UserProfile(appleUserID: "apple-user-123", isGuestAccount: false, iCloudSyncEnabled: true)
        profile.unlinkAppleID()
        #expect(profile.isGuestAccount)
        #expect(profile.appleUserID == nil)
        #expect(!profile.iCloudSyncEnabled)
    }
}

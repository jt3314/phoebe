import Foundation

struct FeatureInterest: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let featureType: String // "bbt" or "sport"
    let responses: String   // JSON string
    var notifyOnLaunch: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, responses
        case userId = "user_id"
        case featureType = "feature_type"
        case notifyOnLaunch = "notify_on_launch"
        case createdAt = "created_at"
    }
}

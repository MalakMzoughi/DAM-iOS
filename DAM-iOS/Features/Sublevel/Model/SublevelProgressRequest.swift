import Foundation

struct SublevelProgressRequest: Codable {
    let userId: String
    let levelId: String
    let sublevelId: String
    let stars: Int
    let score: Int
    let completed: Bool
}

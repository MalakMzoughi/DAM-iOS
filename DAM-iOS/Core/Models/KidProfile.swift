import Foundation

struct KidProfile: Codable, Identifiable, Equatable {
	var id: String { uniqueName.lowercased() }

	let uniqueName: String
	var displayName: String
	var age: Int
	var avatarEmoji: String
	var avatarColorHex: String
	var backendAvatarId: String?
	var backendAvatarName: String?
	var backendAvatarImageUrl: String?
}

extension KidProfile {
	static let placeholder = KidProfile(
		uniqueName: "",
		displayName: "",
		age: 0,
		avatarEmoji: "🎵",
		avatarColorHex: "#6A5AE0"
	)
}

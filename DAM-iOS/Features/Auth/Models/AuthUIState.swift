//
//  AuthUIState.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

enum KidFlowStep: Int, CaseIterable {
	case accountChoice
	case returningLogin
	case uniqueName
	case profileDetails
	case greeting
}

struct KidAvatarOption: Identifiable, Equatable {
	let emoji: String
	let label: String
	let colorValue: UInt32

	var id: String { "\(emoji)-\(colorValue)" }
	var color: Color { Color(hex: colorValue) }
	var colorHex: String { String(format: "#%06X", colorValue) }

	static let presets: [KidAvatarOption] = [
		.init(emoji: "🦥", label: "Sloth", colorValue: 0x7E57C2),
		.init(emoji: "🦊", label: "Fox", colorValue: 0xFF7043),
		.init(emoji: "🐼", label: "Panda", colorValue: 0x26C6DA),
		.init(emoji: "🐵", label: "Monkey", colorValue: 0xFFB74D),
		.init(emoji: "🦄", label: "Unicorn", colorValue: 0xEC407A),
		.init(emoji: "🐯", label: "Tiger", colorValue: 0xFFA726)
	]

	static func option(for profile: KidProfile) -> KidAvatarOption {
		if let match = presets.first(where: { $0.emoji == profile.avatarEmoji }) {
			return match
		}
		let value = profile.avatarColorHex.hexToRGBValue() ?? 0x6A5AE0
		return KidAvatarOption(emoji: profile.avatarEmoji, label: "Custom", colorValue: value)
	}
}

struct KidFlowState {
	var step: KidFlowStep
	var uniqueName: String
	var uniqueNameError: String?
	var kidName: String
	var kidAge: String
	var profileError: String?
	var returningUniqueName: String
	var returningError: String?
	var selectedAvatar: KidAvatarOption
	var backendAvatarId: String?
	var backendAvatarName: String?
	var backendAvatarImageUrl: String?
	var activeProfile: KidProfile?
	var isSavingProfile: Bool

	init(activeProfile: KidProfile? = nil) {
		self.activeProfile = activeProfile
		self.selectedAvatar = activeProfile.map { KidAvatarOption.option(for: $0) } ?? KidAvatarOption.presets.first!
		self.uniqueName = activeProfile?.uniqueName ?? ""
		self.kidName = activeProfile?.displayName ?? ""
		self.kidAge = activeProfile.map { $0.age > 0 ? "\($0.age)" : "" } ?? ""
		self.backendAvatarId = activeProfile?.backendAvatarId
		self.backendAvatarName = activeProfile?.backendAvatarName
		self.backendAvatarImageUrl = activeProfile?.backendAvatarImageUrl
		self.step = activeProfile == nil ? .accountChoice : .greeting
		self.uniqueNameError = nil
		self.profileError = nil
		self.returningUniqueName = ""
		self.returningError = nil
		self.isSavingProfile = false
	}
}

private extension String {
	func hexToRGBValue() -> UInt32? {
		let cleaned = trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
		guard cleaned.count == 6 || cleaned.count == 8 else { return nil }
		return UInt32(cleaned, radix: 16)
	}
}

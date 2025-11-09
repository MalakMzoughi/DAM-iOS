//
//  AppSettings.swift
//  DAM-iOS
//
//  Created by iMac on 9/11/2025.
//

import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    @AppStorage(AppStorageKeys.musicOn) var musicOn: Bool = true
    @AppStorage(AppStorageKeys.musicVolume) var musicVolume: Double = 0.8
    @AppStorage(AppStorageKeys.vibrationOn) var vibrationOn: Bool = true
    @AppStorage(AppStorageKeys.gameSoundsOn) var gameSoundsOn: Bool = true
    
    // remember if the user opened the app before
    @AppStorage(AppStorageKeys.hasPlayedBefore) var hasPlayedBefore: Bool = false
}

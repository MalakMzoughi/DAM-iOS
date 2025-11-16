//
//  MapView.swift
//  DAM-iOS
//
//  Created by Malak on 13/11/2025.
//

import SwiftUI

struct SeaMapView: View {
    @ObservedObject var viewModel: HomeMapViewModel
    @EnvironmentObject private var userSession: UserSession
    @State private var selectedLevel: Level? = nil

    var body: some View {
        GeometryReader { proxy in
            let mapScaleX: CGFloat = 1.3
            let mapScaleY: CGFloat = 1.1
            let mapSize = CGSize(width: proxy.size.width * mapScaleX,
                                 height: proxy.size.height * mapScaleY)

            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    Image("sea_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: mapSize.width, height: mapSize.height)
                        .clipped()

                    SeaFoamOverlayView()
                        .frame(width: mapSize.width, height: mapSize.height)

                    LevelPathView(
                        levels: viewModel.levels,
                        mapSize: mapSize,
                        progressIndex: viewModel.lastCompletedIndex
                    )

                    ShipMarkerView(
                        position: viewModel.shipPosition(in: mapSize)
                    )

                    ForEach(viewModel.levels) { level in
                        LevelIslandView(level: level)
                            .position(
                                x: level.position.x * mapSize.width,
                                y: level.position.y * mapSize.height
                            )
                            .onTapGesture {
                                if level.state != .locked {
                                    selectedLevel = level
                                }
                            }
                    }
                }
                .frame(width: mapSize.width, height: mapSize.height)
            }
        }
        .fullScreenCover(item: $selectedLevel) { level in
            LevelSelectionView(level: level)
                .environmentObject(userSession)
        }
    }
}

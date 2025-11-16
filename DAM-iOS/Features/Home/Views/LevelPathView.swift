//
//  LevelPathView.swift
//  DAM-iOS
//
//  Created by Malak on 14/11/2025.
//

import SwiftUI

struct LevelPathView: View {
    let levels: [Level]
    let mapSize: CGSize
    let progressIndex: Int   // from ViewModel

    private func point(for level: Level) -> CGPoint {
        CGPoint(
            x: level.position.x * mapSize.width,
            y: level.position.y * mapSize.height
        )
    }

    // MARK: - Paths

    private var completedPath: Path {
        var path = Path()
        guard !levels.isEmpty else { return path }

        path.move(to: point(for: levels[0]))

        for level in levels.prefix(progressIndex + 1) {
            path.addLine(to: point(for: level))
        }
        return path
    }

    private var remainingPath: Path {
        var path = Path()
        guard levels.count > 1 else { return path }

        let startIndex = max(progressIndex, 0)
        path.move(to: point(for: levels[startIndex]))

        for level in levels.suffix(from: startIndex) {
            path.addLine(to: point(for: level))
        }
        return path
    }

    // MARK: - Body

    var body: some View {
        let strokeStyle = StrokeStyle(
            lineWidth: 10,
            lineCap: .round,
            lineJoin: .round
        )

        let completedGradient = LinearGradient(
            colors: [
                Color.cyan,
                Color.green,
                Color.yellow
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        let remainingGradient = LinearGradient(
            colors: [
                Color.blue.opacity(0.35),
                Color.gray.opacity(0.35)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        ZStack {
            // Remaining (unreached) part
            remainingPath
                .stroke(remainingGradient, style: strokeStyle)

            // Completed trail
            completedPath
                .stroke(completedGradient, style: strokeStyle)

            // Glow around completed trail
            completedPath
                .stroke(completedGradient, style: strokeStyle)
                .blur(radius: 8)
                .opacity(0.7)
        }
    }
}

struct ShipMarkerView: View {
    let position: CGPoint

    var body: some View {
        Image("ship_marker")
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .position(position)
            .shadow(radius: 5)
    }
}

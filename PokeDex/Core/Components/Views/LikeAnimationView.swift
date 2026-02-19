//
//  LikeAnimationView.swift
//  PokeDex
//
//  Created by yamartin on 3/3/25.
//

import SwiftUI

struct AnimationValues {
    var opacity = 0.0
    var scale = 0.0
    var angle = Angle.zero
    var verticalOffset = 0.0
    var horizontalOffset = 0.0
}

enum AnimationType {
    case like
    case dislike
}

struct LikeAnimationView: View, Identifiable {
    let id = UUID()
    let duration: Double
    let type: AnimationType
    private let heartSize = 80.0

    var body: some View {
        GeometryReader { proxy in
            HeartImageView(size: heartSize)
                .keyframeAnimator(
                    initialValue: AnimationValues()
                ) { content, value in
                    content
                        .opacity(value.opacity)
                        .scaleEffect(value.scale)
                        .rotationEffect(value.angle)
                        .offset(x: value.horizontalOffset, y: value.verticalOffset)
                } keyframes: { _ in
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(1.0, duration: duration * 0.4, timingCurve: .easeIn)
                    }

                    KeyframeTrack(\.angle) {
                        let angle = Double.random(in: -45...45)
                        let angleMultiplier = type == .like ? 1.0 : -1.0
                        CubicKeyframe(.degrees(angle * angleMultiplier), duration: duration * 0.2)
                        CubicKeyframe(.degrees(-angle * angleMultiplier), duration: duration * 0.3)
                        LinearKeyframe(.degrees(.zero), duration: duration * 0.2)
                    }

                    KeyframeTrack(\.scale) {
                        CubicKeyframe(1.2, duration: duration * 0.5)
                        LinearKeyframe(1.0, duration: duration * 0.2, timingCurve: .easeOut)
                        LinearKeyframe(1.0, duration: duration * 0.3)
                    }

                    KeyframeTrack(\.verticalOffset) {
                        let yOffset = proxy.frame(in: .global).midY + heartSize / 2
                        let offsetMultiplier = type == .like ? -1.0 : 1.0
                        LinearKeyframe(0.0, duration: duration * 0.7)
                        LinearKeyframe(yOffset * offsetMultiplier, duration: duration * 0.3, timingCurve: .easeIn)
                    }

                    KeyframeTrack(\.horizontalOffset) {
                        let offset = Double.random(in: -40...40)
                        LinearKeyframe(0.0, duration: duration * 0.85)
                        LinearKeyframe(offset, duration: duration * 0.15)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct HeartImageView: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundStyle(
                .linearGradient(
                    colors: [Color(.igPink), Color(.igRed), Color(.igOrange)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
            )
    }
}

#Preview {
    LikeAnimationView(duration: 1.0, type: .like)
}

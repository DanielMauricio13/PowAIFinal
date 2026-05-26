//
//  HeartRateOverlay.swift
//  Gym-app-ioss
//
//  Created by Daniel Pinilla on 5/25/26.
//


//  HeartRateOverlay.swift
//  Gym-app-ioss

import SwiftUI

/// Compact BPM badge that pulses on every new reading.
struct HeartRateOverlay: View {
    let bpm: Int?
    let isMonitoring: Bool

    @State private var pulse = false

    // Zone coloring — standard 5-zone model
    private var zoneColor: Color {
        guard let bpm else { return .gray }
        switch bpm {
        case ..<100: return Color(red: 0.2, green: 0.8, blue: 0.4)   // Zone 1 – easy
        case 100..<130: return Color(red: 0.2, green: 0.6, blue: 1.0) // Zone 2 – aerobic
        case 130..<155: return Color(red: 1.0, green: 0.75, blue: 0.0)// Zone 3 – tempo
        case 155..<175: return Color(red: 1.0, green: 0.4,  blue: 0.0)// Zone 4 – threshold
        default:         return Color(red: 1.0, green: 0.1,  blue: 0.1)// Zone 5 – max
        }
    }

    private var zoneLabel: String {
        guard let bpm else { return "—" }
        switch bpm {
        case ..<100: return "Z1"
        case 100..<130: return "Z2"
        case 130..<155: return "Z3"
        case 155..<175: return "Z4"
        default:         return "Z5"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .foregroundStyle(zoneColor)
                .scaleEffect(pulse ? 1.25 : 1.0)
                .animation(.easeOut(duration: 0.2), value: pulse)

            if let bpm {
                Text("\(bpm)")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundStyle(zoneColor)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.3), value: bpm)

                VStack(alignment: .leading, spacing: 1) {
                    Text("BPM")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text(zoneLabel)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(zoneColor.opacity(0.85))
                }
            } else {
                Text(isMonitoring ? "---" : "No HR")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(zoneColor.opacity(0.5), lineWidth: 1.2))
        )
        .shadow(color: zoneColor.opacity(bpm != nil ? 0.35 : 0), radius: 10, x: 0, y: 4)
        .onChange(of: bpm) { _, _ in
            pulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { pulse = false }
        }
    }
}

import SwiftUI

/// Maps each ROM system to real controller labels.
struct FaceScheme {
    let north: String
    let west: String
    let east: String
    let south: String
    let northColor: Color
    let westColor: Color
    let eastColor: Color
    let southColor: Color
    let l1Label: String
    let l2Label: String
    let r1Label: String
    let r2Label: String

    static func forSystem(_ system: String) -> FaceScheme {
        let s = system.uppercased()
        if ["PSP", "PS1", "PSX", "PS2", "PS"].contains(where: { s.contains($0) }) {
            return FaceScheme(
                north: "△", west: "□", east: "○", south: "×",
                northColor: Color(red: 0.2, green: 0.85, blue: 0.55),
                westColor: Color(red: 0.95, green: 0.45, blue: 0.85),
                eastColor: Color(red: 0.95, green: 0.35, blue: 0.35),
                southColor: Color(red: 0.35, green: 0.65, blue: 0.95),
                l1Label: "L", l2Label: "L2", r1Label: "R", r2Label: "R2"
            )
        }
        if ["NDS", "3DS", "GBA", "GB", "GBC", "NES", "SNES", "N64", "GC", "WII", "GAMECUBE"].contains(where: { s.contains($0) }) {
            return FaceScheme(
                north: "X", west: "Y", east: "A", south: "B",
                northColor: Color(red: 0.35, green: 0.55, blue: 0.95),
                westColor: Color(red: 0.25, green: 0.85, blue: 0.45),
                eastColor: Color(red: 0.95, green: 0.25, blue: 0.25),
                southColor: Color(red: 1.0, green: 0.84, blue: 0.2),
                l1Label: "L", l2Label: "ZL", r1Label: "R", r2Label: "ZR"
            )
        }
        if ["GENESIS", "MD", "SMS", "GG", "DC"].contains(where: { s.contains($0) }) {
            return FaceScheme(
                north: "Y", west: "X", east: "B", south: "A",
                northColor: Color(red: 1.0, green: 0.84, blue: 0.2),
                westColor: Color(red: 0.35, green: 0.85, blue: 0.95),
                eastColor: Color(red: 0.95, green: 0.25, blue: 0.25),
                southColor: Color(red: 0.25, green: 0.85, blue: 0.45),
                l1Label: "X", l2Label: "Z", r1Label: "Y", r2Label: "C"
            )
        }
        // Default = reference mockup colors (Y/X/B/A)
        return FaceScheme(
            north: "Y", west: "X", east: "B", south: "A",
            northColor: Color(red: 1.0, green: 0.84, blue: 0.2),
            westColor: Color(red: 0.35, green: 0.85, blue: 0.95),
            eastColor: Color(red: 0.95, green: 0.25, blue: 0.25),
            southColor: Color(red: 0.25, green: 0.85, blue: 0.45),
            l1Label: "LB", l2Label: "LT", r1Label: "RB", r2Label: "RT"
        )
    }
}

struct SystemFaceButtons: View {
    let scheme: FaceScheme
    var radius: CGFloat = 18
    var body: some View {
        let gap = radius * 2.2
        ZStack {
            FaceButton(color: scheme.northColor, label: scheme.north, radius: radius).offset(y: -gap)
            FaceButton(color: scheme.westColor, label: scheme.west, radius: radius).offset(x: -gap)
            FaceButton(color: scheme.eastColor, label: scheme.east, radius: radius).offset(x: gap)
            FaceButton(color: scheme.southColor, label: scheme.south, radius: radius).offset(y: gap)
        }
    }
}

import SwiftUI

struct EmulatorPlayView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    @State private var coreLoaded = false

    var body: some View {
        GeometryReader { proxy in
            let s = min(proxy.size.width / 1536.0, proxy.size.height / 1536.0)

            ZStack {
                Color.white.ignoresSafeArea()

                // The reference layout is intentionally kept as one controller surface:
                // triggers/bumpers at the top, game window in the middle, sticks/d-pad/
                // face buttons around it, and Browser centered underneath.
                controllerSurface
                    .scaleEffect(s, anchor: .center)
                    .frame(width: 1536, height: 1536)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                // FPS is the only overlay that is not part of the controller artwork.
                FPSOverlay()
                    .padding(.top, 12)
                    .padding(.trailing, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .task {
            coreLoaded = CoreLoader.shared.loadCore(for: game.system)
        }
        .onDisappear {
            CoreLoader.shared.unload()
        }
    }

    private var controllerSurface: some View {
        ZStack {
            // Top shoulders
            ShoulderControl(title: "LT", shape: .trigger)
                .position(x: 296, y: 188)

            ShoulderControl(title: "LB", shape: .bumper)
                .position(x: 296, y: 270)

            ShoulderControl(title: "RT", shape: .trigger)
                .position(x: 1064, y: 188)

            ShoulderControl(title: "RB", shape: .bumper)
                .position(x: 1064, y: 270)

            // Center game display
            GameViewport(
                game: game,
                coreLoaded: coreLoaded
            )
            .position(x: 768, y: 488)

            // D-pad
            PhotoDPad()
                .position(x: 280, y: 625)

            // Xbox face buttons: Y top, X left, B right, A bottom.
            PhotoFaceButtons()
                .position(x: 1080, y: 625)

            // Analog sticks
            PhotoThumbstick()
                .position(x: 275, y: 1018)

            PhotoThumbstick()
                .position(x: 1065, y: 1018)

            // Three-dot indicator + Browser control
            HStack(spacing: 34) {
                Circle().fill(Color.black).frame(width: 42, height: 42)
                Circle().fill(Color.black).frame(width: 42, height: 42)
                Circle().fill(Color.black).frame(width: 42, height: 42)
            }
            .position(x: 768, y: 790)

            Button(action: {}) {
                Text("Browser")
                    .font(.system(size: 54, weight: .regular, design: .default))
                    .foregroundStyle(.white)
                    .frame(width: 420, height: 160)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .position(x: 768, y: 900)
        }
        .frame(width: 1536, height: 1536)
    }
}

private struct GameViewport: View {
    let game: GameItem
    let coreLoaded: Bool

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 18) {
                Text("GAME")
                    .font(.system(size: 88, weight: .regular, design: .default))
                    .foregroundStyle(.white)

                Text(game.name)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)

                Text(coreLoaded ? "Core loaded" : "Core unavailable")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .padding(.horizontal, 30)
        }
        .frame(width: 600, height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct ShoulderControl: View {
    enum ShapeKind {
        case trigger
        case bumper
    }

    let title: String
    let shape: ShapeKind

    var body: some View {
        Text(title)
            .font(.system(size: 28, weight: .regular, design: .rounded))
            .foregroundStyle(.white)
            .frame(
                width: shape == .trigger ? 196 : 236,
                height: shape == .trigger ? 64 : 80
            )
            .background {
                if shape == .trigger {
                    Trapezoid()
                        .fill(Color(red: 0.76, green: 0.79, blue: 0.83))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.76, green: 0.79, blue: 0.83))
                }
            }
    }
}

private struct Trapezoid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct PhotoDPad: View {
    var body: some View {
        ZStack {
            dpadArm(width: 78, height: 210)
                .offset(y: -4)

            dpadArm(width: 210, height: 78)
                .offset(x: -4)

            Circle()
                .fill(Color.black)
                .frame(width: 70, height: 70)
        }
        .frame(width: 250, height: 250)
    }

    private func dpadArm(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.black)
            .frame(width: width, height: height)
    }
}

private struct PhotoFaceButtons: View {
    var body: some View {
        ZStack {
            PhotoFaceButton(title: "Y", fill: Color(red: 0.98, green: 0.82, blue: 0.26))
                .offset(y: -94)

            PhotoFaceButton(title: "X", fill: Color(red: 0.32, green: 0.80, blue: 0.84))
                .offset(x: -94)

            PhotoFaceButton(title: "B", fill: Color(red: 0.95, green: 0.04, blue: 0.08))
                .offset(x: 94)

            PhotoFaceButton(title: "A", fill: Color(red: 0.08, green: 0.90, blue: 0.48))
                .offset(y: 94)
        }
        .frame(width: 270, height: 270)
    }
}

private struct PhotoFaceButton: View {
    let title: String
    let fill: Color

    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.system(size: 50, weight: .regular, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(fill, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct PhotoThumbstick: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.86, green: 0.86, blue: 0.86))
                .frame(width: 250, height: 250)

            Circle()
                .fill(Color.black)
                .frame(width: 192, height: 192)
        }
        .frame(width: 250, height: 250)
    }
}

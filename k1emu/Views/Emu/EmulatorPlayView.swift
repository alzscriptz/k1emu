import SwiftUI

struct EmulatorPlayView: View {
    let game: GameItem
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            controllerSurface
                .frame(width: 1536, height: 720)
                .aspectRatio(1536.0 / 720.0, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // FPS is the only overlay that is not part of the controller artwork.
            FPSOverlay()
                .padding(.top, 12)
                .padding(.trailing, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .task {
            _ = CoreLoader.shared.loadCore(for: game.system)
        }
        .onDisappear {
            CoreLoader.shared.unload()
        }
    }

    private var controllerSurface: some View {
        ZStack {
            ShoulderControl(title: "LT", shape: .trigger)
                .position(x: 296, y: 54)

            ShoulderControl(title: "LB", shape: .bumper)
                .position(x: 296, y: 122)

            ShoulderControl(title: "RT", shape: .trigger)
                .position(x: 1240, y: 54)

            ShoulderControl(title: "RB", shape: .bumper)
                .position(x: 1240, y: 122)

            GameViewport(game: game)
                .position(x: 768, y: 260)

            PhotoDPad()
                .position(x: 280, y: 278)

            PhotoFaceButtons()
                .position(x: 1260, y: 278)

            PhotoThumbstick()
                .position(x: 275, y: 570)

            PhotoThumbstick()
                .position(x: 1260, y: 570)

            HStack(spacing: 34) {
                Circle().fill(Color.black).frame(width: 34, height: 34)
                Circle().fill(Color.black).frame(width: 34, height: 34)
                Circle().fill(Color.black).frame(width: 34, height: 34)
            }
            .position(x: 768, y: 418)

            Button(action: {}) {
                Text("Browser")
                    .font(.system(size: 52, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 420, height: 142)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .position(x: 768, y: 525)
        }
    }
}

private struct GameViewport: View {
    let game: GameItem

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 12) {
                Text("GAME")
                    .font(.system(size: 82, weight: .regular))
                    .foregroundStyle(.white)

                Text(game.name)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)

                Text(game.system.uppercased())
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .padding(.horizontal, 30)
        }
        .frame(width: 600, height: 270)
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
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black)
                .frame(width: 78, height: 210)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black)
                .frame(width: 210, height: 78)

            Circle()
                .fill(Color.black)
                .frame(width: 70, height: 70)
        }
        .frame(width: 250, height: 250)
    }
}

private struct PhotoFaceButtons: View {
    var body: some View {
        ZStack {
            PhotoFaceButton(title: "Y", fill: Color(red: 0.98, green: 0.82, blue: 0.26))
                .offset(y: -82)

            PhotoFaceButton(title: "X", fill: Color(red: 0.32, green: 0.80, blue: 0.84))
                .offset(x: -82)

            PhotoFaceButton(title: "B", fill: Color(red: 0.95, green: 0.04, blue: 0.08))
                .offset(x: 82)

            PhotoFaceButton(title: "A", fill: Color(red: 0.08, green: 0.90, blue: 0.48))
                .offset(y: 82)
        }
        .frame(width: 250, height: 250)
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

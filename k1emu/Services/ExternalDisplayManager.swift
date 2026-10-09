import UIKit
import SwiftUI

/// Hosts the game on an external screen (HDMI / AirPlay as extra display).
/// Phone stays the controller.
@MainActor
final class ExternalDisplayManager: ObservableObject {
    static let shared = ExternalDisplayManager()

    @Published private(set) var hasExternalScreen = false

    private var externalWindow: UIWindow?
    private var hostingController: UIHostingController<AnyView>?

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenConnected), name: UIScreen.didConnectNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenDisconnected), name: UIScreen.didDisconnectNotification, object: nil
        )
        // Attach if already connected
        if let screen = UIScreen.screens.first(where: { $0 != UIScreen.main }) {
            attach(to: screen)
        }
    }

    func startGameDisplay(appState: AppState, settings: SettingsStore) {
        guard let screen = UIScreen.screens.first(where: { $0 != UIScreen.main }) else {
            hasExternalScreen = false
            return
        }
        attach(to: screen, appState: appState, settings: settings)
    }

    func stopGameDisplay() {
        externalWindow?.isHidden = true
        externalWindow = nil
        hostingController = nil
    }

    private func attach(to screen: UIScreen, appState: AppState? = nil, settings: SettingsStore? = nil) {
        hasExternalScreen = true
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen

        let root: AnyView
        if let appState, let settings {
            root = AnyView(
                ExternalGameRoot()
                    .environmentObject(appState)
                    .environmentObject(settings)
            )
        } else {
            root = AnyView(Color.black)
        }

        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .black
        window.rootViewController = host
        window.isHidden = false
        window.makeKeyAndVisible()

        externalWindow = window
        hostingController = host
    }

    @objc private func screenConnected(_ note: Notification) {
        guard let screen = note.object as? UIScreen else { return }
        hasExternalScreen = true
        // Window will be (re)built when TV mode is toggled with environment objects
        _ = screen
    }

    @objc private func screenDisconnected(_ note: Notification) {
        hasExternalScreen = UIScreen.screens.contains { $0 != UIScreen.main }
        if !hasExternalScreen {
            stopGameDisplay()
        }
    }
}

/// Full-bleed game surface for external TV / monitor.
struct ExternalGameRoot: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            EmulatorScreenView()
                .ignoresSafeArea()
        }
        .statusBarHidden(true)
    }
}

import SwiftUI
import UIKit

@MainActor
final class ExternalDisplayManager: ObservableObject {
    private var window: UIWindow?
    private weak var appState: AppState?
    private weak var settings: SettingsStore?

    func connect(appState: AppState, settings: SettingsStore) {
        self.appState = appState
        self.settings = settings
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidConnect(_:)), name: UIScreen.didConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidDisconnect(_:)), name: UIScreen.didDisconnectNotification, object: nil)
        refresh()
    }

    func refresh() {
        guard let appState, let settings,
              settings.tvModeEnabled,
              appState.isPlaying,
              let game = appState.currentGame else {
            hide()
            return
        }

        guard let screen = UIScreen.screens.first(where: { $0 != UIScreen.main }) else {
            hide()
            return
        }

        if settings.autoEnterControllerOnExternalDisplay {
            appState.isTVModeActive = true
        }

        let root = TVDisplayView(game: game)
            .environmentObject(appState)
            .environmentObject(settings)

        if window?.screen !== screen {
            hide()
            let externalWindow = UIWindow(frame: screen.bounds)
            externalWindow.screen = screen
            externalWindow.backgroundColor = .black
            externalWindow.rootViewController = UIHostingController(rootView: root)
            window = externalWindow
        } else {
            window?.rootViewController = UIHostingController(rootView: root)
        }

        window?.isHidden = false
    }

    func hide() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
    }

    @objc private func screenDidConnect(_ notification: Notification) {
        refresh()
    }

    @objc private func screenDidDisconnect(_ notification: Notification) {
        if appState?.isPlaying == true {
            appState?.isTVModeActive = false
        }
        refresh()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

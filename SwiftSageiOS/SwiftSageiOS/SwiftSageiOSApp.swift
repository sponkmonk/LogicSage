//
//  SwiftSageiOSApp.swift
//  SwiftSageiOS
//
//  Created by Chris Dillard on 4/23/23.
//

import SwiftUI
import Combine
let STRING_LIMIT = 50000


@main
struct SwiftSageiOSApp: App {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var appState = AppState()
    var serviceDiscovery: ServiceDiscovery?
    init() {
        serviceDiscovery = ServiceDiscovery()
        serviceDiscovery?.startDiscovering()

#if !os(macOS)
//        if !hasSeenInstructions() {
//            print("openning console after instr")
//        }
//        else {
//            consoleManager.isVisible = true
//        }
#endif
    //    cmdWindows = [LCManager]()

//        // Alpha window
//        cmdWindows.append(LCManager())
//        // Beta
//        cmdWindows.append(LCManager())
//        // Gamma
//        cmdWindows.append(LCManager())
//        // Delta
//        cmdWindows.append(LCManager())
//        // Epsilon
//        cmdWindows.append(LCManager())
//        // Zeta
//        cmdWindows.append(LCManager())
//        // Eta
//        cmdWindows.append(LCManager())
//        // Theta
//        cmdWindows.append(LCManager())
//        //Iota
//        cmdWindows.append(LCManager())
////        Kappa
//        Lambda
//        Mu
//        Nu
//        Xi
//        Omicron
//        Pi
//        Rho
//        Sigma
//        Tau
//        Upsilon
//        Phi
//        Chi
//        Psi
//        Omega
    }
    @State private var showInstructions: Bool = !hasSeenInstructions()
    var body: some Scene {
        WindowGroup {
            ZStack {
                settingsViewModel.backgroundColor
                    .ignoresSafeArea()
                ContentView()
                    .environmentObject(settingsViewModel)
                    .environmentObject(appState)

                    .overlay(
                        Group {
                            if showInstructions {
                                InstructionsPopup(isPresented: $showInstructions ,settingsViewModel: settingsViewModel )
                            }
                        }
                    )
            }
        }
    }
    func doDiscover() {
        serviceDiscovery?.startDiscovering()
    }
}

func setHasSeenInstructions(_ hasSeen: Bool) {
    UserDefaults.standard.set(hasSeen, forKey: "hasSeenInstructions")
}

func hasSeenInstructions() -> Bool {
    return UserDefaults.standard.bool(forKey: "hasSeenInstructions")
}

// wimdowz 95
//var cmdWindows = [LCManager]()
//var mainWindow = LCManager.shared


var firstBackground = false
class AppState: ObservableObject {
    @Published var isInBackground: Bool = false
    private var cancellables: [AnyCancellable] = []

    init() {
#if !os(macOS)

        let didEnterBackground = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .map { _ in true }
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()

        let willEnterForeground = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .map { _ in false }
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()

        didEnterBackground
            .merge(with: willEnterForeground)
            .sink { [weak self] in
                self?.isInBackground = $0
                // SHOULD RECONNECT????????
//                if !(self?.isInBackground ?? false) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + reconnectInterval) {
                        if firstBackground {
                            consoleManager.print("Reconnecting... but you should probably reboot app for now, he's working on it...")
                        }
                        //screamer.connect()
                        firstBackground = true
                    }
                    
//                }
            }
            .store(in: &cancellables)
#endif
    }
}

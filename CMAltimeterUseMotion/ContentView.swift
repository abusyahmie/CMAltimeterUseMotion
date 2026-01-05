//
//  ContentView.swift
//  CMAltimeterUseMotion
//
//  Created by AHMAD SHAHRIL AKMAR AHMAD RASHDI on 27/01/2025.
//

import SwiftUI
import CoreMotion

// Refactored: AltimeterManager encapsulates CMAltimeter usage and exposes published, display-ready strings for the UI.

@MainActor
final class AltimeterManager: ObservableObject {
    // Displayed values (strings ready for the UI)
    @Published var relAlt: String = "--"
    @Published var relPressure: String = "--"
    @Published var absAlt: String = "--"
    @Published var precision: String = "--"
    @Published var accuracy: String = "--"
    @Published var authorizationStatusText: String = "--"
    @Published var errorMessage: String? = nil
    @Published var isRelativeAvailable: Bool = false
    @Published var isAbsoluteAvailable: Bool = false

    // Controls running state. Changing this starts/stops updates automatically.
    @Published var isRunning: Bool = false {
        didSet {
            Task { @MainActor in
                if isRunning {
                    start()
                } else {
                    stop()
                }
            }
        }
    }

    private let altimeter: CMAltimeter

    init() {
        altimeter = CMAltimeter()
        updateAvailability()
        updateAuthorizationText()
    }

    // deinit intentionally omitted. Lifecycle stop() is handled explicitly by the view (onDisappear)

    func updateAvailability() {
        isRelativeAvailable = CMAltimeter.isRelativeAltitudeAvailable()
        isAbsoluteAvailable = CMAltimeter.isAbsoluteAltitudeAvailable()
    }

    func updateAuthorizationText() {
        let status = CMAltimeter.authorizationStatus()
        switch status {
        case .notDetermined:
            authorizationStatusText = "Not determined"
        case .restricted:
            authorizationStatusText = "Restricted"
        case .denied:
            authorizationStatusText = "Denied"
        case .authorized:
            authorizationStatusText = "Authorized"
        @unknown default:
            authorizationStatusText = "Unknown (\(status.rawValue))"
        }
    }

    func start() {
        errorMessage = nil
        updateAvailability()
        updateAuthorizationText()

        startRelativeUpdates()
        startAbsoluteUpdates()

        print("AltimeterManager: updates started")
    }

    func stop() {
        stopRelativeUpdates()
        stopAbsoluteUpdates()
        print("AltimeterManager: updates stopped")
    }

    private func startRelativeUpdates() {
        guard isRelativeAvailable else {
            relAlt = "unavailable"
            relPressure = "unavailable"
            return
        }

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                print("Relative update error: \(error.localizedDescription)")
                Task { @MainActor in
                    self.errorMessage = "Relative error: \(error.localizedDescription)"
                }
                return
            }

            if let data = data {
                // data.relativeAltitude and data.pressure are NSNumbers here
                let relAltitudeValue = data.relativeAltitude.doubleValue
                let pressureValue = data.pressure.doubleValue

                Task { @MainActor in
                    self.relAlt = String(format: "%.2f", relAltitudeValue)
                    self.relPressure = String(format: "%.2f", pressureValue)
                }
            } else {
                print("Relative update: no data")
            }
        }
    }

    private func stopRelativeUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
        print("AltimeterManager: relative altitude updates stopped")
    }

    private func startAbsoluteUpdates() {
        guard isAbsoluteAvailable else {
            absAlt = "unavailable"
            return
        }

        altimeter.startAbsoluteAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                print("Absolute update error: \(error.localizedDescription)")
                Task { @MainActor in
                    self.errorMessage = "Absolute error: \(error.localizedDescription)"
                }
                return
            }

            if let data = data {
                Task { @MainActor in
                    self.absAlt = String(format: "%.2f", data.altitude)
                    self.precision = String(format: "%.2f", data.precision)
                    self.accuracy = String(format: "%.2f", data.accuracy)
                }
            } else {
                print("Absolute update: no data")
            }
        }
    }

    private func stopAbsoluteUpdates() {
        altimeter.stopAbsoluteAltitudeUpdates()
        print("AltimeterManager: absolute altitude updates stopped")
    }
}

// ContentView now uses AltimeterManager as a StateObject. ContentView remains lightweight and focuses on presentation.
struct ContentView: View {
    @StateObject private var manager = AltimeterManager()

    var body: some View {
        VStack(spacing: 12) {
            Group {
                Text("Altitude: \(manager.relAlt) m")
                Text("Pressure: \(manager.relPressure) kPa")
                Text("Altitude (absolute): \(manager.absAlt) m")
                Text("Precision: \(manager.precision) m")
                Text("Accuracy: \(manager.accuracy) m")
                Text("Auth status: \(manager.authorizationStatusText)")
            }
            .font(.title3)

            if let error = manager.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }

            Spacer()

            VStack(spacing: 8) {
                Toggle("Altimeter | Barometer Sensor", isOn: $manager.isRunning)
                    .onChange(of: manager.isRunning) {
                        // zero-parameter closure (iOS 17+ preferred). Read latest state from manager.
                        print("Toggle changed to \(manager.isRunning)")
                    }

                HStack {
                    Text("Relative available:")
                    Spacer()
                    Text(manager.isRelativeAvailable ? "Yes" : "No")
                        .foregroundColor(manager.isRelativeAvailable ? .green : .secondary)
                }

                HStack {
                    Text("Absolute available:")
                    Spacer()
                    Text(manager.isAbsoluteAvailable ? "Yes" : "No")
                        .foregroundColor(manager.isAbsoluteAvailable ? .green : .secondary)
                }
            }
            .padding(.top)
        }
        .padding()
        .onAppear {
            // Ensure availability and authorization text are up to date when the view appears
            manager.updateAvailability()
            manager.updateAuthorizationText()
        }
        .onDisappear {
            // Stop updates explicitly when view disappears
            manager.stop()
        }
    }
}

#Preview {
    ContentView()
}

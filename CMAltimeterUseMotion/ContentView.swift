//
//  ContentView.swift
//  CMAltimeterUseMotion
//
//  Created by AHMAD SHAHRIL AKMAR AHMAD RASHDI on 27/01/2025.
//

import SwiftUI
import CoreMotion

//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}

//  The code is based on the following link:
//  https://forums.developer.apple.com/forums/thread/769911

struct ContentView: View {
    @State private var relAlt: String = "--"
    @State private var relPressure: String = "--"
    @State private var absAlt: String = "--"
    @State private var precision: String = "--"
    @State private var accuracy: String = "--"
    @State private var status: String = "--"

    @State private var isAltimeterOn = false 
//    {
//        didSet{
//            if isAltimeterOn {
//                startAltimeter(with: altimeter)
//            } else {
//                stopAltimeter(with: altimeter)
//            }
//        }
//    }
    
    let altimeter = CMAltimeter()
    
    var body: some View {
        VStack {
            Text("Altitude: \(relAlt) m")
                .font(.title3)
            Text("Pressure: \(relPressure) kPa")
                .font(.title3)
            Text("Altitude (absolute): \(absAlt) m")
                .font(.title3)
            Text("Precision: \(precision) m")
                .font(.title3)
            Text("Accuracy: \(accuracy) m")
                .font(.title3)
            Text("Auth status: \(status)")
                .font(.title3)
            
            Spacer()
            
            Toggle("Altimeter | Barometer Sensor", isOn: $isAltimeterOn)
                .onChange(of: isAltimeterOn) { oldValue, newValue in
                    print("toggle to \(newValue)")
                    if newValue {
                        startAltimeter(with: altimeter)
                    } else {
                        stopAltimeter(with: altimeter)
                    }
                }
        
        }
        .padding()
//        .onAppear {
            
//            It turns out initializing the CMAltimeter in the onAppear function caused the reference to not stick around, which for unclear reasons meant that relative altitude updates would never be delivered even though absolute updates were. Moving to the top level of the file made things work perfectly.
//            let altimeter = CMAltimeter()

//            startRelativeBarometerUpdates(with: altimeter)
//            startAbsoluteBarometerUpdates(with: altimeter)
//            status = CMAltimeter.authorizationStatus().rawValue.formatted()
//            print("updates started")
//        }
    }
    
    private func startAltimeter(with altimeter: CMAltimeter) {
        startRelativeBarometerUpdates(with: altimeter)
        startAbsoluteBarometerUpdates(with: altimeter)
        status = CMAltimeter.authorizationStatus().rawValue.formatted()
        print("updates started")
    }
    
    private func stopAltimeter(with altimeter: CMAltimeter) {
        stopRelativeBarometerUpdates(with: altimeter)
        stopAbsoluteBarometerUpdates(with: altimeter)
        status = CMAltimeter.authorizationStatus().rawValue.formatted()
        print("updates stopped")
    }
    
    private func startRelativeBarometerUpdates(with altimeter: CMAltimeter) {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            relAlt = "nope"
            relPressure = "nope"
            return
        }
        
        altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                print("updating relative")
                relAlt = String(format: "%.2f", data.relativeAltitude.doubleValue)
                relPressure = String(format: "%.2f", data.pressure.doubleValue)

            } else {
                print("no data relative")
            }
        }
    }
    
    private func startAbsoluteBarometerUpdates(with altimeter: CMAltimeter) {
        guard CMAltimeter.isAbsoluteAltitudeAvailable() else {
            absAlt = "nope"
            print("no absolute available")
            return
        }
        
//        let altimeter = CMAltimeter()
        altimeter.startAbsoluteAltitudeUpdates(to: .main) { data, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                print("updating absolute")
                absAlt = String(format: "%.2f", data.altitude)
                precision = String(format: "%.2f", data.precision)
                accuracy = String(format: "%.2f", data.accuracy)

            }
        }
    }
    
    private func stopRelativeBarometerUpdates(with altimeter: CMAltimeter) {
        altimeter.stopRelativeAltitudeUpdates()
        print("relative altitude updates stopped")
    }
    
    private func stopAbsoluteBarometerUpdates(with altimeter: CMAltimeter) {
        altimeter.stopAbsoluteAltitudeUpdates()
        print("absolute altitude updates stopped")
    }
}

#Preview {
    ContentView()
}

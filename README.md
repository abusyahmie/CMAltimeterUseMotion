# CMAltimeterUseMotion App

I'll explain what ContentView.swift does and walk through its state, UI, how it uses CMAltimeter, important gotchas, and a few small improvement suggestions.

## Checklist

* High-level summary — Done
* State variables & UI mapping — Done
* How altitude/pressure updates start/stop (functions) — Done
* Threading, lifecycle, and availability/authorization notes — Done
*Quick improvements and edge cases to watch — Done

## High-level summary

* This is a small SwiftUI view that reads barometer/altimeter data using CoreMotion's CMAltimeter and displays:
    * Relative altitude and pressure
    * Absolute altitude, precision, and accuracy
    * A numeric authorization status
*  The user toggles a Toggle to start/stop the altimeter updates.

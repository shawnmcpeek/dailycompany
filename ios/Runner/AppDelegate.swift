import Flutter
import UIKit
import CoreHaptics

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let bellHaptics = BellHapticsController()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "pro.daddoodev.dailycompany/haptics",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "play" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let kind = call.arguments as? String ?? ""
      self?.bellHaptics.play(kind: kind)
      result(nil)
    }
  }
}

/// Core Haptics patterns for the office bell and Lectio ticks.
final class BellHapticsController {
  private var engine: CHHapticEngine?
  private var supportsHaptics = false

  init() {
    supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    guard supportsHaptics else { return }
    do {
      engine = try CHHapticEngine()
      try engine?.start()
      engine?.stoppedHandler = { [weak self] _ in
        try? self?.engine?.start()
      }
      engine?.resetHandler = { [weak self] in
        try? self?.engine?.start()
      }
    } catch {
      supportsHaptics = false
    }
  }

  func play(kind: String) {
    guard supportsHaptics, let engine else {
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      return
    }

    do {
      try engine.start()
      let pattern = try pattern(for: kind)
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: 0)
    } catch {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }

  private func pattern(for kind: String) throws -> CHHapticPattern {
    switch kind {
    case "little":
      return try CHHapticPattern(events: [
        transient(time: 0.00, intensity: 0.45, sharpness: 0.35),
        transient(time: 0.08, intensity: 0.40, sharpness: 0.30),
      ], parameters: [])
    case "major":
      return try CHHapticPattern(events: [
        transient(time: 0.00, intensity: 0.70, sharpness: 0.45),
        transient(time: 0.14, intensity: 0.65, sharpness: 0.40),
        transient(time: 0.28, intensity: 0.60, sharpness: 0.35),
      ], parameters: [])
    case "compline":
      // Soft decaying envelope ~0.9s — the evening bell.
      return try CHHapticPattern(events: [
        transient(time: 0.00, intensity: 0.75, sharpness: 0.25),
        transient(time: 0.18, intensity: 0.60, sharpness: 0.22),
        transient(time: 0.36, intensity: 0.45, sharpness: 0.18),
        transient(time: 0.54, intensity: 0.30, sharpness: 0.14),
        transient(time: 0.72, intensity: 0.18, sharpness: 0.10),
        transient(time: 0.88, intensity: 0.10, sharpness: 0.08),
      ], parameters: [])
    case "lectioTick":
      return try CHHapticPattern(events: [
        transient(time: 0.00, intensity: 0.30, sharpness: 0.55),
      ], parameters: [])
    case "complete":
      return try CHHapticPattern(events: [
        transient(time: 0.00, intensity: 0.35, sharpness: 0.40),
        transient(time: 0.10, intensity: 0.25, sharpness: 0.30),
      ], parameters: [])
    default:
      return try CHHapticPattern(events: [
        transient(time: 0.00, intensity: 0.40, sharpness: 0.40),
      ], parameters: [])
    }
  }

  private func transient(time: TimeInterval, intensity: Float, sharpness: Float)
    -> CHHapticEvent
  {
    CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
      ],
      relativeTime: time
    )
  }
}

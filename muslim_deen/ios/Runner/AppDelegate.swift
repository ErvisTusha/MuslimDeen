import Flutter
import UIKit
import UserNotifications
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        }
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "com.ervis.muslimdeen/audio", binaryMessenger: controller.binaryMessenger)
    audioChannel.setMethodCallHandler { (call, result) in
      if call.method == "isSilentMode" {
        let audioSession = AVAudioSession.sharedInstance()
        do {
          try audioSession.setActive(true)
          let isMuted = audioSession.outputVolume == 0.0
          result(isMuted)
        } catch {
          result(false)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([[.banner, .sound]])
  }
}

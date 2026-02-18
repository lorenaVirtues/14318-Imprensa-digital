//
//  imprensaApp.swift
//  imprensa
//
//  Created by Virtues25 on 09/02/26.
//

import SwiftUI
import GoogleCast


class AppDelegate: NSObject, UIApplicationDelegate, GCKLoggerDelegate {
    let kReceiverAppID = "AA997F6E" 
    let kDebugLoggingEnabled = true
    
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
      let options = GCKCastOptions(discoveryCriteria: criteria)
      options.physicalVolumeButtonsWillControlDeviceVolume = true
      GCKCastContext.setSharedInstanceWith(options)
      GCKLogger.sharedInstance().delegate = self
      return true
  }

  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
      // Se a chave não existir, o padrão agora é permitir rotação
      if UserDefaults.standard.object(forKey: "rotationEnabled") == nil {
          return .allButUpsideDown
      }
      
      if UserDefaults.standard.bool(forKey: "rotationEnabled") {
          return .allButUpsideDown
      } else {
          return .portrait
      }
  }
}

@main
struct imprensaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var radioPlayer: RadioPlayer
    
    @State var radio: RadioModel
    
    init() {
        let defaultURL = URL(string: "https://dummy")!

        // Passa o mesmo ThemeManager para o RadioPlayer
        _radioPlayer = StateObject(
            wrappedValue: RadioPlayer(streamingURL: defaultURL)
        )
        
        _radio = State(initialValue: RadioModel(streamUrl: "https://dummy"))
        
    }
    
    var body: some Scene {
        WindowGroup {
            AppRoot(radio: radio)
                .environmentObject(radioPlayer)
        }
    }
}

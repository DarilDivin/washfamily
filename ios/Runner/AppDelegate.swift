import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lecture manuelle du .env ajouté dans les Flutter assets
    if let envPath = Bundle.main.path(forResource: "flutter_assets/.env", ofType: nil) {
        do {
            let envContent = try String(contentsOfFile: envPath)
            let lines = envContent.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.split(separator: "=", maxSplits: 1)
                if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == "GOOGLE_MAPS_API_KEY" {
                    let apiKey = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    GMSServices.provideAPIKey(apiKey)
                    break
                }
            }
        } catch {
            print("Erreur lors de la lecture du fichier .env: \(error)")
        }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

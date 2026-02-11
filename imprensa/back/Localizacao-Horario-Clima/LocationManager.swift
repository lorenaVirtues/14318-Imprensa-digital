import Foundation
import CoreLocation
import UIKit

final class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var lastLocation: CLLocation?
    @Published var city: String?
    @Published var state: String?

    // ✅ Publique o status de autorização
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        // Não precisa começar a atualizar antes da permissão
        // Peça permissão ao iniciar (se quiser manter seu comportamento atual, ok)
        manager.requestWhenInUseAuthorization()
    }

    // ✅ Expor helpers
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startOnceIfAuthorized() {
        guard authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways else { return }
        manager.startUpdatingLocation()
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

extension LocationManager: CLLocationManagerDelegate {

    // iOS 14+
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        // Comece só quando tiver autorização
        startOnceIfAuthorized()
    }

    // iOS 13 e anteriores
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authStatus = status
        startOnceIfAuthorized()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        lastLocation = loc

        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.city  = placemark.locality
                    self.state = placemark.administrativeArea
                }
            }
        }

        manager.stopUpdatingLocation() // leitura única
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erro ao obter localização:", error)
    }
}

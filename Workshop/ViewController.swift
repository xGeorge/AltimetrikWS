//
//  ViewController.swift
//  Workshop
//
//  Created by Jorge Armando Torres Perez on 3/14/20.
//

import UIKit
import MapKit
import CoreLocation

typealias NewLocationAction = (CLLocation) -> ()

class ViewController: UIViewController {
    let regionRadius: CLLocationDistance = 10000
    let locationManager = CLLocationManager()
    let initialLocation = CLLocation(latitude: 40.766548, longitude: -73.9779713) //testing
    var bicycles = [String: [MKPointAnnotation]]()
    var locationAction: NewLocationAction?

    @IBOutlet weak var mapView: MKMapView!

    func showBikesNear(from network: [Network]?) {
        guard let network = network else { return }
        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: network.capacity) { index in
                let fixedIndex = index != 0 ? index - 1 : 0
                guard let href = network[fixedIndex].href else { return }
                APIServices.shared.getBicycles(href: href) { [weak self] (network) in
                    guard let stations = network?.stations else { return }
                    for station in stations {
                        if station.free_bikes! > 0 {
                            let annotation = MKPointAnnotation()
                            annotation.coordinate = CLLocationCoordinate2D(latitude: station.latitude!, longitude: station.longitude!)
                            if self?.bicycles[network!.id!] == nil { self?.bicycles[network!.id!] = [MKPointAnnotation]() }
                            self?.bicycles[network!.id!]?.append(annotation)
                            DispatchQueue.main.async { [weak self] in
                                self?.mapView.addAnnotation(annotation)
                            }
                        }
                    }
                }
               }
        }
    }

    func centerMapOnLocation(_ location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
      mapView.setRegion(coordinateRegion, animated: true)
    }

    private func newLocationFound(location: CLLocation) {
        centerMapOnLocation(location)
        LocationServices.shared.getAdress(location: location, completion: { address, error in
            guard let address = address, error == nil,
                let countryCode = address["CountryCode"] as? String,
                let city = address["City"] as? String else { return }
            APIServices.shared.getNetwork { (networks) in
                guard var networks = networks else { return }
                networks = networks.filter { (network) -> Bool in
                    let networkCity = network.location?.city?.components(separatedBy: ", ")
                    let stateMatch = (networkCity != nil && networkCity!.capacity > 1) ? city == networkCity?[0] : city == network.location?.city
                    return network.location?.country == countryCode && stateMatch
                }
                DispatchQueue.main.async { [weak self] in
                    self?.showBikesNear(from: networks)
                }
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        getLocation(action: newLocationFound)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func getLocation(action: @escaping NewLocationAction) {
        locationAction = nil
        let status = CLLocationManager.authorizationStatus()
        switch status {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                return
            case .denied, .restricted:
                let alert = UIAlertController(title: "Location Services disabled", message: "Please enable Location Services in Settings", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
                return
            case .authorizedAlways, .authorizedWhenInUse:
                locationAction = action
                break
        }
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            locationManager.stopUpdatingLocation()
            locationAction?(currentLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationAction = nil
        print(error)
    }
}

struct Network: Codable {
    let company: [String]?
    let href: String?
    let id: String?
    let location: Location?
    let name: String?
    var stations: [Station]?

    init(_ dictionary: [String: Any]) {
        self.company = dictionary["company"] as? [String]
        self.href = dictionary["href"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
        let locationKeys = dictionary["location"] as? [String:Any]
        self.location = locationKeys != nil ? Location(locationKeys!) : nil
        self.name = dictionary["name"] as? String ?? ""
        self.stations = [Station]()
        guard let stationKeys = dictionary["stations"] as? [[String:Any]] else { return }
        for dic in stationKeys {
            self.stations!.append(Station(dic))
        }
        //TODO
    }
}

struct Location: Codable {
    let city: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    init(_ dictionary: [String: Any]) {
        self.city = dictionary["city"] as? String
        self.country = dictionary["country"] as? String ?? ""
        self.latitude = dictionary["latitude"] as? Double ?? 0.0
        self.longitude = dictionary["longitude"] as? Double ?? 0.0

    }
}

struct Station: Codable {
    let empty_slots: String?
    let extra: [String]?
    let free_bikes: Int32?
    let id: String?
    let latitude: Double?
    let longitude: Double?
    let name: String?
    let timestamp: Date?
    init(_ dictionary: [String: Any]) {
        self.empty_slots = dictionary["empty_slots"] as? String
        self.extra = dictionary["extra"] as? [String]
        self.free_bikes = dictionary["free_bikes"] as? Int32 ?? 0
        self.id = dictionary["id"] as? String ?? ""
        self.latitude = dictionary["latitude"] as? Double ?? 0.0
        self.longitude = dictionary["longitude"] as? Double ?? 0.0
        self.name = dictionary["name"] as? String
        self.timestamp = dictionary["timestamp"] as? Date
    }
}

//
//  LocationServices.swift
//  Workshop
//
//  Created by Jorge Armando Torres Perez on 3/14/20.
//

import Foundation
import MapKit

typealias JSONDictionary = [String:Any]

class LocationServices {
    public static let shared = LocationServices()
    let locationManager = CLLocationManager()

    let authStatus = CLLocationManager.authorizationStatus()
    let inUse = CLAuthorizationStatus.authorizedWhenInUse
    let always = CLAuthorizationStatus.authorizedAlways

    func getAdress(location: CLLocation!, completion: @escaping (_ address: JSONDictionary?, _ error: Error?) -> ()) {
        self.locationManager.requestWhenInUseAuthorization()
        if self.authStatus == inUse || self.authStatus == always {
            let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(location) { placemarks, error in
                guard error == nil else { return completion(nil, error) }
                let placeArray = placemarks as? [CLPlacemark]
                var placeMark: CLPlacemark!
                placeMark = placeArray?[0]
                guard let address = placeMark.addressDictionary as? JSONDictionary else { return }
                completion(address, nil)
            }
        }
    }
}

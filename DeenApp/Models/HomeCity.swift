//
//  HomeCity.swift
//  DeenApp
//
//  The user-defined "Heimatstadt" used by the Seferi (traveler) check inside
//  the Qibla compass. Stored alongside its coordinates so the great-circle
//  distance from the current GPS position can be computed without repeated
//  geocoding.
//

import Foundation
import CoreLocation

struct HomeCity: Codable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

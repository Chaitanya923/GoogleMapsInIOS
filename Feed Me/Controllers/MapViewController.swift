/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet private weak var mapCenterPinImage: UIImageView!
  @IBOutlet weak var mapView: GMSMapView!
  @IBOutlet private weak var pinImageVerticalConstraint: NSLayoutConstraint!
  
  var searchedTypes = ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
  let locationManager = CLLocationManager()
  let dataProvider = GoogleDataProvider()
  let searchRadius: Double = 1000

    @IBAction func refreshPlaces(_ sender: UIBarButtonItem) {
        fetchPlaces(near: mapView.camera.target)
    }
}

// MARK: - Lifecycle
extension MapViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self
    locationManager.delegate = self
    if CLLocationManager.locationServicesEnabled() {
      locationManager.requestLocation()
      mapView.isMyLocationEnabled = true
      mapView.settings.myLocationButton = true
    } else {
      locationManager.requestWhenInUseAuthorization()
    }
  }
  
  func reverseGeocode(coordinate: CLLocationCoordinate2D) {
    // 1
    let geocoder = GMSGeocoder()
    // 2
    geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
      guard
        let address = response?.firstResult(),
        let lines = address.lines
        else {
          return
      }
      // 3
      self.addressLabel.text = lines.joined(separator: "\n")
      // 4
      UIView.animate(withDuration: 0.25) {
        self.view.layoutIfNeeded()
      }
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard
      let navigationController = segue.destination as? UINavigationController,
      let controller = navigationController.topViewController as? TypesTableViewController
      else {
        return
    }
    controller.selectedTypes = searchedTypes
    controller.delegate = self
  }
  
  func fetchPlaces(near coordinate: CLLocationCoordinate2D){
    // 1
    mapView.clear()
    // 2
    dataProvider.fetchPlaces(
      near: coordinate,
      radius:searchRadius,
      types: searchedTypes
    ) { places in
      places.forEach { place in
        // 3
        let marker = PlaceMarker(place: place, availableTypes: self.searchedTypes)
        // 4
        marker.map = self.mapView
      }
    }
  }

}

// MARK: - TypesTableViewControllerDelegate
extension MapViewController: TypesTableViewControllerDelegate {
  func typesController(_ controller: TypesTableViewController, didSelectTypes types: [String]) {
    fetchPlaces(near: mapView.camera.target)

    searchedTypes = controller.selectedTypes.sorted()
    dismiss(animated: true)
  }
}

// MARK: - CLLocationManagerDelegate
//1
extension MapViewController: CLLocationManagerDelegate {
  // 2
  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    // 3
    guard status == .authorizedWhenInUse else {
      return
    }
    // 4
    locationManager.requestLocation()

    //5
    mapView.isMyLocationEnabled = true
    mapView.settings.myLocationButton = true
  }

  // 6
  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else {
      return
    }
    fetchPlaces(near: location.coordinate)
    // 7
    mapView.camera = GMSCameraPosition(
      target: location.coordinate,
      zoom: 15,
      bearing: 0,
      viewingAngle: 0)
  }

  // 8
  func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error
  ) {
    print(error)
  }
}

extension MapViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
    reverseGeocode(coordinate: position.target)
  }
}

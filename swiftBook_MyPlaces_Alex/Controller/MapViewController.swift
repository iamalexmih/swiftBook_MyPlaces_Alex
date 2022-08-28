//
//  MapViewController.swift
//  swiftBook_MyPlaces_Alex
//
//  Created by Алексей Попроцкий on 16.07.2022.
//

import UIKit
import MapKit
import CoreLocation

protocol MapToNewViewControllerDelegate {
    func getAddress(_ address: String?)
}


class MapViewController: UIViewController {
    
    let mapManager = MapManager()
    var mapToNewViewControllerDelegate: MapToNewViewControllerDelegate? // Delegate
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    var incomeSegueIdentifier = ""
    
    var previousLocation: CLLocation? {
        didSet {
            mapManager.startTrackingUserLocation(for: mapView,
                                                and: previousLocation)
            { currentLocation in
                self.previousLocation = currentLocation
                DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                    self.mapManager.showUserLocation(mapView: self.mapView)
                }
            }
        }
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addressLabel.text = ""
        mapView.delegate = self
        setupMapView()
    }

    @IBAction func closeMap() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func centerViewUserLocation() {
        mapManager.showUserLocation(mapView: mapView)
    }
    
    @IBAction func doneButtonPress() {
        mapToNewViewControllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goButtonPressed() {
        mapManager.getDirections(for: mapView) { location in
            self.previousLocation = location
        }
    }
    
    private func setupMapView() {
        mapManager.centerLocation(mapManager.initLocationGelendzhik, regionRadius: 3000, mapView: mapView)
        goButton.isHidden = true
        
        mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        if incomeSegueIdentifier == "showPlaceMap" {
            mapManager.setupPlacemark(place: place, mapView: mapView)
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
}

//Расширение клааса позволяющее кастоматизировать банер точки локации
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil } // Проверяем что annotation не является аннотацией определяющей текущее местоположение юзера.
        
        // Прежде чем создавать новый объект annotationView, надо проверить его на переиспользование dequeueReusableAnnotationView.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50)) // height/width = 50, так как размеры банера 50.
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
    
    //метод будет вызываться каждый раз при смене отображаемого на экране региона, и каждый раз мы будем отображать адрес который находиться в центре текущего региона.
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder() //преобразовывает координаты в адрес, и на оборот
        
        if incomeSegueIdentifier == "showPlaceMap" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                self.mapManager.showUserLocation(mapView: self.mapView)
            }
        }
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center) { placemarks, error in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let city = placemark?.locality
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                if streetName != nil && buildNumber != nil && city != nil {
                    self.addressLabel.text = "\(city!), \(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
            
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 4
        return renderer
    }
}

// didChangeAuthorization устаревший метод, за место него locationManagerDidChangeAuthorization(_:)
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // checkLocationAuthorization()
    }
}

//
//  MapManager.swift
//  swiftBook_MyPlaces_Alex
//
//  Created by Алексей Попроцкий on 18.07.2022.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()
    
    let initLocationGelendzhik = CLLocation(latitude: 44.56112, longitude: 38.07644)
    
    

    
    private let regionInMeters = 500.00
    private var placeCoordinate: CLLocationCoordinate2D? //хранение координат
    private var directionsArray: [MKDirections] = []
    
    // MARK: - Annotation, Маркер Заведения
    func setupPlacemark(place: Place, mapView: MKMapView) {
        guard let location = place.location else { return }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            if let error = error { // извлекаем ошибку
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return } // извлекаем опционал из placemarks, это массив
            let placemarkAdress = placemarks.first // Мы ищем положение по конкретному адресу, поэтому массив placemarks должен содержать всего одну метку
            
            let annotation = MKPointAnnotation() // Экземпляр описывает точку на карте
            annotation.title = place.name
            annotation.subtitle = place.type
            
            // Определяем положение маркера
            guard let placemarkLocation = placemarkAdress?.location else { return }
            
            //Привязываем аннотацию к точке на карте в соответствии с расположением маркера (placemarkAdress)
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            
            mapView.showAnnotations([annotation], animated: true) //показать область карты, чтоб на ней были видны все созданные аннотации. массив аннотаций [annotation].
            mapView.selectAnnotation(annotation, animated: true) //чтобы выделить созданную аннотацию, Значок метки становиться больше, чем у всех остальных меток.
            
        }
    }
    
    //MARK: - Проверка доступности сервисов геолокации
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else { //Если службы геолокации выключены, то вызвать Алерт контроллер с инструкциями, как их включить.
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.showAlert(title: "Ваша локация не определена", message: "Зайдите в настройки setting -> Privacy -> Location Services and turn On")
            }
        }
    }
    
    //MARK: - Проверка авторизации приложения для исп сервисов геолок
    func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {//Обработка разных вариантов Ауторизации пользователя.
        switch locationManager.authorizationStatus { // authorizationStatus имеет пять состояний, надо их всех проверить.
            case .authorizedWhenInUse:
                mapView.showsUserLocation = true
                if segueIdentifier == "getAddress" {
                    showUserLocation(mapView: mapView)
                }
                break
            case .denied:
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    self.showAlert(title: "Ваша локация не определена", message: "Зайдите в настройки setting -> MyPlaces -> Location")
                }
                break
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                //Show alert controller
                break
            case .authorizedAlways:
                break
            @unknown default:
                print("func checkLocationAuthorization(), New case is available")
        }
    }
    
    //MARK: - Фокусирование камеры на местоположении пользователя
    func showUserLocation(mapView: MKMapView) {
        if let location = locationManager.location?.coordinate { //если получается определить координаты пользователя
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: - Построение маршрута юзер - место
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
        
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Текущая позиция не найдена")
            return
        }
        
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        guard let request = createDirectionRequest(from: location) else {
            showAlert(title: "Error", message: "Место назначения не найдено")
            return
        }
        let directions = MKDirections(request: request)
        
        //запуск расчета маршрута
        directions.calculate { response, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.showAlert(title: "Error", message: "Маршрут не доступен")
                return
            }
            for route in response.routes {// массив с перечислением возможными вариантами маршрута
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) //показать целиком маршрут на экране
                
                //время в пути и расстояние
                let distance = String( format: "%.1f", route.distance/1000)
                let timeInterval = route.expectedTravelTime
                
                print("Расстояние до места: \(distance) км")
                print("Время в пути составит: \(timeInterval) cек")
            }
            
        }
    }
    // MARK: -  Настройка запроса для расчета маршрута
    func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        guard let destinationCoordinate = placeCoordinate else { return nil }
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    // MARK: -  Меняем отображаемую зону области карты в соответствии с перемещением пользователя
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        guard let location = location else { return }
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: location) > 50 else { return }
        
        closure(center)
    }
    // MARK: - сброс всех ранее построенных маршрутов перед построением нового
    func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
        directionsArray.removeAll()
    }
    
    // MARK: - Определение центра отображаемой области карты
    // метод возращает координаты точки, находящейся по центру экрана
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Alert Controller
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
        
    }
    
    // MARK: - Центрирование карты при запуске mapView на заданном городе
    
    func centerLocation(_ location: CLLocation, regionRadius: CLLocationDistance, mapView: MKMapView) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
}

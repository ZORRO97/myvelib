//
//  MapViewController.swift
//  myvelib
//
//  Created by etudiant-11 on 14/04/2016.
//  Copyright © 2016 francois. All rights reserved.
//

import UIKit
import MapKit
import Flurry_iOS_SDK

class MapViewController: UIViewController {
    
    
    @IBOutlet var mapView : MKMapView!
    @IBOutlet var flecheButton  :UIButton!
    
    // var velibStations : [VelibStation]!
    var stationsIds: [Int]!
    var allStations : [VelibStation]!
    var centerStation: VelibStation!
    var closestStations = [VelibStation]()
    var locationManager =  CLLocationManager()
    let regionRadius: CLLocationDistance = 450
    var pageIndex  : ScreenType!
    
    // Action pour le bouton retour
    @IBAction func backButtonPressed(){
        print("Button back pressed")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func flecheButtonPressed(){
        self.showUserLocation()
        mapView.setCenterCoordinate(mapView.userLocation.coordinate, animated: true)
    }
    
    // ajouter les pins pour une liste de stations
    func displayPins(stations : [VelibStation]){
        mapView.removeAnnotations(mapView.annotations)
        let mapCenterPosition = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        print(" les stations \(stationsIds)")
        for station in stations {
            if (mapCenterPosition.distanceFromLocation(station.position) <= regionRadius * 2) {
                if (stationsIds.indexOf(station.numberStation) != nil) {
                    addPin(station, pinType: .FavoriteStation)
                } else {
                    addPin(station,pinType: .StandardStation)
                }
            }
        }
        
        
    }

    override func viewDidLoad() {
        
        print("nb de stations \(allStations.count)")
        // print("station sélectionnée \(centerStation.texteStation)")
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // mapView.centerCoordinate
        // locationManager.requestAlwaysAuthorization()
        // affiche tous les pins
        displayPins(allStations)
        var params = [String : String]()
        if centerStation != nil {
            self.centerMapOnLocation(centerStation.position)
            params["position_centre"] = "latitude \(centerStation.position.coordinate.latitude) longitude \(centerStation.position.coordinate.longitude)"
        } else {
            self.centerMapOnLocation(CLLocation(latitude: 48.853, longitude: 2.35))
            params["position_centre"] = "forcée latitude \(48.853) longitude \(2.35)"
        }
        // événement analytique
        sendAnalyticsEvent("affichage carte", parameters: params)
        self.showUserLocation()
        closestStations =
            getClosestStations(allStations, userPosition: centerStation.position, number: 5)
        for station in closestStations {
            print("station proche \(station.numberStation) distance \(station.distanceToUser!)")
        }
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - LocationManager
    func showUserLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("did update location")
        if manager.location != nil {
            locationManager.stopUpdatingLocation()
            logDebug("launching request")
            
            
        }
    }
    
    
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: false)
    }
    
    func addPin(velibStation : VelibStation, pinType : PinType) {
        let myPin = Pin(station : velibStation ,pinType: pinType)
        mapView.addAnnotation(myPin)
    }
    // MARK: -
}

extension MapViewController : MKMapViewDelegate, CLLocationManagerDelegate {
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // pour supprimer les annotations
        
        displayPins(allStations)
        print("appel mapview")
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? Pin {
            let identifier = "pin"
            
            var view: MKAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView { // 2
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)//position du popup par rapport à l'image
                
                //pour bien placer le pin
                view.centerOffset = CGPoint(x: 0, y: -25)
                
                view.image = annotation.image
                
                let imageRight = (annotation.pinType == .FavoriteStation) ? "fleche_pleine" : "fleche_creuse"
                let myButton = UIButton(type: .Custom)
                myButton.frame = CGRect(x: 20, y: 20, width: 20, height: 20)
                myButton.setBackgroundImage(UIImage(named: imageRight), forState: .Normal)
                view.rightCalloutAccessoryView = myButton as UIView
                
                view.leftCalloutAccessoryView = UIImageView(image: annotation.image)
                view.frame.size = CGSize(width: 36, height: 45)
            }
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        let myStation = view.annotation as! Pin
        
        print("info for :\(myStation.station.texteStation)")
        switch myStation.pinType {
        case .FavoriteStation :
            if let index = stationsIds.indexOf(myStation.station.numberStation) {
                stationsIds.removeAtIndex(index)
                persistStations(stationsIds, pageIndex: pageIndex)
            }
        case .StandardStation :
            stationsIds.append(myStation.station.numberStation)
            persistStations(stationsIds, pageIndex: pageIndex)
        default: break
        }
        sendAnalyticsEvent("changement drapeau", parameters: nil)
        displayPins(allStations)
    }
}
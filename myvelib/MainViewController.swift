//
//  MainViewController.swift
//  myvelib
//
//  Created by etudiant-11 on 11/04/2016.
//  Copyright © 2016 francois. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Flurry_iOS_SDK
import MapKit
import CoreLocation

class MainViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var bikeTableView:UITableView!
    @IBOutlet var pageButton:UIButton!
    @IBOutlet var explicationLabel:UILabel!
    @IBOutlet var compteurLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    
    var refreshControl: UIRefreshControl!
    var pageIndex:ScreenType = .Home
    let locationManager = CLLocationManager()
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    // var stationIds = [18101, 18037, 18023, 18105]
    var stationIds = [Int]()
    var velibStations = [VelibStation]() // les stations de l'environnement home | work | geoloc
    var allStations = [VelibStation]() // toutes les stations
    var centerStation: VelibStation!
    var geolocStations = [VelibStation]()
    
    var available_bike_stands = 0
    
    @IBAction func sendButtonPressed(){
        print("lancement")
        
        hydrate()
    }
    
    @IBAction func situationButtonPressed() {
        print("bouton image activé")
        if stationIds.isEmpty {
            print("liste des stations vide")
        } else {
            // renseigner centerStation
            centerStation = velibStations[0]            
        }
        performSegueWithIdentifier("tomap", sender: self)    }
    
    // début d'affichage indicateur d'activité
    func startIndicator(){
        self.activityIndicator.hidden = false
        self.activityIndicator.startAnimating()
    }
    
    // fin affichage indicateur activité
    func stopIndicator(){
        self.activityIndicator.hidden = true
        self.activityIndicator.stopAnimating()
    }
    
    // Remplir les tableaux
    func hydrate(){
        // méthode 1
        /*
        for id in stationIds {
            getStationInfo(id)
        }*/
        // méthode 2
        // getStationsInfo(stationIds)
        // méthode 3 (la bonne) avec closure
        // il y a un appel réseau asynchrone
        NSLog("avant la requete")
        
        if let myStationIds = getStationsIds(pageIndex) {
            stationIds = myStationIds
            startIndicator()
            // persistStations(myStationIds, pageIndex: pageIndex)
            getStationsInfoNew (self, stationIds: myStationIds) { (stationsReceived,allStations) in
                
                NSLog("received from getStationsInfo: \(stationsReceived)")
                self.velibStations = stationsReceived
                
                self.allStations = allStations
                                print("Toutes les stations au nombre de \(allStations.count)")
                self.bikeTableView.reloadData()
                self.view.backgroundColor = getColorStation(stationsReceived)
                self.stopIndicator()
            }
        } else {
            NSLog("pas de stations")
        }
        
        
        
        // ou bien version complète
        /*
        getStationsInfoNew (self.stationIds, completionHandler: { (stationsReceived : [VelibStation]) in
            
            NSLog("received from getStationsInfo: \(stationsReceived)")
            self.stations = stationsReceived
            self.stationTableView.reloadData()
        })
         */
        
    }
    
    func refresh(sender: AnyObject){
        print("On rafraichit")
        // code pour rafraichir
        // myStations.removeAll()  // vide les valeurs du tableau
        hydrate()     // remplir le tableau        
        sender.endRefreshing()  // terminer le rafraichissement
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "tomap") {
            let mydestination: MapViewController =  segue.destinationViewController as! MapViewController
            mydestination.stationsIds = self.stationIds
            mydestination.centerStation = self.centerStation
            mydestination.allStations = self.allStations
            mydestination.pageIndex = self.pageIndex
            
        }
    }
    
    // MARK: - LocationManager
    func initGeoloc() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    
    // cette fonction écoute le changement de position du user
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        logDebug("did update location")
        
        if manager.location != nil {
            locationManager.stopUpdatingLocation()
            logDebug("launching request")
            
            // lancer la requete pour obtenir les stations et afficher les stations les plus proches
            // en utilisant getClosestStations
            getStationsInfoNew (self,stationIds: [Int]()) { (stationsReceived,allStations) in
                
                
                self.allStations = allStations
                print("Toutes les stations au nombre de \(allStations.count)")
                self.velibStations = getClosestStations(allStations, userPosition: manager.location! , number: 10)
//                for station in self.velibStations {
//                    print("station géolocalisée \(station.texteStation)")
//                }
                self.bikeTableView.reloadData()
                self.view.backgroundColor = getColorStation(self.velibStations)
                
                self.stopIndicator()
            }
            
        }
        
    }
    // MARK: -
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // hydrate()
        
        // Do any additional setup after loading the view, typically from a nib.
        // code slide to refresh
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(MainViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.bikeTableView.addSubview(refreshControl)
        var nomImage:String
        
        // var color: UIColor
        switch self.pageIndex {
        case .Home : nomImage = "home"
          //  color = UIColor.blueColor()
        case .Work : nomImage = "work"
          //  color = UIColor.yellowColor()
        case .Geoloc : nomImage = "geolocx2"
        //    color = UIColor.cyanColor()
        }
        pageButton.setBackgroundImage(UIImage(named: nomImage), forState: .Normal)
      //  self.view.backgroundColor = color
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        logUserDefaultsWithFilter("Stations")
        if pageIndex == .Geoloc {
            initGeoloc()
            bikeTableView.hidden = false
            explicationLabel.hidden = true
        } else {
            
            hydrate()
            
            if stationIds.isEmpty {
                print("liste vide")
                bikeTableView.hidden = true
                explicationLabel.hidden = false
                explicationLabel.text = "Votre liste de stations préférées est vide !"
                
            } else {
                bikeTableView.hidden = false
                explicationLabel.hidden = true
            }
            var params = [String : String]()
            params["nombre de stations"] = "\(stationIds.count)"
            params["vue"]="Main"
            sendAnalyticsEvent("affichage vue principale", parameters: params)
            Flurry.logEvent("affichage vue principale")
        }
    }


}

// MARK: - TableView
extension MainViewController : UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) ->
Int {
        // A modifier, retourner le nombre de ligne dans la section
    return velibStations.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("VelibStationCell", forIndexPath: indexPath) as! VelibStationCell
        // Ajouter la logique d'affichage du texte dans la cellule de la TableView
        // la variable indexpath.row indique la ligne selectionnée
        // on accède aux IBOutlet de la cellule avec par exemple : cell.name =
        // cell.stationLabel =
        cell.nbPlacesLabel.text = "\(velibStations[indexPath.row].nbPlaces)"
        cell.nbVelosLabel.text = "\(velibStations[indexPath.row].nbBikes)"
        if pageIndex == .Geoloc {
            cell.stationLabel.adjustsFontSizeToFitWidth = true
            cell.stationLabel.text = "\(velibStations[indexPath.row].texteStation) d \(round(velibStations[indexPath.row].distanceToUser!))m"
        } else {
            cell.stationLabel.text = velibStations[indexPath.row].texteStation
        }
return cell }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedRow = indexPath.row
        //faire quelque chose avec selectedRow
        print(selectedRow)
        centerStation = self.velibStations[selectedRow]
        self.performSegueWithIdentifier("tomap", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    // personnalisation du slide to left
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        /*
        let value = self.myStations[indexPath.row].favorite
        // utilisation d'une closure
        let favorite = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: value ? "Enlever" : "Favorite") { action, index in
            print("favorite button tapped")
            
            self.myStations[indexPath.row].favorite = (value) ? false : true
            self.bikeTableView.reloadData()
        }
        favorite.backgroundColor = UIColor.orangeColor()
        */
        
        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete") { action, index in
            print("Delete button tapped")
            self.velibStations.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
        }
        return [delete]
    }

}

//
//  Model.swift
//  myvelib
//
//  Created by etudiant-11 on 13/04/2016.
//  Copyright © 2016 francois. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MapKit

enum ScreenType {
    case Home
    case Work
    case Geoloc
}

enum PinType {
    case FavoriteStation
    case StandardStation
    case Home
    case Work
}


let TESTVERSION = true

class Pin: NSObject, MKAnnotation {
    var title: String? {
        if let myTitle = self.station.texteStation as String! {
            return myTitle
        } else {
            return nil
        }
    }
    // let location: CLLocation
    let pinType: PinType
    
    var image: UIImage {
        let label:String
        switch self.pinType {
            
        case .FavoriteStation : label = "station_orange"
        case .StandardStation : label = "station_grise"
        case .Home : label = "home"
        case .Work : label = "work"
            
        }
        if let myImage = UIImage(named: label) {
            return myImage
        } else {
            return UIImage(named : "plus")!
        }
        
    }
    var station: VelibStation
    
    init(station : VelibStation, pinType: PinType) {
        
        self.station = station
        // self.location = location
        self.pinType = pinType
        // self.image = image
        super.init()
    }
    
    var coordinate : CLLocationCoordinate2D {
        return self.station.position.coordinate
    }
    
    //nécessaire si on ne veut pas de subtitle
    var subtitle: String? {
        return ""
    }
}

// récupérer les infos de toutes les stations demandées d'un coup
func getStationsInfoNew(vc : MainViewController?, stationIds:[Int], completionHandler: (stations: [VelibStation],allStations :[VelibStation])->()){
    // URL spécifique de DECAUD
    let urlString = "\(APIURL)/stations?contract=\(APIContract)&apiKey=\(APIKey)"
    var output = [VelibStation]()
    var allStations = [VelibStation]()
    
    NSLog("debut de getStationInfo")
    
    Alamofire.request(.GET, urlString, parameters : nil)
        .response { (request, response, data, error) in
            NSLog("Résultat de la requête reçu")
            if (error == nil && data != nil) {
                
                
                let json = JSON(data: data!) // tableau de json
                let myQueue = dispatch_queue_create("myQueue", nil)
                dispatch_async(myQueue, {
                    var compteur = 0
                    var ratio = 0.0
                for index in 0..<json.count {  // ouvre le for
                    
                    compteur += 1
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        // mettre le code de la main thread ici
                        if vc != nil {
                            ratio = Double(compteur)/Double(json.count)
                            vc!.compteurLabel.text = "\(round(ratio*10000)/100) %"
                            vc!.progressView.progress = Float(ratio)
                        }
                    })
                    
                    var numberStation = 0
                    if let number_station = json[index]["number"].number { // test number
                        numberStation = Int(number_station)
                        
                            if let availableStands = json[index]["available_bike_stands"].number,
                                let available_bikes = json[index]["available_bikes"].number,
                                let description_station = json[index]["name"].string,
                                let lat_position = json[index]["position"]["lat"].number,
                                let lng_position = json[index]["position"]["lng"].number
                            {
                                let position = CLLocation(latitude: CLLocationDegrees(lat_position), longitude: CLLocationDegrees(lng_position))
                                let myStation = VelibStation(numberStation: numberStation, texteStation: description_station, nbBikes: Int(available_bikes), nbPlaces: Int(availableStands))
                                myStation.position = position
                                if  stationIds.indexOf(numberStation) != nil {
                                    output.append(myStation)
                                }
                                allStations.append(myStation)
                                
                            } else {
                                print("probleme json avec autres données \(json[index])")
                            }
                         // pas de else ce n'est pas un numéro intéressant
                    } else {
                        print("probleme avec \(json[index])")
                    }
                    
                } // fin du for
                
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    // mettre le code de la main thread ici
                    completionHandler(stations: output, allStations: allStations)
                })
                    
                }) // fin dispatch
                
            } else {
                NSLog("error in GetSimpleSation=\(error)")
            }
            
            NSLog("Fin du traitement de la requête")        }
    NSLog("fonction getStationInfo terminée")
}

func getStationsIds(pageIndex :ScreenType)->[Int]?{
    var output = [Int]?()
    switch pageIndex {
        case .Home :
            // output =  [18028,17001]
           output = NSUserDefaults().objectForKey("HomeStations") as! [Int]?
        case .Work :
            // output = [18101,18037,18105]
            output = NSUserDefaults().objectForKey("WorkStations") as! [Int]?
        case .Geoloc :
            
            output = [35002] //[35002,35003,33005]
    }
    
    return output
}

func getColorStation(stations: [VelibStation])->UIColor {
    var nbMax = 0
    var color : UIColor!
    for station in stations {
        if station.nbBikes > nbMax {
            nbMax = station.nbBikes
        }
    }
    switch nbMax {
    case 0: color = UIColor.redColor()
    case 1: color = UIColor.orangeColor()
    default: color = UIColor.greenColor()
    }
    return color
}

func persistStations(stationsIds: [Int],pageIndex: ScreenType ){
    // sauvegarder les données
    switch pageIndex {
    case .Home : NSUserDefaults.standardUserDefaults().setObject(stationsIds, forKey: "HomeStations")
    case .Work: NSUserDefaults.standardUserDefaults().setObject(stationsIds, forKey: "WorkStations")
    case .Geoloc: NSUserDefaults.standardUserDefaults().setObject(stationsIds, forKey: "GeolocStations")
    }
   
    
}

func getClosestStations(stations : [VelibStation], userPosition : CLLocation, number : Int)->[VelibStation] {
    var stationsSort = [VelibStation]()
    var output = [VelibStation]()
    for station in stations {
        station.setDistanceToUser(userPosition)
    }
    stationsSort = stations.sort( { $0.distanceToUser < $1.distanceToUser })
    
    let max = (number < stationsSort.count) ? number : stationsSort.count
    for index in 0..<max  {
        output.append(stationsSort[index])
    }
    
    return output
}

/*
// récupérer les infos de toutes les stations demandées d'un coup
func getStationsInfo(stationIds:[Int]){
    // URL spécifique de DECAUD
    let urlString = "\(APIURL)/stations?contract=\(APIContract)&apiKey=\(APIKey)"
    
    NSLog("debut de getStationInfo")
    
    Alamofire.request(.GET, urlString, parameters : nil)
        .response { (request, response, data, error) in
            NSLog("Résultat de la requête reçu")
            if (error == nil && data != nil) {
                
                
                let json = JSON(data: data!) // tableau de json
                
                for index in 0..<json.count {  // ouvre le for
                    
                    var numberStation = 0
                    if let number_station = json[index]["number"].number { // test number
                        numberStation = Int(number_station)
                        if  stationIds.indexOf(numberStation) != nil {
                            if let availableStands = json[index]["available_bike_stands"].number,
                                let available_bikes = json[index]["available_bikes"].number,
                                let description_station = json[index]["name"].string               {
                                
                                self.velibStations.append(VelibStation(numberStation: numberStation, texteStation: description_station, nbBikes: Int(available_bikes), nbPlaces: Int(availableStands)))
                                self.bikeTableView.reloadData()
                            } else {
                                print("probleme json avec autres données \(json[index])")
                            }
                        } // pas de else ce n'est pas un numéro intéressant
                    } else {
                        print("probleme avec \(json[index])")
                    }
                    
                }
                
            } else {
                NSLog("error in GetSimpleSation=\(error)")
            }
            
            NSLog("Fin du traitement de la requête")        }
    NSLog("fonction getStationInfo terminée")
}
 */

/*

func getStationInfo(stationId: Int){
    let urlString = "\(APIURL)/stations/\(stationId)?contract=\(APIContract)&apiKey=\(APIKey)"
    
    NSLog("debut de getStationInfo")
    
    Alamofire.request(.GET, urlString, parameters : nil)
        .response { (request, response, data, error) in
            NSLog("Résultat de la requête reçu")
            if (error == nil && data != nil) {
                
                let json = JSON(data: data!)
                var nbPlaces = 0
                var nbBikes = 0
                var numberStation = 0
                var texteStation = ""
                
                if let availableStands = json["available_bike_stands"].number,
                    let available_bikes = json["available_bikes"].number,
                    let number_station = json["number"].number,
                    let description_station = json["name"].string                    {
                    nbPlaces = Int(availableStands)
                    nbBikes = Int(available_bikes)
                    numberStation = Int(number_station)
                    texteStation = description_station
                    
                    self.velibStations.append(VelibStation(numberStation: numberStation, texteStation: texteStation, nbBikes: nbBikes, nbPlaces: nbPlaces))
                    self.bikeTableView.reloadData()
                } else {
                    print("probleme avec \(json)")
                }
            } else {
                NSLog("error in GetSimpleSation=\(error)")
            }
            
            NSLog("Fin du traitement de la requête")        }
    NSLog("fonction getStationInfo terminée")
    
}
 */

/* func getStationInfoV1 (stationId : Int)  {
 
 
 let urlString = "https://api.jcdecaux.com/vls/v1/stations/\(stationId)?contract=Paris&apiKey=75b0a9731cbe12ea8fe887883d1b3a4cd85bb5fd"
 let request = NSURLRequest(URL: NSURL(string: urlString)!)
 
 
 NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
 //voila ce qu'on fait avec le résultat
 
 if (error == nil)  && (data != nil) {
 
 NSLog("Response =\(response)")
 NSLog("Data =\(data)")
 //on parse le json
 do {
 let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
 
 print("json2=\(json)")
 
 
 if let available_bikes = json["available_bikes"] as! Int? {
 print("available bikes=\(available_bikes)")
 self.nbVelosLabel.text = "\(available_bikes)"
 }
 
 if let available_bike_stands = json["available_bike_stands"] as! Int? {
 print("available bike stands =\(available_bike_stands)")
 self.nbPlacesLabel.text = "\(available_bike_stands)"
 }
 
 
 
 } catch {
 print(error)
 }
 
 
 } else {
 NSLog("error message=\(error)")
 }
 
 }
 
 }
 */

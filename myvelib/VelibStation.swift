//
//  VelibStation.swift
//  myvelib
//
//  Created by etudiant-11 on 12/04/2016.
//  Copyright © 2016 francois. All rights reserved.
//

import Foundation
import CoreLocation

class VelibStation {
    var numberStation:Int
    var texteStation:String
    var nbBikes:Int
    var nbPlaces:Int
    var position = CLLocation()
    
    var distanceToUser: CLLocationDistance?
    
    func setDistanceToUser(userPosition : CLLocation) {
        
        self.distanceToUser = userPosition.distanceFromLocation(self.position)
    }
    
    
    
    init(numberStation:Int,texteStation:String,nbBikes:Int,nbPlaces:Int){
        self.numberStation = numberStation
        self.texteStation = texteStation
        self.nbBikes = nbBikes
        self.nbPlaces = nbPlaces
        
    }
    
        
}



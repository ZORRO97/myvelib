//
//  Utilities.swift
//  myvelib
//
//  Created by etudiant-11 on 15/04/2016.
//  Copyright © 2016 francois. All rights reserved.
//

import Foundation
import UIKit
import Flurry_iOS_SDK

func logUserDefaultsWithFilter(needle: String?) {
    print("******    User Defaults  ******")
    for (key, value) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
        
        if (needle != nil) {
            if key.rangeOfString(needle!) != nil {
                NSLog("key=\(key) value=\(value)\n")
            }
        } else {
            logDebug("key=\(key) value=\(value)\n")
        }
    }
}

func logDebug (myString: String) {
    if (TESTVERSION) {
        NSLog("debug:" + myString)
    }
}

func logWarning (myString: String) {
    NSLog("⚡️warning⚡️:" + myString)
}

func logError (myString: String) {
    NSLog("💔error💔:" + myString)
}

func isLandscape()->Bool {
    let orientation =  UIApplication.sharedApplication().statusBarOrientation
    
    return ((orientation == UIInterfaceOrientation.LandscapeLeft ) || (orientation == UIInterfaceOrientation.LandscapeRight))
}



func deviceScreenHeight()->Float {// renvoie la  hauteur du device, independamment de l'orientation
    if isLandscape() {
        //  println("returning width instead of height")
        return Float(UIScreen.mainScreen().bounds.size.width)
    } else {
        return Float(UIScreen.mainScreen().bounds.size.height)
    }
}

func getDevice ()-> String {//retourne le nom du modèle basé sur la hauteur
    #if os(iOS)
        let deviceHeight = deviceScreenHeight()
        
        //   println("realheight=\(deviceHeight)")
        if (UIDevice.currentDevice().userInterfaceIdiom == .Pad) {
            return "iPad"
        }
        else {
            switch deviceHeight {
            case 480:
                return "iPhone4"
            case 568:
                return "iPhone5"
            case 667:
                return "iPhone6"
            case 736:
                return "iPhone6plus"
            default:
                return "unknown"
            }
        }
    #else
        return "AppleTV"
    #endif
}


func getUserLanguage()->String {//from defined languages in localisation, "en" as default
    let displayNameString = NSLocale.preferredLanguages()[0]
    var output = "en"
    
    logDebug("langageString=\(displayNameString)")
    
    if (displayNameString.rangeOfString("fr") != nil) { output = "fr"  }
    if (displayNameString.rangeOfString("es") != nil) { output = "es"  }
    if (displayNameString.rangeOfString("de") != nil) { output = "de"  }
    if (displayNameString.rangeOfString("it") != nil) { output = "it"  }
    if (displayNameString.rangeOfString("Hans") != nil) { output = "zh" }
    if (displayNameString.rangeOfString("pt") != nil) { output = "pt" }
    if (displayNameString.rangeOfString("ko") != nil) { output = "ko" }
    if (displayNameString.rangeOfString("ja") != nil) { output = "ja" }
    if (displayNameString.rangeOfString("en-GB") != nil) { output = "en-GB" }
    
    return output
}

func sendAnalyticsEvent(name : String, parameters : [String : String]?) {
    
    // dictionnaire vide qui va contenir les paramètres
    var params = [String:String]()
    
    // si paramaters est non vide, je le recopie dans params
    if parameters != nil {
        params = parameters!
    }
    
    // J'ajoute des paramètres standard que je vais retrouver dans tous les events
    params["landscape"] = isLandscape() ? "YES" : "NO"
    params["device"] = getDevice()
    params["langage"] = getUserLanguage()
    
    Flurry.logEvent(name, withParameters: params)
}

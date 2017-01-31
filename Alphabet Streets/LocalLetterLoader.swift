//
//  LocalLetterLoader.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 03/11/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery
import MapKit
import UIKit

class LocalLetter: NSObject, NSCoding {
    let objectId: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    
    required init(letter: LetterAnnotation) {
        self.objectId = letter.objectId
        self.latitude = letter.coordinate.latitude
        self.longitude = letter.coordinate.longitude
    }
    required init(coder decoder: NSCoder) {
        self.objectId = (decoder.decodeObject(forKey: "objectId") as? String)!
        self.latitude = (decoder.decodeDouble(forKey: "latitude") as? CLLocationDegrees)!
        self.longitude = (decoder.decodeDouble(forKey: "longitude") as? CLLocationDegrees)!
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.objectId, forKey: "objectId")
        coder.encode(self.latitude, forKey: "latitude")
        coder.encode(self.longitude, forKey: "longitude")
    }
    func getCoordinate() -> CLLocationCoordinate2D{
        let coord = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        return coord
    }
}

class LocalLetterLoader {
    
    
    var points_to_upload: NSMutableArray = []
    var map: MKMapView!
    let saving_key="local_letter_dict"
    
    
    init(map: MKMapView) {
        
        self.map=map
        
        
        
        
    }
    
    func getLocalLetterDict() -> [String: LocalLetter]{
        if let data = UserDefaults.standard.data(forKey: self.saving_key),
            let local_letters = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: LocalLetter] {
            return local_letters
        } else {
            print("There is no local data to load")
            return [:]
        }
    }
    

    
    
    func saveLetter(letter: LetterAnnotation){
        
        
        
        let local_letter = LocalLetter(letter: letter)
        var local_letters = self.getLocalLetterDict()
        local_letters[local_letter.objectId]=local_letter
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: local_letters)
        UserDefaults.standard.set(encodedData, forKey: self.saving_key)


        
    }
    
   
    
    
    
    
}

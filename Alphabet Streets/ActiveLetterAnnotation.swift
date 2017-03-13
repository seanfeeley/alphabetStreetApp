//
//  ActiveLetterAnnotation.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 12/03/2017.
//  Copyright © 2017 sean-feeley. All rights reserved.
//

import Foundation
import MapKit

class ActiveLetter: NSObject, NSCoding {
    let objectId: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let original_latitude: CLLocationDegrees
    let original_longitude: CLLocationDegrees
    
    required init(letter: LetterAnnotation) {
        self.objectId = letter.objectId
        self.latitude = letter.coordinate.latitude
        self.longitude = letter.coordinate.longitude
        self.original_latitude = CLLocationDegrees(self.objectId.components(separatedBy: "/")[0])!
        self.original_longitude = CLLocationDegrees(self.objectId.components(separatedBy: "/")[1])!
    }
    
    required init(coder decoder: NSCoder) {
        self.objectId = (decoder.decodeObject(forKey: "objectId") as? String)!
        self.latitude = (decoder.decodeDouble(forKey: "latitude") as? CLLocationDegrees)!
        self.longitude = (decoder.decodeDouble(forKey: "longitude") as? CLLocationDegrees)!
        self.original_latitude = CLLocationDegrees(self.objectId.components(separatedBy: "/")[0])!
        self.original_longitude = CLLocationDegrees(self.objectId.components(separatedBy: "/")[1])!
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
    func toDict() -> [String:Any] {
        var d = Dictionary<String, Any>()
        d["objectId"]=self.objectId
        d["latitude"]=self.latitude
        d["longitude"]=self.longitude
        return d
        
    }
}

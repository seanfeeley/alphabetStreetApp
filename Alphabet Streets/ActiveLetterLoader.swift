//
//  LocalLetterLoader.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 03/11/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import Foundation
import Firebase
import MapKit
import UIKit



class ActiveLetterLoader {
    
    
    var points_to_upload: NSMutableArray = []
    var map: MKMapView!
    var ref: FIRDatabaseReference!
    var subscribe: NSObject!
    

    
    init(map: MKMapView) {
        self.map=map
        self.ref = FIRDatabase.database().reference()
       
        self.register_listeners()
    }
    
    
    func register_listeners() {
        ref.removeAllObservers()
        print(self.map.region.center.latitude - self.map.region.span.latitudeDelta/2)
        print(self.map.region.center.latitude + self.map.region.span.latitudeDelta/2)
        print(self.map.region.center.longitude - self.map.region.span.longitudeDelta/2)
        print(self.map.region.center.longitude + self.map.region.span.longitudeDelta/2)
        _ = ref.child("active").observe(FIRDataEventType.value, with: { (snapshot) in
            print("snapshot")
        })
    }
    
    func upload(_ letter: LetterAnnotation){
        let dict = letter.toDict()
        var shortentedLat=String(format: "%.2f", letter.coordinate.latitude)
        shortentedLat=shortentedLat.replacingOccurrences(of: ".", with: "_", options: .literal, range: nil)
        var shortentedLon=String(format: "%.2f", letter.coordinate.longitude)
        shortentedLon=shortentedLon.replacingOccurrences(of: ".", with: "_", options: .literal, range: nil)
        var shortentedOLat=String(format: "%.2f", letter.original_latitude)
        shortentedOLat=shortentedOLat.replacingOccurrences(of: ".", with: "_", options: .literal, range: nil)
        var shortentedOLon=String(format: "%.2f", letter.original_longitude)
        shortentedOLon=shortentedOLon.replacingOccurrences(of: ".", with: "_", options: .literal, range: nil)
        
        self.ref.child("current").child(shortentedLat).child(shortentedLon).child(letter.objectId).setValue(dict)
        self.ref.child("original").child(shortentedOLat).child(shortentedOLon).child(letter.objectId).setValue(dict)

        print("uploaded i think")
    }
}

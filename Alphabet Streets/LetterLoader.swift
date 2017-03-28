//
//  LetterLoader.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 09/12/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MapKit


class LetterLoader {
    
    let randomLetterLoader: RandomLetterLoader
    let map: MKMapView
    var selectedObjectId: String? = nil
    var ref: FIRDatabaseReference!
    var firebase_letters = [String: LetterAnnotation]()
    
    init(map: MKMapView) {
        
        self.map=map
        self.randomLetterLoader = RandomLetterLoader(map: self.map)
        self.ref = FIRDatabase.database().reference()
        
    }
    
    func register_listeners() {
        self.ref.removeAllObservers()
        let relevant_database_slices = self.getFirebaseSearchAreaStrings()
        let locations = ["current","original"]
        for location in locations{
            for (lat,lon) in relevant_database_slices{
                
                self.ref.child(location)
                    .child(lat)
                    .child(lon)
                    .observe(FIRDataEventType.childAdded, with: { (snapshot) in
                        self.reactToFirebaseChange(snapshot: snapshot as! FIRDataSnapshot)
                    })
                self.ref.child(location)
                    .child(lat)
                    .child(lon)
                    .observe(FIRDataEventType.childMoved, with: { (snapshot) in
                        self.reactToFirebaseChange(snapshot: snapshot as! FIRDataSnapshot)
                    })
                self.ref.child(location)
                    .child(lat)
                    .child(lon)
                    .observe(FIRDataEventType.childChanged, with: { (snapshot) in
                        self.reactToFirebaseChange(snapshot: snapshot as! FIRDataSnapshot)
                    })
            }
        }
    }
    
    func reactToFirebaseChange(snapshot: FIRDataSnapshot){
        let dict = snapshot.value as! Dictionary<String, String>
        let oid = dict["oid"]!
        for annotation in self.map.annotations{
            let letter = annotation as! LetterAnnotation
            if letter.objectId == oid{
                let new_lat = Double(dict["lat"]!)!
                let new_lon = Double(dict["lon"]!)!
                let coord:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: new_lat, longitude: new_lon)

                UIView.animate(withDuration: 0.2, delay:0, options: [.curveEaseOut], animations: {
                    letter.coordinate = coord
                }, completion: nil)
                
            }
        }
    }
    
    func saveLetter(_ letter: LetterAnnotation){
        letter.generateFirbaseStrings()
        let dict = letter.toDict()
        
        self.ref.child("current")
            .child(letter.firebase_lat_string)
            .child(letter.firebase_lon_string)
            .child(letter.objectId).setValue(dict)
        self.ref.child("original")
            .child(letter.firebase_olat_string)
            .child(letter.firebase_olon_string)
            .child(letter.objectId).setValue(dict)
    }
    
    
    func areLettersStillVisible() -> Bool{
        return self.randomLetterLoader.areLettersStillVisible()
        
    }
    
    func getFirebaseSearchAreaStrings() -> [(String,String)] {
        
        
        let topLeft: CLLocationCoordinate2D = self.randomLetterLoader.getMapTopLeftCoordinate()
        let bottomRight: CLLocationCoordinate2D = self.randomLetterLoader.getMapBottomRightCoordinate()
        
        var latitudes: [String] = []
        var current_lat:CLLocationDegrees = bottomRight.latitude - 0.01
        let end_lat:CLLocationDegrees = topLeft.latitude + 0.01
        while current_lat < end_lat{
            var lat_string = String(format: "%.2f", current_lat)
            lat_string=lat_string.replacingOccurrences(of: ".", with: "_", options: .literal, range: nil)
            latitudes.append(contentsOf: [lat_string])
            current_lat = current_lat + 0.01
        }
        
        var longitudes: [String] = []
        var current_lon:CLLocationDegrees = topLeft.longitude - 0.01
        let end_lon:CLLocationDegrees = bottomRight.longitude + 0.01
        while current_lon < end_lon{
            var lon_string = String(format: "%.2f", current_lon)
            lon_string=lon_string.replacingOccurrences(of: ".", with: "_", options: .literal, range: nil)
            longitudes.append(contentsOf: [lon_string])
            current_lon = current_lon + 0.01
        }
        
        var list_of_tuples:[(String,String)] = []
        for latitude in latitudes{
            for longitude in longitudes{
                list_of_tuples.append(contentsOf:[(latitude,longitude)])
            }
        }
        
        return list_of_tuples
        
        
        
    }
    
    
    func getFirebaseData(){
        self.firebase_letters.removeAll()
        let relevant_database_slices = self.getFirebaseSearchAreaStrings()
        let locations = ["current","original"]
        for location in locations{
            for (lat,lon) in relevant_database_slices{
                
                self.ref.child(location)
                    .child(lat)
                    .child(lon)
                    .observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        
                        for child in snapshot.children{
                            let data_child:FIRDataSnapshot = child as! FIRDataSnapshot
                            let dict = data_child.value as! Dictionary<String, String>
                            self.firebase_letters[dict["oid"]!] = LetterAnnotation(firebaseDict:dict)
                        }
                        if (lat,lon) == relevant_database_slices.last!
                            && location == locations.last!{
                            self.placeLetters()
                        }
                        
                        
                    }) { (error) in
                        print(error.localizedDescription)
                }
                
            }
        }
    }
    
    func placeLetters(){
        
        var oldAnnotations: [LetterAnnotation] = self.map.annotations as! [LetterAnnotation]
        
        self.register_listeners()
        for pair in self.firebase_letters{
            self.map.addAnnotation(pair.value as MKAnnotation)
        }
        let randomletters = self.randomLetterLoader.getAutoGeneratedLetters()


        
        for letter in randomletters{
            if selectedObjectId == letter.objectId{
                
            }
            else if self.firebase_letters[letter.objectId] != nil{
                
            }
            else{
                if letter.objectId != selectedObjectId{
                    self.map.addAnnotation(letter as MKAnnotation)
                }
            }
        }
        
        
        var c = 0
        for oldAnnotation in oldAnnotations{
            if (oldAnnotation.objectId == selectedObjectId)
            {
                oldAnnotations.remove(at: c)
                c=c-1
            }
            else if oldAnnotation is HoverAnnotation{
                oldAnnotations.remove(at: c)
                c=c-1
            }
            c=c+1
        }
        self.map.removeAnnotations(oldAnnotations)
    }
    
    
}

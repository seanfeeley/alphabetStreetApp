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
    var firebase_letter_oids_for_this_location: [String] = []
    var add_to_location_observers: [UInt:[String:String]] = [:]
    var remove_from_location_observers: [UInt:[String:String]] = [:]
    var object_id_observers: [String:UInt] = [:]
    var letters_added_with_this_load: Int = 0
    var current_letters_on_screen: [String:LetterAnnotation] = [:]
    var is_loading:Bool = false
    
    init(map: MKMapView) {
        
        self.map=map
        self.randomLetterLoader = RandomLetterLoader(map: self.map)
        self.ref = FIRDatabase.database().reference()
        
    }
    
    func register_listeners() {
        
        let relevant_database_slices = self.getFirebaseSearchAreaStrings()
        for (lat,lon) in relevant_database_slices{
            let handle1 = self.ref.child("by_location")
                .child(lat)
                .child(lon)
                .observe(FIRDataEventType.childAdded, with: { (snapshot) in
                    self.react_to_location_add(snapshot: snapshot as! FIRDataSnapshot)
                })
            self.add_to_location_observers[handle1] = ["lat":lat,"lon":lon]
            let handle2 = self.ref.child("by_location")
                .child(lat)
                .child(lon)
                .observe(FIRDataEventType.childRemoved, with: { (snapshot) in
                    self.react_to_location_remove(snapshot: snapshot as! FIRDataSnapshot)
                })
            self.remove_from_location_observers[handle2] = ["lat":lat,"lon":lon]
        }
        
    }
    func detatch_old_location_observers(){
        for location_observer in [self.add_to_location_observers,self.remove_from_location_observers]{
            for handle in location_observer.keys{
                let lat: String = location_observer[handle]!["lat"]!
                let lon: String = location_observer[handle]!["lon"]!
                self.ref.child("by_location")
                    .child(lat)
                    .child(lon)
                    .removeObserver(withHandle: handle)
            }
        }
        self.add_to_location_observers = [:]
        self.remove_from_location_observers = [:]
        
    }
    
    func react_to_location_add(snapshot: FIRDataSnapshot){
        let oid_observer_key = snapshot.value! as! String
        let oid = snapshot.key
        let handle = self.ref.child("by_oid")
            .child(oid)
            .observe(FIRDataEventType.value, with: { (snapshot) in
                self.firebase_letter_moved(snapshot: snapshot as! FIRDataSnapshot)
            })
        self.object_id_observers[oid_observer_key] = handle
        
    }
    func react_to_location_remove(snapshot: FIRDataSnapshot){
        let oid_observer_key = snapshot.value! as! String
        let oid = snapshot.key
        let handle = self.object_id_observers[oid_observer_key]
        self.ref.child("by_oid")
            .child(oid)
            .removeObserver(withHandle: handle!)
    }
    
    func firebase_letter_moved(snapshot: FIRDataSnapshot){
        //        print("changed!",snapshot.key)
        if snapshot.value is [String:String]{
            let firebase_dict: [String:String] = snapshot.value! as! [String:String]
            let oid = firebase_dict["oid"]!
            let lat:Double = Double(firebase_dict["lat"]!)!
            let lon:Double = Double(firebase_dict["lon"]!)!
            if oid != self.selectedObjectId{
                var to_move: LetterAnnotation?
                
                for letter in self.map.annotations as! [LetterAnnotation]{
                    if letter.objectId == oid {
                        to_move = letter
                    }
                }
                
                if (to_move != nil ){
                    UIView.animate(withDuration: 0.2, delay:0, options: [.curveEaseOut,.curveEaseIn], animations: {
                        to_move!.coordinate.latitude = lat
                        to_move!.coordinate.longitude = lon
                    }, completion: nil)
                    
                }
                else{
                    let newLetter = LetterAnnotation(firebaseDict: firebase_dict)
                    self.add_letter_annotation(newLetter)
                }
            }}
    }
    
    func saveLetter(_ letter: LetterAnnotation){
        
        let firebase_dict: [String: String] = letter.toDict()
        
        
        self.ref.child("by_oid")
            .child(firebase_dict["oid"]!)
            .observeSingleEvent(of: .value, with: { (snapshot) in
                
                if (snapshot.childrenCount != 0 ){
                    let old_data:[String:String] = snapshot.value! as! [String:String]
                    if (old_data["flat"]!+old_data["flon"]! != firebase_dict["flat"]!+firebase_dict["flon"]!){
                        self.remove_letter_data_from_location(old_data)
                    }
                }
                self.add_letter_to_firebase_database(firebase_dict)
                
                
            }) { (error) in
                print(error.localizedDescription)
        }
    }
    
    
    func remove_letter_data_from_location(_ old_data: [String:String]){
        
        self.ref.child("by_location")
            .child(old_data["flat"]!)
            .child(old_data["flon"]!)
            .child(old_data["oid"]!)
            .setValue(nil)
    }
    
    
    func add_letter_to_firebase_database(_ data: [String:String]) {
        self.ref.child("by_location")
            .child(data["flat"]!)
            .child(data["flon"]!)
            .child(data["oid"]!)
            .setValue("\(data["flat"]!):\(data["flon"]!):\(data["oid"]!)")
        self.ref.child("by_oid")
            .child(data["oid"]!)
            .setValue(data)
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
    
    
    func load_letters_via_firebase(){
        //        print("start load_letters_via_firebase")
        self.detatch_old_location_observers()
        DispatchQueue.global().async {
            if self.is_loading == false{
                self.is_loading = true
                self.firebase_letter_oids_for_this_location.removeAll()
                let relevant_database_slices = self.getFirebaseSearchAreaStrings()
                for (lat,lon) in relevant_database_slices{
                    
                    self.ref.child("by_location")
                        .child(lat)
                        .child(lon)
                        .observeSingleEvent(of: .value, with: { (snapshot) in
                            
                            
                            for child in snapshot.children{
                                self.firebase_letter_oids_for_this_location.append((child as! FIRDataSnapshot).key)
                            }
                            if (lat,lon) == relevant_database_slices.last!
                            {
                                self.load_letters()
                            }
                            
                            
                        }) { (error) in
                            print(error.localizedDescription)
                    }
                    
                    
                }
            }
        }
        
        //        print("finish load_letters_via_firebase")
    }
    
    func load_letters(){
        //        print("start load letter")
        
        let firstGroup = DispatchGroup()
        var letters_on_this_new_screen: [String:LetterAnnotation] = [:]
        for oid in self.firebase_letter_oids_for_this_location{
            
            firstGroup.enter()
            
            self.ref.child("by_oid")
                .child(oid)
                .observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.value is [String: String] {
                        let firebase_dict = snapshot.value! as! [String: String]
                        let letter_to_add = LetterAnnotation(firebaseDict: firebase_dict)
                        letters_on_this_new_screen[letter_to_add.objectId] = letter_to_add
                        if self.current_letters_on_screen[letter_to_add.objectId] == nil{
                            self.add_letter_annotation(letter_to_add)
                        }
                        
                    }
                    firstGroup.leave()
                })
            
        }
        
        // called once all code blocks entered into group have left
        firstGroup.notify(queue: DispatchQueue.main){
            
            //            print("finished")
            let randomletters = self.randomLetterLoader.getAutoGeneratedLetters()
            for letter in randomletters{
                letters_on_this_new_screen[letter.objectId] = letter
                if self.current_letters_on_screen[letter.objectId] == nil{
                    self.add_letter_annotation(letter)
                }
            }
            for oid in self.current_letters_on_screen.keys{
                if letters_on_this_new_screen[oid] == nil {
                    self.map.removeAnnotation(self.current_letters_on_screen[oid]!)
                    self.current_letters_on_screen.removeValue(forKey: oid)
                }
            }
            
            
            self.is_loading = false
            
            self.register_listeners()
            
            
        }
        
        
        
        
    }
    
    
    func remove_letter_annotation(_ letter: LetterAnnotation){
        if letter.objectId != self.selectedObjectId{
            self.map.removeAnnotation(letter as MKAnnotation)
            self.current_letters_on_screen.removeValue(forKey: letter.objectId)
        }
    }
    func add_letter_annotation(_ letter: LetterAnnotation){
        
        if letter.objectId == self.selectedObjectId{
            let hover_letter = HoverAnnotation(letter: letter)
            hover_letter.animate_in = true
            self.map.addAnnotation(hover_letter)
            
        }
        letter.animate_in = true
        self.map.addAnnotation(letter as MKAnnotation)
        self.current_letters_on_screen[letter.objectId] = letter
        
        if letter.objectId == self.selectedObjectId{
            letter.start_hovering_on_map(map: self.map)
        }
        
    }
    
    
    
 }

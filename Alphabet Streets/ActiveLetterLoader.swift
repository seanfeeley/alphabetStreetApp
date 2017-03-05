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


extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}
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

class RemoteLetter: PFObject, PFSubclassing {
    @NSManaged var  oid: String?
    @NSManaged var  clat: String?
    @NSManaged var  clon: String?
    @NSManaged var  olat: String?
    @NSManaged var  olon: String?
    
    class func parseClassName() -> String {
        return "ActiveLetters"
    }
}


class LocalLetterLoader {
    var data_saving_key: String
    
    init(data_saving_key: String){
        self.data_saving_key=data_saving_key
    }
    
    
    func getAllLetters() -> [String: ActiveLetter]{
        if let data = UserDefaults.standard.data(forKey: self.data_saving_key),
            let local_letters = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: ActiveLetter] {
            
            
            return local_letters
        } else {
            
            return [:]
        }
    }
    
    func addLetterToData(letter: ActiveLetter){
        var local_letters = self.getAllLetters()
        local_letters[letter.objectId]=letter
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: local_letters)
        UserDefaults.standard.set(encodedData, forKey: self.data_saving_key)
    }
    
    
}

class ActiveLetterLoader {
    
    
    var points_to_upload: NSMutableArray = []
    var map: MKMapView!
    let localDataLoader = LocalLetterLoader(data_saving_key: "active_letter_dict")
    let remoteDataLoader = LocalLetterLoader(data_saving_key: "remote_letter_dict")
    var subscription: Subscription<RemoteLetter>?
    let liveQueryClient = ParseLiveQuery.Client()
    var liveQuery: PFQuery<RemoteLetter> {
        return (RemoteLetter.query()?
            .whereKey("oid", notEqualTo: "whatever")
            .order(byAscending: "oid")) as! PFQuery<RemoteLetter>
    }
    
    
    
    init(map: MKMapView) {
        self.map=map
        self.subscribeToRemoteUpdates()
    }
    
    func subscribeToRemoteUpdates(){
        liveQuery.findObjectsInBackground(block: {(remote_letters, error) -> Void in
            print("live:\(remote_letters!.count)")
        })
        
        self.subscription = liveQueryClient
            .subscribe(liveQuery)
            .handle(Event.updated) { _, remote_letter in
                print("cunt")
        }

        }
    
    
    func getLocalLetterDict() -> [String: ActiveLetter]{
        var data = self.remoteDataLoader.getAllLetters()
        let local_data = self.localDataLoader.getAllLetters()
        print("Local:\(local_data.count) Remote:\(data.count)")
        data.update(other: local_data)
        
        return data
    }
    
    func saveLetter(letter: LetterAnnotation){
        let local_letter = ActiveLetter(letter: letter)
        self.localDataLoader.addLetterToData(letter: local_letter)
        self.upload(local_letter: local_letter)
        
    }
    
    
    func upload(local_letter: ActiveLetter){
        let query = PFQuery(className: "ActiveLetters")
        query.whereKey("oid", equalTo: local_letter.objectId)
        query.findObjectsInBackground { (objects, error) -> Void in
            if error == nil {
                var objectToSave:PFObject = PFObject(className: "ActiveLetters")
                if objects!.count != 0{
                    objectToSave = objects![0]
                }
                objectToSave["clat"] = local_letter.latitude
                objectToSave["clon"] = local_letter.longitude
                objectToSave["olat"] = local_letter.original_latitude
                objectToSave["slon"] = local_letter.original_longitude
                objectToSave["oid"] = local_letter.objectId
                objectToSave.saveInBackground(block: { (success, error) -> Void in
                    if error == nil {
                        if objects!.count != 0{
                            print("Successful Update")
                        }
                        else{
                            print("Successful Upload")

                        }
                        
                    } else {
                        print("Failed Upload")
                    }
                })
            }
        }
    }
    
    
    
    
   
    
    
    
    
}

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
        self.register()
    }
    
    
    func register() {
        RemoteLetter.registerSubclass()
        
        let remoteQ: PFQuery<RemoteLetter>  = RemoteLetter.query()!.whereKey("oid", notEqualTo: "whatever") as! PFQuery<RemoteLetter>
        remoteQ.findObjectsInBackground { (objects, errors) in
            print(objects)
            print(errors)
        }
        self.subscription = liveQueryClient.subscribe(remoteQ).handleSubscribe { [weak self]  (_) in
            print("Subbed")
            }.handleEvent { [weak self] (_, event) in
                self?.handleEvent(event: event)
        }
        
    }
    
    func handleEvent(event: Event<RemoteLetter>) {
        // Make sure we're on main thread
        if Thread.current != Thread.main {
            return DispatchQueue.main.async { [weak self] _ in
                self?.handleEvent(event: event)
            }
        }
        
        switch event {
        case .created(let obj),
             .entered(let obj):
            print("Object is entered!")
            
        case .updated(let obj):
            print("Object is updated!")
            
        case .deleted(let obj),
             .left(let obj):
            print("Object is deleted!")
        }
    }
    
    
    func getLocalLetterDict() -> [String: ActiveLetter]{
        var data = self.remoteDataLoader.getAllLetters()
        let local_data = self.localDataLoader.getAllLetters()
        print("Local:\(local_data.count) Remote:\(data.count)")
        data.update(local_data)
        
        return data
    }
    
    func saveLetter(_ letter: LetterAnnotation){
        let local_letter = ActiveLetter(letter: letter)
        self.localDataLoader.addLetterToData(local_letter)
        self.upload(local_letter)
        
    }
    
    
    func upload(_ local_letter: ActiveLetter){
        let query = PFQuery(className: "ActiveLetters")
        query.whereKey("oid", equalTo: local_letter.objectId)
        query.findObjectsInBackground { (objects, error) -> Void in
            if error == nil {
                var objectToSave:RemoteLetter
                if objects!.count != 0 {
                    objectToSave = objects![0] as! RemoteLetter
                }
                objectToSave = RemoteLetter(letter: local_letter)
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

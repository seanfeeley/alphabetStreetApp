//
//  RemoteLetterLoader.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 03/11/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery
import MapKit

class RemoteLetterLoader {
    
    
    var points_to_upload: NSMutableArray = []
    var map: MKMapView!
    
    
    init(map: MKMapView) {
        
        self.map=map
        
    }
    
    func download() -> Void {
        let query = PFQuery(className: "ActiveLetters")
        query.findObjectsInBackground { (objects, error) -> Void in
                            print("entering")
            
                            if error == nil {
                                print("Query found \(objects!.count) objects")
                                for object in objects!{
                                    print(object)
            
                                }
                                
                            }
            
            
                            print("exiting")
                        }

        
        
    }
    
    
   
    
    //    func loadInPoints(){
    //
    //        if self.loadingPointsIn==false{
    //            self.loadingPointsIn=true
    //
    //            self.newPointsLoadedIn=false
    //            if draggingPoint != nil{
    //                return
    //            }
    //            self.already_existing_ids = []
    //            for a in map.annotations{
    //                let ca = a as! CustomPointAnnotation
    //                already_existing_ids.append(ca.objectId)
    //            }
    //
    //
    //            self.points_to_remove=[]
    //            for a in self.map.annotations{
    //                self.points_to_remove.add(a)
    //            }
    //
    //
    //            let query = PFQuery(className: "ActiveLetters")
    //            let mRect = self.map.visibleMapRect;
    //            let neMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), mRect.origin.y);
    //            let swMapPoint = MKMapPointMake(mRect.origin.x, MKMapRectGetMaxY(mRect));
    //            let neCoord = MKCoordinateForMapPoint(neMapPoint);
    //            let swCoord = MKCoordinateForMapPoint(swMapPoint);
    //
    //            let latDiff = neCoord.latitude - swCoord.latitude
    //            let lonDiff = neCoord.longitude - swCoord.longitude
    //            query.whereKey("latitude", lessThan: neCoord.latitude + latDiff)
    //            query.whereKey("latitude", greaterThan: swCoord.latitude - latDiff)
    //            query.whereKey("longitude", lessThan: neCoord.longitude + lonDiff)
    //            query.whereKey("longitude", greaterThan: swCoord.longitude - lonDiff)
    //            query.limit = 1000
    //            //        print(neCoord.latitude + latDiff,swCoord.latitude - latDiff, neCoord.longitude + lonDiff,swCoord.longitude - lonDiff)
    //            query.findObjectsInBackground { (objects, error) -> Void in
    //                print("entering")
    //                self.newPointsLoadedIn=false
    //
    //                if error == nil {
    //                    print("Query found \(objects!.count) objects")
    //                    for object in objects!{
    //                        let objectId: String=object.objectId! as String
    //
    //
    //                        let a = self.addAnnotation(object)
    //
    //                        if a != nil{
    //                            self.points_to_remove.remove(a!)
    //
    //                        }
    //
    //
    //                    }
    //                    //                self.map.removeAnnotations(self.points_to_remove as! [MKAnnotation])
    //
    //                }
    //
    //                self.newPointsLoadedIn=true
    //                print("exiting")
    //            }
    //
    //            //self.subscription = query.subscribe().handle(Event.Updated) { _, object in
    //            //
    //            //    self.points_to_move.addObject(object)
    //            //
    //            //
    //            //}
    //
    //            //       uploadPoints()
    //            self.loadingPointsIn=false
    //            self.centerPointAtLastPointLoad=CLLocation(latitude:  self.map.region.center.latitude,longitude:  self.map.region.center.longitude)
    //        }
    //        
    //        
    //    }
    
    
    
    
}

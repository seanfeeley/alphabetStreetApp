//
//  ViewController.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 17/07/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import UIKit
import Parse
import MapKit
import Foundation
import ParseLiveQuery




import SystemConfiguration
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}



class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    
    var draggingPoint: CustomPointAnnotation? = nil
    var hoverPoint: CustomPointAnnotation? = nil
    var draggingMapPoint: CLLocation? = nil
    var centerPointAtLastPointLoad: CLLocation? = nil
    var already_existing_ids:[String] = []
    var points_to_remove: NSMutableArray = []
    var points_to_move: NSMutableArray = []
    var points_to_add: NSMutableArray = []
    var points_to_upload: NSMutableArray = []
    var touchPoint:CGPoint? = nil
    
    
    var drapPanTimer:Timer? = nil
    var dragPanLat=0.0
    var dragPanLon=0.0
    
    var location:CLLocation? = nil
    var subscription: Subscription<PFObject>?
    
    var loadingPointsIn:Bool = false
    var uploadingPoints:Bool = false
    var newPointsLoadedIn:Bool = false
    
    
    var reachabilityNotice:Bool = false

    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        centerMap()
        registerListeners()
        //        loadInPoints()
        //
        
        
        
        let movePointsTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.moveAnnotations), userInfo: nil, repeats: true)
        let loadPointsTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.loadAnnotations), userInfo: nil, repeats: true)
        let uploadPointsTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.uploadAnnotations), userInfo: nil, repeats: true)
        
        
        //        let addPointsTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ViewController.loadNewPoints), userInfo: nil, repeats: true)
        //        self.loadNewPoints()
    }
    
    func uploadAnnotations(){
        
        
  
            if self.uploadingPoints==false{
                
                self.uploadingPoints=true
                for object in self.points_to_upload{
                    self.uploadAnnotation(obj: object as! Array<Any>)
                    self.points_to_upload.remove(object)
                    
                }
                self.uploadingPoints=false
            }
            
        
        
        
        
        
    }
    
    
    
    func moveAnnotations(){
        
        
            for object in self.points_to_move{
                self.moveAnnotation(object as! PFObject)
                self.points_to_move.remove(object)
                
            }
        
        
    }
    func loadAnnotations(){
        
        
            if newPointsLoadedIn && self.points_to_add.count != 0{
                //            print("    placing:",self.points_to_add.count,"removing:",self.points_to_remove.count)
                
                
                
                self.map.addAnnotations(self.points_to_add as! [MKAnnotation])
                self.points_to_add=[]
                self.map.removeAnnotations(self.points_to_remove as! [MKAnnotation])
                self.points_to_remove=[]
                self.newPointsLoadedIn=false
            }
        
        
    }
    
    
    @IBAction func homeButton(_ sender: AnyObject) {
        self.drapPanTimer?.invalidate()
        print(self.drapPanTimer)
        self.loadingPointsIn=false
        recenterMap()
        loadInPoints()
        self.loadingPointsIn=false
        
    }
    
    func loadNewPoints(){
        print("LOAD IN NEWBIES")
        for a in (0...100){
            let lat=arc4random_uniform(8000000)
            let lon=arc4random_uniform(12000000)
            let latitude = 50+Float(lat)/1000000.0
            let longitude = 2-Float(lon)/1000000.0
            createPoint(latitude,longitude: longitude)
            
        }
    }
    
    
    func centerMap(){
        
        
        map.delegate=self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        
        recenterMap()
    }
    func recenterMap(){
        
        
        let latDelta: CLLocationDegrees = 0.17
        let lonDelta: CLLocationDegrees = 0.17
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        
        var l = self.location
        
        if l == nil {
            let latitude: CLLocationDegrees = 0
            let longitude: CLLocationDegrees = 0
            
            l = CLLocation(latitude: latitude, longitude: longitude)
        }
        
        let region:MKCoordinateRegion =  MKCoordinateRegionMake(l!.coordinate, span)
        
        map.setRegion(region, animated: false)
        
        
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        
        if self.location == nil {
            self.location = locations[locations.count-1]
            
            recenterMap()
            loadInPoints()
        }
        
        
        
        
    }
    
    func uploadPoints(){
        
        for a in self.map.annotations{
            
            let ca = a as! CustomPointAnnotation
            
            if ca.toUpdate == true
            {
                
            }
            
        }
        
        
        
    }
    
    func loadInPoints(){
        
        if self.loadingPointsIn==false{
            self.loadingPointsIn=true
            
            self.newPointsLoadedIn=false
            if draggingPoint != nil{
                return
            }
            self.already_existing_ids = []
            for a in map.annotations{
                let ca = a as! CustomPointAnnotation
                already_existing_ids.append(ca.objectId)
            }
            
            
            self.points_to_remove=[]
            for a in self.map.annotations{
                self.points_to_remove.add(a)
            }
            
            
            let query = PFQuery(className: "ActiveLetters")
            let mRect = self.map.visibleMapRect;
            let neMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), mRect.origin.y);
            let swMapPoint = MKMapPointMake(mRect.origin.x, MKMapRectGetMaxY(mRect));
            let neCoord = MKCoordinateForMapPoint(neMapPoint);
            let swCoord = MKCoordinateForMapPoint(swMapPoint);
            
            let latDiff = neCoord.latitude - swCoord.latitude
            let lonDiff = neCoord.longitude - swCoord.longitude
            query.whereKey("latitude", lessThan: neCoord.latitude + latDiff)
            query.whereKey("latitude", greaterThan: swCoord.latitude - latDiff)
            query.whereKey("longitude", lessThan: neCoord.longitude + lonDiff)
            query.whereKey("longitude", greaterThan: swCoord.longitude - lonDiff)
            query.limit = 1000
            //        print(neCoord.latitude + latDiff,swCoord.latitude - latDiff, neCoord.longitude + lonDiff,swCoord.longitude - lonDiff)
            query.findObjectsInBackground { (objects, error) -> Void in
                print("entering")
                self.newPointsLoadedIn=false
                
                if error == nil {
                    print("Query found \(objects!.count) objects")
                    for object in objects!{
                        let objectId: String=object.objectId! as String
                        
                        
                        let a = self.addAnnotation(object)
                        
                        if a != nil{
                            self.points_to_remove.remove(a!)
                            
                        }
                        
                        
                    }
                    //                self.map.removeAnnotations(self.points_to_remove as! [MKAnnotation])
                    
                }
                
                self.newPointsLoadedIn=true
                print("exiting")
            }
            
            //self.subscription = query.subscribe().handle(Event.Updated) { _, object in
            //
            //    self.points_to_move.addObject(object)
            //
            //
            //}
            
            //       uploadPoints()
            self.loadingPointsIn=false
            self.centerPointAtLastPointLoad=CLLocation(latitude:  self.map.region.center.latitude,longitude:  self.map.region.center.longitude)
        }
        
        
    }
    
    
    
    func registerListeners(){
        let uiplgr = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.action(_:)))
        //
        uiplgr.minimumPressDuration = 0.05
        //
        map.addGestureRecognizer(uiplgr)
        
    }
    func createPoint(_ latitude: Float, longitude: Float){
        let o = PFObject(className: "ActiveLetters")
        
        print(o)
        o["latitude"] = latitude
        o["longitude"] = longitude
        
        o.saveInBackground()
    }
    
    func uploadAnnotation(obj: Array<Any>){
        let query = PFQuery(className: "ActiveLetters")
        query.whereKey("objectId", equalTo: obj[0])
        query.findObjectsInBackground { (
            objects, error) in
            let prefObj = objects![0]
            prefObj["latitude"] = obj[1]
            prefObj["longitude"] = obj[2]
            prefObj.saveEventually()
        }
        
        //                        query.getObjectInBackgroundWithId(dic[0]){
        //                            (prefObj: PFObject?, error: NSError?) -> Void in
        //                            if error != nil {
        //                                print(error)
        //                            } else if let prefObj = prefObj{
        //                                    prefObj["latitude"] = dic[1]
        //                                    prefObj["longitude"] = dic[2]
        //                                    prefObj.saveEventually()
        //                            }
        //                        }
        
    }
    
    func moveAnnotation(_ dic: PFObject){
        
        let objectId: String=dic.objectId! as String
        
        for a in self.map.annotations{
            let ca = a as! CustomPointAnnotation
            //            print("  ",ca.objectId)
            
            if ca.objectId == objectId{
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                    ca.coordinate.longitude=dic["longitude"] as! CLLocationDegrees
                    ca.coordinate.latitude=dic["latitude"] as! CLLocationDegrees
                    }, completion: { (finished: Bool) -> Void in
                })
            }
        }
        
    }
    
    func addAnnotation(_ dic: PFObject) -> MKAnnotation?{
        var letter="a"
        let letterset = CharacterSet.controlCharacters
        let objectId: String=dic.objectId! as String
        
        
        
        
        if self.already_existing_ids.contains(objectId){
            
            
            
            for a in self.map.annotations{
                let ca = a as! CustomPointAnnotation
                if ca.objectId == objectId{
                    
                    if ca.toUpdate != true{
                        ca.coordinate.longitude=dic["longitude"] as! CLLocationDegrees
                        ca.coordinate.latitude=dic["latitude"] as! CLLocationDegrees
                        
                    }
                    
                    
                    return ca
                }
                
                
            }
            
        }
        else{
            
            var bytes = ""
            for char in objectId.utf8{
                bytes = bytes + String(char)
            }
            
            
            
            
            
            letter="letter_16_00"
            
            return addAnnotation(dic["latitude"] as! CLLocationDegrees, longitude: dic["longitude"] as! CLLocationDegrees, letter: letter, objectId: objectId)
        }
        return nil
    }
    
    
    func addAnnotation(_ latitude: CLLocationDegrees, longitude: CLLocationDegrees, letter: String, objectId: String) -> MKAnnotation?{
        let latitude: CLLocationDegrees = latitude
        let longitude: CLLocationDegrees = longitude
        
        let location: CLLocationCoordinate2D=CLLocationCoordinate2DMake(latitude, longitude)
        let annotation = CustomPointAnnotation()
        annotation.letter=letter
        annotation.objectId=objectId
        annotation.coordinate = location
        
        
        var contains:Bool=false
        for a in self.points_to_add{
            if (a as AnyObject).objectId == annotation.objectId{
                contains=true
            }
        }
        if contains == false{
            self.points_to_add.add(annotation)
        }
        else{
            //            self.points_to_add.addObject(annotation)
            
        }
        //                    self.map.addAnnotation(annotation)
        
        
        return annotation
    }
    
    
    
    
    
    func action(_ gestureRecognizer: UIGestureRecognizer) -> Bool{
        //        print(self.map.annotations)
        //
        
        
        
        self.touchPoint = gestureRecognizer.location(in: self.map)
        
        let newCoord: CLLocationCoordinate2D = map.convert(self.touchPoint!,toCoordinateFrom: self.map)
        let newLocation: CLLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
        
        //        createPoint(newCoord.latitude as Double,longitude: newCoord.longitude as Double)
        //        return true
        
        
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            self.drapPanTimer?.invalidate()
            var closest:MKAnnotation? = nil
            var closestDist:CLLocationDistance? = nil
            
            for annotation in self.map.annotations{
                let otherLocation: CLLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                let meters = newLocation.distance(from: otherLocation)
                if closestDist==nil || meters < closestDist{
                    closest=annotation
                    closestDist=meters
                }
                
                
                
            }
            
            var detectable:CLLocationDistance = 1000
            
            if UIDevice.current.model=="iPhone"{
                detectable=1000
            }
            else if UIDevice.current.model=="iPad"{
                detectable=500
            }
            else{
                detectable=1000
                
            }
            
            
            if closestDist < detectable && closest != nil {
                draggingPoint = closest as! CustomPointAnnotation
                UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                    self.draggingPoint!.coordinate.latitude = newCoord.latitude+0.01
                    self.draggingPoint!.coordinate.longitude = newCoord.longitude
                    }, completion: { (finished: Bool) -> Void in
                })
                
                
                self.hoverPoint = CustomPointAnnotation()
                self.hoverPoint?.coordinate = newCoord
                self.hoverPoint?.letter="hover"
                self.map.addAnnotation(self.hoverPoint!)
            }
            else{
                draggingMapPoint=newLocation
                
            }
            
            
        }
        else if gestureRecognizer.state == UIGestureRecognizerState.changed {
            
            if draggingPoint != nil{
                
                UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                    self.draggingPoint!.coordinate.latitude = newCoord.latitude+0.01
                    self.draggingPoint!.coordinate.longitude = newCoord.longitude
                    }, completion: { (finished: Bool) -> Void in
                })
                
                self.hoverPoint?.coordinate=newCoord
                
                
                
                    var toPan = false
                    let right = UIScreen.main.bounds.width - self.touchPoint!.x
                    let moveRight = 0.002 - right/100000
                    if moveRight > 0{
                        self.dragPanLon = Double(moveRight)
                        toPan = true
                    }
                    let left = self.touchPoint!.x
                    let moveLeft = 0.002 - left/100000
                    if moveLeft > 0{
                        self.dragPanLon = Double(-moveLeft)
                        toPan = true
                    }
                
                let top = self.touchPoint!.y
                
                let moveTop = 0.002 - top/100000
                if moveTop > 0{
                    self.dragPanLat = Double(moveTop)
                    toPan = true
                }
                let bottom = UIScreen.main.bounds.height - self.touchPoint!.y
               
                let moveBottom = 0.002 - bottom/100000
                if moveBottom > 0{
                    self.dragPanLat = Double(-moveBottom)
                    toPan = true
                }
                
                
                if toPan{
                    if self.drapPanTimer == nil || self.drapPanTimer?.isValid == false{
                        self.drapPanTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.dragPan), userInfo: nil, repeats: true)
                        
                    }
                }
                else{
                    self.drapPanTimer?.invalidate()

                }

                
                

                
                
                
                
            }
            else if draggingMapPoint != nil{
                self.drapPanTimer?.invalidate()
                let center = map.centerCoordinate
                let newCenter = CLLocation(latitude: center.latitude-(newLocation.coordinate.latitude-draggingMapPoint!.coordinate.latitude), longitude: center.longitude-(newLocation.coordinate.longitude-draggingMapPoint!.coordinate.longitude))
                map.setCenter(newCenter.coordinate, animated: false)
                
                
                
            }
            
        }else if gestureRecognizer.state == UIGestureRecognizerState.ended {
            self.drapPanTimer?.invalidate()
            
            if draggingPoint != nil{
                
         
                
                
                UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                    self.draggingPoint!.coordinate = newCoord
                    }, completion: { (finished: Bool) -> Void in
                })
                draggingPoint!.coordinate = newCoord
                let uploadList = [draggingPoint!.objectId,draggingPoint!.coordinate.latitude,draggingPoint!.coordinate.longitude] as [Any]
                self.map.removeAnnotation(self.hoverPoint!)
                self.hoverPoint=nil
                self.draggingPoint = nil
                
                
                self.points_to_upload.add(uploadList)
                
                
                
                
                
                
            }
            else{
                self.drapPanTimer?.invalidate()
                //                loadInPoints()
                draggingMapPoint = nil
            }
        }
        
        return true
    }
    
    
    
    func dragPan(){
        
        
        self.map.region.center.latitude=self.map.region.center.latitude+self.dragPanLat
        self.map.region.center.longitude=self.map.region.center.longitude+self.dragPanLon
        
    }
    
    
    
    func resizeImage(_ image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
        
        let locationNow=CLLocation(latitude:  self.map.region.center.latitude,longitude:  self.map.region.center.longitude)
        
        if self.centerPointAtLastPointLoad != nil && locationNow.distance(from: self.centerPointAtLastPointLoad!) > 10000{
            self.loadInPoints()
        }
        
        
        
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        if !(annotation is CustomPointAnnotation) {
            return nil
        }
        
        return getAnViewForAnnotation(mapView, annotation: annotation)
        
        
    }
    func getAnViewForAnnotation(_ mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView {
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            
            anView!.canShowCallout = true
        }
        else {
            anView!.annotation = annotation
        }
        
        //Set annotation-specific properties **AFTER**
        //the view is dequeued or created...
        
        let cpa = annotation as! CustomPointAnnotation
        let image=UIImage(named:"\(cpa.letter.lowercased()).png")
        if image != nil{
            
            
            
            var pixels:CGFloat = 64.0
            if UIDevice.current.model=="iPhone"{
                
                pixels=32
            }
            else if UIDevice.current.model=="iPad"{
                pixels=50
            }
            else{
                pixels=32
                
            }
            
            
            
            
            anView!.image = resizeImage(image!,newWidth: pixels)
            
        }
        else{
            print(cpa.letter.lowercased())
        }
        
        
        
        
        
        return anView!
        
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
class CustomPointAnnotation: MKPointAnnotation {
    var letter: String!
    var objectId: String = "xxxxxx"
    
    var toUpdate: Bool = false
    
}


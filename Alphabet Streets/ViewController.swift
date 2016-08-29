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




class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    
    var draggingPoint: CustomPointAnnotation? = nil
    var draggingMapPoint: CLLocation? = nil
    var already_existing_ids:[String] = []
    var points_to_remove: NSMutableArray = []
    var points_to_move: NSMutableArray = []
    var points_to_add: NSMutableArray = []
    var location:CLLocation? = nil
    var subscription: Subscription<PFObject>?
    
    var newPointsLoadedIn:Bool = false
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        centerMap()
        registerListeners()
//        loadInPoints()
//
        let movePointsTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(ViewController.moveAnnotations), userInfo: nil, repeats: true)
//        let loadPointsTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(ViewController.loadAnnotations), userInfo: nil, repeats: true)
        
        
//        let addPointsTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ViewController.loadNewPoints), userInfo: nil, repeats: true)
//        self.loadNewPoints()
    }
    

    func moveAnnotations(){
        
        
        for object in self.points_to_move{
            self.moveAnnotation(object as! PFObject)
            self.points_to_move.removeObject(object)
            
        }
        
        
    }
    func loadAnnotations(){
        if newPointsLoadedIn{
            print(self.points_to_add.count,self.points_to_remove.count)
            self.map.addAnnotations(self.points_to_add as! [MKAnnotation])
            self.points_to_add=[]
            self.map.removeAnnotations(self.points_to_remove as! [MKAnnotation])
            self.points_to_remove=[]
            self.newPointsLoadedIn=false
        }


    }
    
    
    @IBAction func homeButton(sender: AnyObject) {
        
        recenterMap()
        loadInPoints()
        
        
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
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        
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
            self.points_to_remove.addObject(a)
        }
        
        
        let query = PFQuery(className: "Letters")
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
        print(neCoord.latitude + latDiff,swCoord.latitude - latDiff, neCoord.longitude + lonDiff,swCoord.longitude - lonDiff)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            if error == nil {
                print("Query found \(objects?.count) objects")
                for object in objects!{
                    let objectId: String=object.objectId! as String
                    
                    
                    let a = self.addAnnotation(object)
                    
                    if a != nil{
                        self.points_to_remove.removeObject(a!)
                        
                    }
                    
                    
                }
                self.map.removeAnnotations(self.points_to_remove as! [MKAnnotation])
               
                
            } else {
                print("Error")
            }
        }
    
        self.subscription = query.subscribe().handle(Event.Updated) { _, object in

             self.points_to_move.addObject(object)

            
        }
       
       uploadPoints()
       self.newPointsLoadedIn=true
       
       
        
    }
    func registerListeners(){
        let uiplgr = UILongPressGestureRecognizer(target: self, action: Selector("action:"))
        //
        uiplgr.minimumPressDuration = 0
        //
        map.addGestureRecognizer(uiplgr)
        
    }
    func createPoint(latitude: Float, longitude: Float){
        let o = PFObject(className: "Letters")
        o["latitude"] = latitude
        o["longitude"] = longitude
        
        o.saveInBackground()
    }
    
    func moveAnnotation(dic: PFObject){

        let objectId: String=dic.objectId! as String

        for a in self.map.annotations{
            let ca = a as! CustomPointAnnotation
            print("  ",ca.objectId)
            if ca.objectId == objectId{
                    UIView.animateWithDuration(0.5, delay: 1.0, options: UIViewAnimationOptions.TransitionNone, animations: { () -> Void in
                        ca.coordinate.longitude=dic["longitude"] as! CLLocationDegrees
                        ca.coordinate.latitude=dic["latitude"] as! CLLocationDegrees
                    }, completion: { (finished: Bool) -> Void in
                    })
            }
        }
        
    }
    
    func addAnnotation(dic: PFObject) -> MKAnnotation?{
        var letter="a"
        let letterset = NSCharacterSet.controlCharacterSet()
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
            let allLetters: [String] = ["a","a","a","a","a",
                                        "b","b",
                                        "c","c",
                                        "d","d","d","d",
                                        "e","e","e","e","e",
                                        "f","f",
                                        "g","g","g",
                                        "h","h",
                                        "i","i","i","i","i",
                                        "j","j",
                                        "k","k",
                                        "l","l","l","l",
                                        "m","m",
                                        "n","n","n","n","n",
                                        "o","o","o","o","o",
                                        "p","p",
                                        "q",
                                        "r","r","r","r","r",
                                        "s","s","s","s",
                                        "t","t","t","t","t",
                                        "u","u","u","u",
                                        "v","v",
                                        "w","w",
                                        "x","x",
                                        "y","y",
                                        "z", "z",
                                        ]
            
            let u = UInt32(bytes.substringToIndex(bytes.startIndex.advancedBy(4)))!
            srand(u)
            let index:Int = Int(rand()%Int32(allLetters.count))
            
            
            letter=allLetters[index]
            
            
            return addAnnotation(dic["latitude"] as! CLLocationDegrees, longitude: dic["longitude"] as! CLLocationDegrees, letter: letter, objectId: objectId)
        }
        return nil
    }
    
    
    func addAnnotation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, letter: String, objectId: String) -> MKAnnotation?{
        let latitude: CLLocationDegrees = latitude
        let longitude: CLLocationDegrees = longitude
        
        let location: CLLocationCoordinate2D=CLLocationCoordinate2DMake(latitude, longitude)
        let annotation = CustomPointAnnotation()
        annotation.letter=letter
        annotation.objectId=objectId
        annotation.coordinate = location
        
        
//        var contains:Bool=false
//        for a in self.points_to_add{
//            if a.objectId == annotation.objectId{
//                contains=true
//            }
//        }
//        if contains == false{
//            self.points_to_add.addObject(annotation)
//        }
//        else{
//            self.points_to_add.addObject(annotation)
//
//        }
                    self.map.addAnnotation(annotation)
        

        return annotation
    }
    
    
    
    
    
    func action(gestureRecognizer: UIGestureRecognizer) -> Bool{
        //        print(self.map.annotations)
        //
        
        
        
        let touchPoint = gestureRecognizer.locationInView(self.map)
        
        let newCoord: CLLocationCoordinate2D = map.convertPoint(touchPoint,toCoordinateFromView: self.map)
        let newLocation: CLLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
        
        //        createPoint(newCoord.latitude as Double,longitude: newCoord.longitude as Double)
        //        return true
        
        
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            var closest:MKAnnotation? = nil
            var closestDist:CLLocationDistance? = nil
            
            for annotation in self.map.annotations{
                let otherLocation: CLLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                let meters = newLocation.distanceFromLocation(otherLocation)
                if closestDist==nil || meters < closestDist{
                    closest=annotation
                    closestDist=meters
                }
                
                
                
            }
            
            var detectable:CLLocationDistance = 1000
            
            if UIDevice.currentDevice().model=="iPhone"{
                detectable=1000
            }
            else if UIDevice.currentDevice().model=="iPad"{
                detectable=500
            }
            else{
                detectable=1000
                
            }
            
            
            if closestDist < detectable && closest != nil {
                draggingPoint = closest as! CustomPointAnnotation
                draggingPoint!.coordinate = newCoord
            }
            else{
                draggingMapPoint=newLocation
            }
            
            
        }
        else if gestureRecognizer.state == UIGestureRecognizerState.Changed {
            
            if draggingPoint != nil{
                draggingPoint!.coordinate = newCoord
            }
            else if draggingMapPoint != nil{
                let center = map.centerCoordinate
                let newCenter = CLLocation(latitude: center.latitude-(newLocation.coordinate.latitude-draggingMapPoint!.coordinate.latitude), longitude: center.longitude-(newLocation.coordinate.longitude-draggingMapPoint!.coordinate.longitude))
                map.setCenterCoordinate(newCenter.coordinate, animated: false)
                
            }
            
        }else if gestureRecognizer.state == UIGestureRecognizerState.Ended {
            if draggingPoint != nil{
                
                let oid = draggingPoint!.objectId
                
                
                
                
                let query = PFQuery(className: "Letters")
                query.getObjectInBackgroundWithId(draggingPoint!.objectId){
                    (prefObj: PFObject?, error: NSError?) -> Void in
                    if error != nil {
                        
                        print(error)
                    } else if let prefObj = prefObj{
                        if self.draggingPoint != nil{
                            prefObj["latitude"] = self.draggingPoint!.coordinate.latitude
                            prefObj["longitude"] = self.draggingPoint!.coordinate.longitude
                            prefObj.saveEventually()
                            self.draggingPoint = nil
                        }
                      
                        
                        
                        
                        
                        
                    }
                }
                
                
                
                
                
            }
            else{
                loadInPoints()
                draggingMapPoint = nil
            }
        }
        
        return true
    }
    
    
    
    

    
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
      
        
        if !(annotation is CustomPointAnnotation) {
            return nil
        }
        
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        
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
        let image=UIImage(named:"\(cpa.letter.lowercaseString).png")
        if image != nil{
            
            
            
            var pixels:CGFloat = 64.0
            
            if UIDevice.currentDevice().model=="iPhone"{
                pixels=32
            }
            else if UIDevice.currentDevice().model=="iPad"{
                pixels=50
            }
            else{
                pixels=32

            }
          
            
            
            anView!.image = resizeImage(image!,newWidth: pixels)
            
        }
        else{
            print(cpa.letter.lowercaseString)
        }
        
        
        
        
        
        return anView
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
class CustomPointAnnotation: MKPointAnnotation {
    var letter: String!
    var objectId: String!
    
    var toUpdate: Bool = false
    
}


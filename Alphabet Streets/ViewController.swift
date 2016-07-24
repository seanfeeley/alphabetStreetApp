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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    var draggingPoint: CustomPointAnnotation? = nil
    var draggingMapPoint: CLLocation? = nil
    
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        centerMap()
        registerListeners()
        loadInPoints()
        
    }
    
    func centerMap(){
        
        
        map.delegate=self
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let latitude: CLLocationDegrees = 51.4
        let longitude: CLLocationDegrees = -0.1
        
        let latDelta: CLLocationDegrees = 0.27
        let lonDelta: CLLocationDegrees = 0.27
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        
        let location: CLLocationCoordinate2D=CLLocationCoordinate2DMake(latitude, longitude)
        
        let region:MKCoordinateRegion =  MKCoordinateRegionMake(location, span)
        
        map.setRegion(region, animated: true)
        
        
        
        
        
    }
    func loadInPoints(){
        
        
        let allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        
        let query = PFQuery(className: "Letters")
        
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                print("Successfully retrieved \(objects?.count)")
                
                for object in objects!{
                    
                    
                    self.addAnnotation(object)
                }
                
                
            } else {
                print("Error")
            }
        }
        
        
    }
    func registerListeners(){
        let uiplgr = UILongPressGestureRecognizer(target: self, action: Selector("action:"))
        //
        uiplgr.minimumPressDuration = 0
        //
        map.addGestureRecognizer(uiplgr)
        
    }
    
    
    
    func addAnnotation(dic: PFObject){
        var letter="a"
        let letterset = NSCharacterSet.controlCharacterSet()
        let objectId: String=dic.objectId! as String
        for tempChar in objectId.characters {
            
            let tempStr=String(tempChar)
            if let number = Int(tempStr)
            {
                
            }
            else
            {
                letter=tempStr
                break
            }
            
            
        }
        addAnnotation(dic["latitude"] as! Double, longitude: dic["longitude"] as! Double, letter: letter, objectId: objectId)
    }
    
    
    func addAnnotation(latitude: Double, longitude: Double, letter: String, objectId: String){
        let latitude: CLLocationDegrees = latitude
        let longitude: CLLocationDegrees = longitude
        
        let location: CLLocationCoordinate2D=CLLocationCoordinate2DMake(latitude, longitude)
        let annotation = CustomPointAnnotation()
        annotation.letter=letter
        annotation.objectId=objectId
        
        annotation.coordinate = location
        
        self.map.addAnnotation(annotation)
    }
    
    
    
    
    
    func action(gestureRecognizer: UIGestureRecognizer) -> Bool{
        //        print(self.map.annotations)
        //
        
        
        let touchPoint = gestureRecognizer.locationInView(self.map)
        
        let newCoord: CLLocationCoordinate2D = map.convertPoint(touchPoint,toCoordinateFromView: self.map)
        let newLocation: CLLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
        
        
        
        
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
            if closestDist < 1300 && closest != nil {
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
                print(oid)
                let query = PFQuery(className: "Letters")
                query.getObjectInBackgroundWithId(oid){
                    (prefObj: PFObject?, error: NSError?) -> Void in
                    if error != nil {
                        print ("dsdsdsds")
                        print(error)
                    } else if let prefObj = prefObj{
                        if self.draggingPoint != nil{
                            prefObj["latitude"] = self.draggingPoint!.coordinate.latitude
                            prefObj["longitude"] = self.draggingPoint!.coordinate.longitude
                            prefObj.saveInBackgroundWithBlock(nil)
                            self.draggingPoint = nil
                        }

                    }
                }
                
                
                
            }
            else{
                draggingMapPoint = nil
            }
        }
        
        return true
    }
    
    
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //        let latDelta: CLLocationDegrees = 0.01
        //        let lonDelta: CLLocationDegrees = 0.01
        //
        //        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        //        let region:MKCoordinateRegion =  MKCoordinateRegionMake(locations[0].coordinate, span)
        //
        //        self.map.setRegion(region, animated: true)
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
        let image=UIImage(named:"\(cpa.letter).png")
        if image != nil{
            anView!.image = resizeImage(image!,newWidth: 50)
            
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
}


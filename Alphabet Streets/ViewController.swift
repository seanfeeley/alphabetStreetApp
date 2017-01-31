//
//  ViewController.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 17/07/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import UIKit

import MapKit
import Foundation





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



class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate,UIGestureRecognizerDelegate {
    
    @IBOutlet weak var map: MKMapView!

    var currentUserLocation:CLLocation? = nil
    var centerPointAtLastPointLoad: CLLocation? = nil
    var meterBetweenRefreshesAtLastLoad: CLLocationDegrees? = nil
    
    var locationManager = CLLocationManager()
    var selectedObjectId: String? = nil
    var oldMapRegion: MKCoordinateRegion? = nil
    
    var letterLoader: LetterLoader!
    
//    var draggingPoint: CustomPointAnnotation? = nil
//    var hoverPoint: CustomPointAnnotation? = nil
//    var draggingMapPoint: CLLocation? = nil
//    var already_existing_ids:[String] = []
//    var points_to_remove: NSMutableArray = []
//    var points_to_move: NSMutableArray = []
//    var points_to_add: NSMutableArray = []
//
//    var touchPoint:CGPoint? = nil
//    
//    
//    var drapPanTimer:Timer? = nil
//    var dragPanLat=0.0
//    var dragPanLon=0.0
//    
//    var subscription: Subscription<PFObject>?
//    
//    var loadingPointsIn:Bool = false
//    var uploadingPoints:Bool = false
//    var newPointsLoadedIn:Bool = false
//    
//    
//    var reachabilityNotice:Bool = false

    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initaliseMap()
        
    }
    
    func initaliseMap(){
        
        self.letterLoader = LetterLoader(map: self.map)
        map.delegate=self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        registerListeners()
        

    }
    
    func registerListeners(){

        let uizgr = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.pinchRecognizer(_:)))
        uizgr.delegate=self
        map.addGestureRecognizer(uizgr)
        
        let uizpr = UIPanGestureRecognizer(target: self, action: #selector(ViewController.panRecognizer(_:)))
        uizpr.delegate=self
        map.addGestureRecognizer(uizpr)
        
        let uitr = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapRecognizer(_:)))
        uitr.delegate=self
        map.addGestureRecognizer(uitr)
        
        
        
        
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool{
        return true
    }
    func pinchRecognizer(_ gestureRecognizer: UIPinchGestureRecognizer) -> Bool{

  
        self.refreshAnnotationResolutions()
//        self.stopHovering()
        if self.map.annotations.count==0{
            self.placeLetterAnnotations()
        }
        return true
    }
    
    
    func panRecognizer(_ gestureRecognizer: UIPinchGestureRecognizer) -> Bool{
        self.locationHasChanged()
        return true
    }
    
    func tapRecognizer(_ sender:UITapGestureRecognizer){
        if sender.state == .ended {
            
            let touchLocation: CGPoint = sender.location(in: sender.view)
            let touchCoord = self.map.convert(touchLocation, toCoordinateFrom: self.map.inputView)
            if self.selectedObjectId == nil {
                self.setSelectedLetter(coord: touchCoord)
            }
            else if self.letterLoader.areLettersStillVisible() {
                self.moveHoverPoint(coord: touchCoord)
                self.dropSelectedLetter(coord: touchCoord)
                
            }
            
        }
        
    }
    
    func dropHoverPoint(letter: LetterAnnotation){
        let hoverPoint = HoverAnnotation(letter: letter)
        self.map.addAnnotation(hoverPoint)
    }
    
    func moveHoverPoint(coord: CLLocationCoordinate2D){
        let hoverPoint = self.getHoverPoint()
        UIView.animate(withDuration: 0.2, delay:0, options: [.curveEaseOut], animations: {
           hoverPoint?.coordinate = coord
            
        }, completion: nil)
        
    }
    
    
    
    
   
    
    func dropSelectedLetter(coord: CLLocationCoordinate2D){
        
        let selectedLetter = self.getSelectedLetter()
        
        if selectedLetter != nil{
            selectedLetter!.getView(mapView: self.map).layer.removeAllAnimations()
            UIView.animate(withDuration: 0.2,  delay: 0, options: [.curveEaseOut],animations: {
                
                selectedLetter!.coordinate=coord
                
            }, completion: { (completed) in
                
                selectedLetter!.isHovering = false
                self.letterLoader.saveLetter(letter: selectedLetter!)
                self.selectedObjectId = nil
                self.removeAllHoverShadows()
                
                
            })

        }
        
    }
    
    
    func setSelectedLetter(coord: CLLocationCoordinate2D){
        let tapLocation: CLLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        for annotation in self.map.annotations{
        
                
            
            let location: CLLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let distance = location.distance(from: tapLocation)
            if distance < getTapingDistance(){
                let selectedLetter = annotation as! LetterAnnotation
                self.selectedObjectId = selectedLetter.objectId
                self.dropHoverPoint(letter: selectedLetter)
                self.startHoveringSelectedLetter()
                return
                }
        }
    }
    
    func getSelectedLetter() -> LetterAnnotation?{
        if self.selectedObjectId != nil{
            for annotation in self.map.annotations{
                if annotation is HoverAnnotation == false{
                    let letter = annotation as! LetterAnnotation
                    if letter.objectId == self.selectedObjectId{
                        return letter
                    }
                }
                
            }
            let offscreenLetter = LetterAnnotation(objectId: self.selectedObjectId!)
            self.map.addAnnotation(offscreenLetter)
            return offscreenLetter
        }
        
        return nil
    }
    func getHoverPoint() -> HoverAnnotation?{
       
        for annotation in self.map.annotations{
            if annotation is HoverAnnotation{
                return annotation as? HoverAnnotation
            }
            
        }
        return nil
    }
    
    func removeAllHoverShadows(){
        for annotation in self.map.annotations{
            if annotation is HoverAnnotation{
                self.map.removeAnnotation(annotation)
            }
            
        }

    }
    
    func startHoveringSelectedLetter(){
        var selectedLetter = self.getSelectedLetter()
        selectedLetter?.isHovering=true
        self.refreshAnnotationResolutions()
        selectedLetter = self.getSelectedLetter()
        selectedLetter?.isHovering=true
        UIView.animate(withDuration: 0.2,  delay: 0, options: [.curveEaseOut],animations: {
            

            let selectedLetterXY = self.map.convert((selectedLetter!.coordinate), toPointTo: self.map.inputView)
            let newSelectedLeterXY = CGPoint(x: selectedLetterXY.x, y: selectedLetterXY.y - getHoverHeight(mapView: self.map))
            selectedLetter!.coordinate=self.map.convert(newSelectedLeterXY, toCoordinateFrom: self.map.inputView)
            
        }, completion: { (completed) in
            
// This is my hover animation which i really like but found had to work in conjunction with map zooming
            
//            if(self.selectedLetter != nil){
//                
//                UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse], animations: {
//
//                    
//                    
//
//                    let selectedLetterXY = self.map.convert((self.selectedLetter?.coordinate)!, toPointTo: self.map.inputView)
//                    let newSelectedLeterXY = CGPoint(x: selectedLetterXY.x, y: selectedLetterXY.y + getHoverHeight(mapView: self.map)/2)
//                    self.selectedLetter?.coordinate=self.map.convert(newSelectedLeterXY, toCoordinateFrom: self.map.inputView)
//                    
//                    
//                }, completion: nil)
//                
//                
//            }
            
            
        })

           
        
        
        

        
        
        
    }
    
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
        self.locationHasChanged()
        self.regionHasChanged()
        
    }
    
    
    func locationHasChanged(){
        let locationNow=CLLocation(latitude:  self.map.region.center.latitude,longitude:  self.map.region.center.longitude)
        let meters_between_loads:CLLocationDegrees = getMetersBetweenLetterRefreshes(mapView: self.map)
        
        if self.centerPointAtLastPointLoad != nil{
            let difference:CLLocationDegrees = meters_between_loads - self.meterBetweenRefreshesAtLastLoad!
            if difference > self.meterBetweenRefreshesAtLastLoad! || locationNow.distance(from: self.centerPointAtLastPointLoad!) > meters_between_loads{

                self.placeLetterAnnotations( )
            }
        
        }
        else if self.centerPointAtLastPointLoad == nil{
            self.centerPointAtLastPointLoad = locationNow
            self.meterBetweenRefreshesAtLastLoad = meters_between_loads
        }

        
    }
    
    func regionHasChanged(){
        if self.oldMapRegion == nil
        {
            self.oldMapRegion = self.map.region
        }
        else if self.oldMapRegion?.span.latitudeDelta != self.map.region.span.latitudeDelta
        {
            self.refreshAnnotationResolutions()
            self.oldMapRegion = self.map.region

        }
    
    
    }
    func refreshAnnotationResolutions(){
        if (self.letterLoader.areLettersStillVisible()){
            
            self.refreshVisibleAnnotationResolutions()
        }
        else{
            self.fadeOutAllAnnotations()
        }
    }
    
    func fadeOutAllAnnotations(){
        
        for annotation in self.map.annotations{
            let letter: LetterAnnotation = annotation as! LetterAnnotation
            
            UIView.animate(withDuration: 0.5, animations: {
            let view = self.map.view(for: letter)
            
            view?.alpha=0
            }, completion: { (completed) in
                //self.map.removeAnnotation(letter)
            })
        }
        
    }
    
   
    func refreshVisibleAnnotationResolutions(){
        
        let all_annotaions = self.map.annotations
        var visible_rect = self.map.visibleMapRect
        visible_rect.origin.x = visible_rect.origin.x - visible_rect.size.width/2
        visible_rect.origin.y = visible_rect.origin.y - visible_rect.size.height/2
        visible_rect.size.height=visible_rect.size.height*2
        visible_rect.size.width=visible_rect.size.width*2
        var annotations_to_refresh: [LetterAnnotation] = []
        var all_hover_annotations: [LetterAnnotation] = []
        var all_selected_annotations: [LetterAnnotation] = []
        
        for annotation in all_annotaions{
            if MKMapRectContainsPoint(visible_rect, MKMapPointForCoordinate(annotation.coordinate)){
                if annotation is HoverAnnotation{
                    all_hover_annotations.append(HoverAnnotation(letter: annotation as! HoverAnnotation))
                }
                else if annotation is LetterAnnotation{
                    let letter = LetterAnnotation(other: annotation as! LetterAnnotation)
                    if letter.objectId == self.selectedObjectId{
                        letter.isHovering=true
                        all_selected_annotations.append(letter)
                        
                    }
                    else{
                        annotations_to_refresh.append(letter)
                    }
                    
                }
            }
        }
        print(annotations_to_refresh.count,all_hover_annotations.count,all_selected_annotations.count)
        self.map.addAnnotations(annotations_to_refresh)
        self.map.addAnnotations(all_hover_annotations)
        self.map.addAnnotations(all_selected_annotations)
        self.map.removeAnnotations(all_annotaions)
        

        
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
                
        if self.currentUserLocation == nil {
            self.currentUserLocation = locations[locations.count-1]
            centerMapToUserLocation()
        }
        
    }
    
    
    @IBAction func homeButton(_ sender: AnyObject) {

        centerMapToUserLocation()

        
    }

    
    func centerMapToUserLocation(){
        
        
        let latDelta: CLLocationDegrees = ZOOM_DISTANCE
        let lonDelta: CLLocationDegrees = ZOOM_DISTANCE
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        
        var l = self.currentUserLocation
        
        if l == nil {
            let latitude: CLLocationDegrees = 0
            let longitude: CLLocationDegrees = 0
            
            l = CLLocation(latitude: latitude, longitude: longitude)
        }
        
        let region:MKCoordinateRegion =  MKCoordinateRegionMake(l!.coordinate, span)
        
        map.setRegion(region, animated: false)
        
        
        self.placeLetterAnnotations()
    }
    
    
   
        
  
    
    
    func placeLetterAnnotations(){
        if (self.letterLoader.areLettersStillVisible()){
        self.centerPointAtLastPointLoad = CLLocation(latitude:  self.map.region.center.latitude,longitude:  self.map.region.center.longitude)
        self.meterBetweenRefreshesAtLastLoad = getMetersBetweenLetterRefreshes(mapView: self.map)
            
            
        

        self.letterLoader.placeLetters(selectedObjectId: self.selectedObjectId)
        
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let letterAnnotation: LetterAnnotation = annotation as! LetterAnnotation
        return letterAnnotation.getView(mapView: mapView)

    }
    
    
//    func getAnViewForAnnotation(_ mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView {
//        
//        
//    }

    
    
    
    
    
    
}

//    func downloadLetterAnnotaions(){

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

            //self.subscription = query.subscribe().handle(Event.Updated) { _, object in
            //
            //    self.points_to_move.addObject(object)
            //
            //
            //}

            //       uploadPoints()
//            self.loadingPointsIn=false
//            self.centerPointAtLastPointLoad=CLLocation(latitude:  self.map.region.center.latitude,longitude:  self.map.region.center.longitude)
//        }
    
        
//    }

    
//    
//    func moveAnnotations(){
//        
//        
//            for object in self.points_to_move{
//                self.moveAnnotation(object as! PFObject)
//                self.points_to_move.remove(object)
//                
//            }
//        
//        
//    }
    
//    func moveAnnotation(_ dic: PFObject){
//        
//        let objectId: String=dic.objectId! as String
//        
//        for a in self.map.annotations{
//            let ca = a as! CustomPointAnnotation
//            //            print("  ",ca.objectId)
//            
//            if ca.objectId == objectId{
//                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
//                    ca.coordinate.longitude=dic["longitude"] as! CLLocationDegrees
//                    ca.coordinate.latitude=dic["latitude"] as! CLLocationDegrees
//                }, completion: { (finished: Bool) -> Void in
//                })
//            }
//        }
//        
//    }
    
//    func loadAnnotations(){
//        
//        
//            if newPointsLoadedIn && self.points_to_add.count != 0{
//                //            print("    placing:",self.points_to_add.count,"removing:",self.points_to_remove.count)
//                
//                
//                
//                self.map.addAnnotations(self.points_to_add as! [MKAnnotation])
//                self.points_to_add=[]
//                self.map.removeAnnotations(self.points_to_remove as! [MKAnnotation])
//                self.points_to_remove=[]
//                self.newPointsLoadedIn=false
//            }
//        
//        
//    }
    
    
    
//    func loadNewPoints(){
//        print("LOAD IN NEWBIES")
//        for a in (0...100){
//            let lat=arc4random_uniform(8000000)
//            let lon=arc4random_uniform(12000000)
//            let latitude = 50+Float(lat)/1000000.0
//            let longitude = 2-Float(lon)/1000000.0
//            createPoint(latitude,longitude: longitude)
//
//        }
//    }
    
    
    
//    func uploadPoints(){
//        
//        for a in self.map.annotations{
//            
//            let ca = a as! CustomPointAnnotation
//            
//            if ca.toUpdate == true
//            {
//                
//            }
//            
//        }
//        
//        
//        
//    }
    
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
    
    
    
//    func createPoint(_ latitude: Float, longitude: Float){
//        let o = PFObject(className: "ActiveLetters")
//        
//        print(o)
//        o["latitude"] = latitude
//        o["longitude"] = longitude
//        
//        o.saveInBackground()
//    }
    
       

    
//    func addAnnotation(_ dic: PFObject) -> MKAnnotation?{
//        var letter="a"
//        let letterset = CharacterSet.controlCharacters
//        let objectId: String=dic.objectId! as String
//        
//        
//        
//        
//        if self.already_existing_ids.contains(objectId){
//            
//            
//            
//            for a in self.map.annotations{
//                let ca = a as! CustomPointAnnotation
//                if ca.objectId == objectId{
//                    
//                    if ca.toUpdate != true{
//                        ca.coordinate.longitude=dic["longitude"] as! CLLocationDegrees
//                        ca.coordinate.latitude=dic["latitude"] as! CLLocationDegrees
//                        
//                    }
//                    
//                    
//                    return ca
//                }
//                
//                
//            }
//            
//        }
//        else{
//            
//            var bytes = ""
//            for char in objectId.utf8{
//                bytes = bytes + String(char)
//            }
//            
//            
//            
//            
//            
//            letter="letter_16_00"
//            
//            return addAnnotation(dic["latitude"] as! CLLocationDegrees, longitude: dic["longitude"] as! CLLocationDegrees, letter: letter, objectId: objectId)
//        }
//        return nil
//    }
    
    
//    func addAnnotation(_ latitude: CLLocationDegrees, longitude: CLLocationDegrees, letter: String, objectId: String) -> MKAnnotation?{
//        let latitude: CLLocationDegrees = latitude
//        let longitude: CLLocationDegrees = longitude
//        
//        let location: CLLocationCoordinate2D=CLLocationCoordinate2DMake(latitude, longitude)
//        let annotation = CustomPointAnnotation()
//        annotation.letter=letter
//        annotation.objectId=objectId
//        annotation.coordinate = location
//        
//        
//        var contains:Bool=false
//        for a in self.points_to_add{
//            if (a as AnyObject).objectId == annotation.objectId{
//                contains=true
//            }
//        }
//        if contains == false{
//            self.points_to_add.add(annotation)
//        }
//        else{
//            //            self.points_to_add.addObject(annotation)
//            
//        }
//        //                    self.map.addAnnotation(annotation)
//        
//        
//        return annotation
//    }
    
    
    
    
    
//    func action(_ gestureRecognizer: UIGestureRecognizer) -> Bool{
//        //        print(self.map.annotations)
//        //
//        
//        
//        
//        self.touchPoint = gestureRecognizer.location(in: self.map)
//        
//        let newCoord: CLLocationCoordinate2D = map.convert(self.touchPoint!,toCoordinateFrom: self.map)
//        let newLocation: CLLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
//        
//        //        createPoint(newCoord.latitude as Double,longitude: newCoord.longitude as Double)
//        //        return true
//        
//        
//        if gestureRecognizer.state == UIGestureRecognizerState.began {
//            self.drapPanTimer?.invalidate()
//            var closest:MKAnnotation? = nil
//            var closestDist:CLLocationDistance? = nil
//            
//            for annotation in self.map.annotations{
//                let otherLocation: CLLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
//                let meters = newLocation.distance(from: otherLocation)
//                if closestDist==nil || meters < closestDist{
//                    closest=annotation
//                    closestDist=meters
//                }
//                
//                
//                
//            }
//            
//            var detectable:CLLocationDistance = 1000
//            
//            if UIDevice.current.model=="iPhone"{
//                detectable=1000
//            }
//            else if UIDevice.current.model=="iPad"{
//                detectable=500
//            }
//            else{
//                detectable=1000
//                
//            }
//            
//            
//            if closestDist < detectable && closest != nil {
//                draggingPoint = closest as! CustomPointAnnotation
//                UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
//                    self.draggingPoint!.coordinate.latitude = newCoord.latitude+0.01
//                    self.draggingPoint!.coordinate.longitude = newCoord.longitude
//                    }, completion: { (finished: Bool) -> Void in
//                })
//                
//                
//                self.hoverPoint = CustomPointAnnotation()
//                self.hoverPoint?.coordinate = newCoord
//                self.hoverPoint?.letter="hover"
//                self.map.addAnnotation(self.hoverPoint!)
//            }
//            else{
//                draggingMapPoint=newLocation
//                
//            }
//            
//            
//        }
//        else if gestureRecognizer.state == UIGestureRecognizerState.changed {
//            
//            if draggingPoint != nil{
//                
//                UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
//                    self.draggingPoint!.coordinate.latitude = newCoord.latitude+0.01
//                    self.draggingPoint!.coordinate.longitude = newCoord.longitude
//                    }, completion: { (finished: Bool) -> Void in
//                })
//                
//                self.hoverPoint?.coordinate=newCoord
//                
//                
//                
//                    var toPan = false
//                    let right = UIScreen.main.bounds.width - self.touchPoint!.x
//                    let moveRight = 0.002 - right/100000
//                    if moveRight > 0{
//                        self.dragPanLon = Double(moveRight)
//                        toPan = true
//                    }
//                    let left = self.touchPoint!.x
//                    let moveLeft = 0.002 - left/100000
//                    if moveLeft > 0{
//                        self.dragPanLon = Double(-moveLeft)
//                        toPan = true
//                    }
//                
//                let top = self.touchPoint!.y
//                
//                let moveTop = 0.002 - top/100000
//                if moveTop > 0{
//                    self.dragPanLat = Double(moveTop)
//                    toPan = true
//                }
//                let bottom = UIScreen.main.bounds.height - self.touchPoint!.y
//               
//                let moveBottom = 0.002 - bottom/100000
//                if moveBottom > 0{
//                    self.dragPanLat = Double(-moveBottom)
//                    toPan = true
//                }
//                
//                
//                if toPan{
//                    if self.drapPanTimer == nil || self.drapPanTimer?.isValid == false{
//                        self.drapPanTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.dragPan), userInfo: nil, repeats: true)
//                        
//                    }
//                }
//                else{
//                    self.drapPanTimer?.invalidate()
//
//                }
//
//                
//                
//
//                
//                
//                
//                
//            }
//            else if draggingMapPoint != nil{
//                self.drapPanTimer?.invalidate()
//                let center = map.centerCoordinate
//                let newCenter = CLLocation(latitude: center.latitude-(newLocation.coordinate.latitude-draggingMapPoint!.coordinate.latitude), longitude: center.longitude-(newLocation.coordinate.longitude-draggingMapPoint!.coordinate.longitude))
//                map.setCenter(newCenter.coordinate, animated: false)
//                
//                
//                
//            }
//            
//        }else if gestureRecognizer.state == UIGestureRecognizerState.ended {
//            self.drapPanTimer?.invalidate()
//            
//            if draggingPoint != nil{
//                
//         
//                
//                
//                UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
//                    self.draggingPoint!.coordinate = newCoord
//                    }, completion: { (finished: Bool) -> Void in
//                })
//                draggingPoint!.coordinate = newCoord
//                let uploadList = [draggingPoint!.objectId,draggingPoint!.coordinate.latitude,draggingPoint!.coordinate.longitude] as [Any]
//                self.map.removeAnnotation(self.hoverPoint!)
//                self.hoverPoint=nil
//                self.draggingPoint = nil
//                
//                
//                self.points_to_upload.add(uploadList)
//                
//                
//                
//                
//                
//                
//            }
//            else{
//                self.drapPanTimer?.invalidate()
//                //                loadInPoints()
//                draggingMapPoint = nil
//            }
//        }
//        
//        return true
//    }
//    
    
    
//    func dragPan(){
//        
//        
//        self.map.region.center.latitude=self.map.region.center.latitude+self.dragPanLat
//        self.map.region.center.longitude=self.map.region.center.longitude+self.dragPanLon
//        
//    }



class localPincher: UIGestureRecognizer {
    
}
    
    
    

    
    

    
    

    




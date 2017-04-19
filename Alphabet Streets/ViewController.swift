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

extension UserDefaults {
    // check for is first launch - only true on first invocation after app install, false on all further invocations
    // Note: Store this value in AppDelegate if you have multiple places where you are checking for this flag
    static func isFirstLaunch() -> Bool {
        let hasBeenLaunchedBeforeFlag = "hasBeenLaunchedBeforeFlag"
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: hasBeenLaunchedBeforeFlag)
        if (isFirstLaunch) {
            UserDefaults.standard.set(true, forKey: hasBeenLaunchedBeforeFlag)
            UserDefaults.standard.synchronize()
        }
        return isFirstLaunch
    }
}


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate,UIGestureRecognizerDelegate {
    

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var zoom_in_label: UITextField!
    @IBOutlet weak var letter_inside_focus: UIImageView!
    @IBOutlet weak var focus_ring: UIImageView!

    var currentUserLocation:CLLocation? = nil
    var centerPointAtLastPointLoad: CLLocation? = nil
    var meterBetweenRefreshesAtLastLoad: CLLocationDegrees? = nil
    
    var locationManager = CLLocationManager()
    var selectedObjectId: String? = nil
    var oldMapRegion: MKCoordinateRegion? = nil
    var letterLoader: LetterLoader!

    
    

    
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
        deregister_double_tap_zoom_listeners()
        registerListeners()
        

    }
    
    func deregister_double_tap_zoom_listeners(){
        
        if (map.subviews[0].gestureRecognizers != nil){
            for gesture in map.subviews[0].gestureRecognizers!{
                if gesture is UITapGestureRecognizer{
                    let tap = gesture as! UITapGestureRecognizer
                    if tap.numberOfTapsRequired == 2{
                        map.subviews[0].removeGestureRecognizer(gesture)
                    }
                }
            }
        }
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
//        print(gestureRecognizer.description)
        return true
    }
    func pinchRecognizer(_ gestureRecognizer: UIPinchGestureRecognizer) -> Bool{

  
        self.refreshAnnotationResolutions()

        if self.map.annotations.count==0 && self.letterLoader.is_loading == false{
            
            self.placeLetterAnnotations()
            
        }
        return true
    }
    
    
    func panRecognizer(_ gestureRecognizer: UIPinchGestureRecognizer) -> Bool{
//        self.locationHasChanged()
//        print("\(self.map.annotations.count)")

        return true
    }
    
    func tapRecognizer(_ sender:UITapGestureRecognizer){
        if sender.state == .ended {
            
            let touchLocation: CGPoint = sender.location(in: sender.view)
            let touchCoord = self.map.convert(touchLocation, toCoordinateFrom: self.map.inputView)
            if self.selectedObjectId == nil {
                self.setSelectedLetter(touchCoord)
            }
            else if self.letterLoader.areLettersStillVisible() {
                self.moveHoverPoint(touchCoord)
                self.dropSelectedLetter(touchCoord)
                
            }
            
        }
        
    }

    
    func dropHoverPoint(_ letter: LetterAnnotation){
        let hoverPoint = HoverAnnotation(letter: letter)
        self.map.addAnnotation(hoverPoint)
    }
    
    func moveHoverPoint(_ coord: CLLocationCoordinate2D){
        let hoverPoint = self.getHoverPoint()
        UIView.animate(withDuration: 0.2, delay:0, options: [.curveEaseOut], animations: {
           hoverPoint?.coordinate = coord
            
        }, completion: nil)
        
    }
    
    
    
    
   
    
    func dropSelectedLetter(_ coord: CLLocationCoordinate2D){
        self.stop_spinning_focus()
        let selectedLetter = self.getSelectedLetter()
        
        if selectedLetter != nil{
            selectedLetter!.getView(self.map).layer.removeAllAnimations()
            UIView.animate(withDuration: 0.2,  delay: 0, options: [.curveEaseOut],animations: {
                
                selectedLetter!.coordinate=coord
                
            }, completion: { (completed) in
                
                selectedLetter!.isHovering = false
                self.letterLoader.saveLetter(selectedLetter!)
                self.selectedObjectId = nil
                self.removeAllHoverShadows()
                
                
            })

        }
        
    }
    
    
    func setSelectedLetter(_ coord: CLLocationCoordinate2D){
        let tapLocation: CLLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        for annotation in self.map.annotations{
        
                
            
            let location: CLLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let distance = location.distance(from: tapLocation)
            if distance < getTapingDistance(){
                let selectedLetter = annotation as! LetterAnnotation
                self.selectedObjectId = selectedLetter.objectId
                self.dropHoverPoint(selectedLetter)
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
    
    func start_spinning_focus(){
        let selectedLetter = self.getSelectedLetter()
        self.letter_inside_focus.image = UIImage(named:"letter_32_\(String(format: "%02d", (selectedLetter?.letterId)!)).png")!
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
            
            self.focus_ring.alpha = 0.6
            self.letter_inside_focus.alpha = 0.6
            
        }, completion: nil)
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.repeat,.curveLinear], animations: {
            
            self.focus_ring.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_4))
            
        }, completion: nil)
    }
    func stop_spinning_focus(){
        self.focus_ring.layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
            self.focus_ring.alpha = 0.1
            self.letter_inside_focus.alpha = 0
            self.focus_ring.transform = CGAffineTransform(rotationAngle: CGFloat(0))
        }, completion: nil)
        
    }
    
    
    func startHoveringSelectedLetter(){
        self.start_spinning_focus()
        var selectedLetter = self.getSelectedLetter()
        selectedLetter?.isHovering=true
        self.refreshAnnotationResolutions()
        selectedLetter = self.getSelectedLetter()
        selectedLetter?.isHovering=true
        UIView.animate(withDuration: 0.2,  delay: 0, options: [.curveEaseOut],animations: {
            selectedLetter!.start_hovering_on_map(map:self.map)
            
        }, completion: { (completed) in
        })
        
        
    }
    
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
//        print("start region did change")
        self.locationHasChanged()
        self.regionHasChanged()
//        print("finish region did change")
        
        
    }
    
    
    func locationHasChanged(){
        let locationNow=CLLocation(latitude:  self.map.region.center.latitude,longitude:  self.map.region.center.longitude)
        let meters_between_loads:CLLocationDegrees = getMetersBetweenLetterRefreshes(self.map)
        
        if self.centerPointAtLastPointLoad != nil{
            let difference:CLLocationDegrees = meters_between_loads - self.meterBetweenRefreshesAtLastLoad!
            if difference > self.meterBetweenRefreshesAtLastLoad! || locationNow.distance(from: self.centerPointAtLastPointLoad!) > meters_between_loads{
                
                
                
                self.placeLetterAnnotations( )
//                self.delete_annotation_outside_region()

            }
        
        }
        else if self.centerPointAtLastPointLoad == nil{
            self.centerPointAtLastPointLoad = locationNow
            self.meterBetweenRefreshesAtLastLoad = meters_between_loads
        }

        
    }
    
//    func delete_annotation_outside_region(){
//        let top_left = letterLoader.randomLetterLoader.getMapTopLeftCoordinate()
//        let bottom_right = letterLoader.randomLetterLoader.getMapBottomRightCoordinate()
//        for annotation in self.map.annotations{
//            if (annotation.coordinate.latitude < top_left.latitude)
//                && (annotation.coordinate.latitude > bottom_right.latitude)
//                && (annotation.coordinate.longitude > bottom_right.longitude)
//                && (annotation.coordinate.longitude > bottom_right.longitude){
//                    self.map.removeAnnotation(annotation)
//                    let l = annotation as! LetterAnnotation
//                    self.letterLoader.current_letters_on_screen.removeValue(forKey: l.objectId)
//                
//            }
//        }
    
//    }
    
    
    
    func regionHasChanged(){
        if self.oldMapRegion == nil
        {
            self.oldMapRegion = self.map.region
        }
        else if self.oldMapRegion?.span.latitudeDelta != self.map.region.span.latitudeDelta
        {
//            self.refreshAnnotationResolutions()
            self.oldMapRegion = self.map.region

        }
    
    
    }
    func refreshAnnotationResolutions(){
        if (self.letterLoader.areLettersStillVisible()){
            
            self.zoom_in_label.isHidden = true
            self.refreshVisibleAnnotationResolutions()
        }
        else{
            self.zoom_in_label.isHidden = false
            self.fadeOutAllAnnotations()
            self.letterLoader.current_letters_on_screen = [:]
        }
    }
    
    func fadeOutAllAnnotations(){
        
        for annotation in self.map.annotations{
            let letter: LetterAnnotation = annotation as! LetterAnnotation
            
            UIView.animate(withDuration: 0.5, animations: {
            let view = self.map.view(for: letter)
            
            view?.alpha=0
            }, completion: { (completed) in
                self.map.removeAnnotation(letter)
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
        self.letterLoader.current_letters_on_screen = [:]
        for annotation in all_annotaions{
            if MKMapRectContainsPoint(visible_rect, MKMapPointForCoordinate(annotation.coordinate)){
                if annotation is HoverAnnotation{
                    all_hover_annotations.append(HoverAnnotation(letter: annotation as! HoverAnnotation))
                }
                else if annotation is LetterAnnotation{
                    let letter = LetterAnnotation(other: annotation as! LetterAnnotation)
                    self.letterLoader.current_letters_on_screen[letter.objectId] = letter
                    if letter.objectId == self.selectedObjectId{
                        letter.isHovering=true
                        all_selected_annotations.append(letter)
                        
                    }
                    else{
                        
                        annotations_to_refresh.append(letter)
                    }
                    self.letterLoader.current_letters_on_screen[letter.objectId] = letter
                    
                }
            }
        }

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
        else{
            self.currentUserLocation = locations[locations.count-1]
        }
        
    }
    
    
    @IBAction func homeButton(_ sender: AnyObject) {

        centerMapToUserLocation()
        refreshVisibleAnnotationResolutions()
        self.zoom_in_label.isHidden = true
        
        
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

        let isFirstLaunch = UserDefaults.isFirstLaunch()
        if isFirstLaunch{
            performSegue(withIdentifier: "show_help", sender: nil)
        }
    }
    
    
   
        
  
    
    
    func placeLetterAnnotations(){
        if (self.letterLoader.areLettersStillVisible()){
        self.centerPointAtLastPointLoad = CLLocation(latitude:  self.map.region.center.latitude,longitude:  self.map.region.center.longitude)
        self.meterBetweenRefreshesAtLastLoad = getMetersBetweenLetterRefreshes(self.map)
            
            
        
        self.letterLoader.selectedObjectId = self.selectedObjectId
        
        
        self.letterLoader.load_letters_via_firebase()
        
        
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let letterAnnotation: LetterAnnotation = annotation as! LetterAnnotation
        return letterAnnotation.getView(mapView)

    }
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        
        
        var i = -1;
        for view in views {
            let letter:LetterAnnotation = view.annotation as! LetterAnnotation
            if letter.animate_in == true{
                i += 1;
                if view.annotation is MKUserLocation {
                    continue;
                }
                
                // Check if current annotation is inside visible map rect, else go to next one
                let point:MKMapPoint  =  MKMapPointForCoordinate(view.annotation!.coordinate);
                if (!MKMapRectContainsPoint(self.map.visibleMapRect, point)) {
                    continue;
                }
                
                let endFrame:CGRect = view.frame;
                
                // Move annotation out of view
                view.alpha = 0
                
                // Animate drop
                let delay = 0.01 * Double(i)
                UIView.animate(withDuration: 1, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations:{() in
                    view.alpha = 1
                }, completion:{(Bool) in
                })
            }

        }
    }
    
}




    
    

    
    

    




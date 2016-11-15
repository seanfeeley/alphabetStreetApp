//
//  LetterAnnotation.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 03/11/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import Foundation

import MapKit


class LetterAnnotation: MKPointAnnotation {
    var letterId: UInt32!
    var letterFile: Int!
    var objectId: String = "xxxxxx"
    var image: UIImage = UIImage()
    let zoomFactor: CGFloat = LETTER_WIDTH
    
    
    var toUpdate: Bool = false
    
    init(coord: CLLocationCoordinate2D) {
        super.init()
        self.coordinate=coord
        self.generateObjectId()
        self.generateRandomLetter()
        self.generateRandomCoordShift()
        self.letterFile = 16
        
    }
    func generateObjectId(){
        self.objectId="\(self.coordinate.latitude)/\(self.coordinate.longitude)"
        
        
    }
    
    func generateRandomLetter(){
        
        srand48(self.getRandomSeed())
        self.letterId = UInt32( drand48() * 26 )
    }
    
    func generateRandomCoordShift(){
        
        srand48(self.getRandomSeed())
        let latShift: CLLocationDegrees = CLLocationDegrees ( drand48() * Double(LETTER_DENSITY)/2)
        let lonShift: CLLocationDegrees = CLLocationDegrees ( drand48() * Double(LETTER_DENSITY)/2)
        self.coordinate.latitude = self.coordinate.latitude - CLLocationDegrees(LETTER_DENSITY)/4 + latShift
        self.coordinate.longitude = self.coordinate.longitude - CLLocationDegrees(LETTER_DENSITY)/4 + lonShift
        
        
    }

    
    func getRandomSeed() -> Int {
        let i: Int = reverseNumber(number:self.objectId.hashValue)
        return i
    }
    
    func reverseNumber(number:Int) -> Int{
        let absNumber:Int = abs(number)
        var absNumberStr:String = String(absNumber)
        let absNumberStrReverse:String = String(absNumberStr.characters.reversed().dropLast(4))
       
        let absNumberReverse:Int = Int(absNumberStrReverse)!
        return absNumberReverse
    }

    
    init(other:LetterAnnotation){
        super.init()
        self.coordinate = other.coordinate
        self.letterId = other.letterId
        self.letterFile = other.letterFile
        self.objectId = other.objectId
        self.image = other.image
        
    }
    
    
    func getView( mapView: MKMapView) -> MKAnnotationView {
        
       
        
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: self.objectId)
        
        if anView == nil {
            anView = MKAnnotationView(annotation: self, reuseIdentifier: self.objectId)
            
            anView!.canShowCallout = true
        }
        else {
            anView!.annotation = self
        }
        let newWidth:CGFloat = self.getLetterWidth(mapView: mapView)
        self.setImageFile(width: newWidth)
        anView!.image = self.getResizedImage(newWidth: newWidth)
        
        anView!.alpha=self.getLetterOpacity(width: newWidth)

        return anView!
    }
    
    func setImageFile(width: CGFloat){
        self.setLetterFileResolution(width: width)
        self.image = UIImage(named:"letter_\(String(format: "%02d", letterFile))_\(String(format: "%02d", letterId)).png")!
        
    }
    
    
    func setLetterFileResolution(width: CGFloat){
        self.letterFile = 16
        
        let resized = width/1
      
        if resized < 16.0{
            self.letterFile = 16
        }
        else if resized < 32.0{
            self.letterFile = 32
        }
        else if resized < 64.0{
            self.letterFile = 64
        }
        else if resized < 128.0{
            self.letterFile = 128
        }
        else if resized < 256.0{
            self.letterFile = 256
        }
        else if resized < 512.0{
            self.letterFile = 512
        }
        else {
            self.letterFile = 1024
        }
    
            
    }
    
    func getLetterWidth( mapView: MKMapView) -> CGFloat{
        
        var pixels:CGFloat = 64.0
        
        //if UIDevice.current.model=="iPhone"{
        //
        //    pixels=32
        //}
        //else if UIDevice.current.model=="iPad"{
        //pixels=50
        //}
        //else{
        //    pixels=32
        //}z
        
        pixels=pixels/getZoomLevel(mapView: mapView)
        return pixels
        
        
    }
    
    
    

    
    
    func getResizedImage(newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    
    func getLetterOpacity(width: CGFloat) -> CGFloat{
        
        var opacity: CGFloat = 1

        if width <= LETTER_OPACITY_FLOOR
        {
            //opacity = 0
        }
        else if width >= LETTER_OPACITY_CEIL
        {
            //opacity = 1
        }
        else
        {
            //opacity = (width - LETTER_OPACITY_FLOOR)/(LETTER_OPACITY_CEIL - LETTER_OPACITY_FLOOR)
        }
        return opacity
        
    }
}

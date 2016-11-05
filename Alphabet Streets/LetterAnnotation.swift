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
    var letterId: Int!
    var letterFile: Int!
    var objectId: String = "xxxxxx"
    var image: UIImage = UIImage()
    let zoomFactor: CGFloat = 30
    
    var toUpdate: Bool = false
    
    init(coord: CLLocationCoordinate2D) {
        super.init()
        self.coordinate=coord
        self.letterId = 0
        self.letterFile = 16
        
    }
    
    
    func getView( mapView: MKMapView) -> MKAnnotationView {
        
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if anView == nil {
            anView = MKAnnotationView(annotation: self, reuseIdentifier: reuseId)
            
            anView!.canShowCallout = true
        }
        else {
            anView!.annotation = self
        }
        let newWidth:CGFloat = self.getLetterWidth(mapView: mapView)
        self.setImageFile(width: newWidth)
        anView!.image = self.getResizedImage(newWidth: self.getLetterWidth(mapView: mapView))
            
        

        return anView!
    }
    
    func setImageFile(width: CGFloat){
        self.setLetterFileResolution(width: width)
        self.image = UIImage(named:"letter_\(String(format: "%02d", letterFile))_\(String(format: "%02d", letterId)).png")!
        
    }
    
    func setLetterFileResolution(width: CGFloat){
        self.letterFile = 16
      
        if width < 16.0{
            self.letterFile = 16
        }
        else if width < 32.0{
            self.letterFile = 32
        }
        else if width < 64.0{
            self.letterFile = 64
        }
        else if width < 128.0{
            self.letterFile = 128
        }
        else if width < 256.0{
            self.letterFile = 256
        }
        else if width < 512.0{
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
        //}
        
        pixels=pixels/self.getZoomLevel(mapView: mapView)
        return pixels
        
        
    }
    
    func getZoomLevel(mapView: MKMapView) -> CGFloat{
        let MERCATOR_RADIUS:CGFloat = 85445659.44705395
        let longitudeDelta: CLLocationDegrees = mapView.region.span.longitudeDelta
        let mapWidthInPixels: CGFloat = mapView.bounds.size.width
        let zoomScale: CGFloat = CGFloat(longitudeDelta) * MERCATOR_RADIUS * CGFloat(M_PI) / (180.0 * mapWidthInPixels);
        let zoom: CGFloat = zoomScale/self.zoomFactor
        return zoom
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
    
}

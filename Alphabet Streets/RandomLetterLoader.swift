//
//  RandomLetterLoader.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 03/11/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import Foundation

import Pods_Alphabet_Streets
import MapKit

class RandomLetterLoader {
    
    
    var points_to_upload: NSMutableArray = []
    var map: MKMapView!
    
    
    init(map: MKMapView) {
        
        self.map=map
        

        
    }

    
    
    func getAutoGeneratedLetters() -> [LetterAnnotation]{
        var letters:[LetterAnnotation]=[]
        let arraryOfCoords: NSMutableArray = self.getGridOfCoords()
        for coord in arraryOfCoords{
            let letterAnnotation:LetterAnnotation = LetterAnnotation(coord: coord as! CLLocationCoordinate2D)
            
            letters.append(letterAnnotation)
            
            
        }
        return letters
    }
    
    
    func getGridOfCoords() -> NSMutableArray{
        let coords:NSMutableArray=[]
        let topLeft: CLLocationCoordinate2D = self.getMapTopLeftCoordinate()
        
        let bottomRight: CLLocationCoordinate2D = self.getMapBottomRightCoordinate()
        
        
        
        var coord_to_add: CLLocationCoordinate2D = topLeft

        
        while coord_to_add.latitude > bottomRight.latitude{
            coord_to_add.longitude = topLeft.longitude
            coord_to_add.latitude = self.getNextUnEqualLatitude(coord_to_add)
            
            while coord_to_add.longitude < bottomRight.longitude{
                coord_to_add.longitude = self.getNextUnEqualLongitude(coord_to_add)
                
                if coord_to_add.latitude < topLeft.latitude && coord_to_add.longitude > topLeft.longitude{
                    
                    coords.add(coord_to_add)
                }
                
                
            }
            
        }
//        print (topLeft,bottomRight,coords.count)
        return coords
    }
    func getNextUnEqualLatitude(_ coord: CLLocationCoordinate2D) -> CLLocationDegrees{
        let latitude: CLLocationDegrees = coord.latitude
        
        return latitude - CLLocationDegrees(LETTER_DENSITY)
    }
    func getNextUnEqualLongitude(_ coord: CLLocationCoordinate2D) -> CLLocationDegrees{
        let longitude: CLLocationDegrees = coord.longitude
        
        return longitude + CLLocationDegrees(LETTER_DENSITY)
    }
    
    
    func getNextEqualLatitude(_ coord: CLLocationCoordinate2D) -> CLLocationDegrees{
        var xyPoint: CGPoint = self.map.convert(coord, toPointTo: self.map.inputView)
        xyPoint.y = xyPoint.y + self.getLetterDensity()
        let newLocation = self.map.convert(xyPoint, toCoordinateFrom: self.map.inputView)
        return newLocation.latitude
    }
    func getNextEqualLongitude(_ coord: CLLocationCoordinate2D) -> CLLocationDegrees{
        var xyPoint: CGPoint = self.map.convert(coord, toPointTo: self.map.inputView)
        xyPoint.x = xyPoint.x + self.getLetterDensity()
        let newLocation = self.map.convert(xyPoint, toCoordinateFrom: self.map.inputView)
        return newLocation.longitude
    }
    func getLetterDensity() -> CGFloat
    {
        return LETTER_DENSITY / CGFloat(getZoomLevel(self.map))
    }
    
  
    
    func getMapTopLeftCoordinate() -> CLLocationCoordinate2D{
        let lat:CLLocationDegrees = CLLocationDegrees(round(RESOLUTION*(self.map.region.center.latitude + self.map.region.span.latitudeDelta))/RESOLUTION)
        let lon:CLLocationDegrees = CLLocationDegrees(round(RESOLUTION*(self.map.region.center.longitude - self.map.region.span.longitudeDelta))/RESOLUTION)
        let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lon)
         
        return coord
    }
    func getMapBottomRightCoordinate() -> CLLocationCoordinate2D{
        let lat:CLLocationDegrees = CLLocationDegrees(round(RESOLUTION*(self.map.region.center.latitude - self.map.region.span.latitudeDelta))/RESOLUTION)
        let lon:CLLocationDegrees = CLLocationDegrees(round(RESOLUTION*(self.map.region.center.longitude + self.map.region.span.longitudeDelta))/RESOLUTION)
        let coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return coord
    }
    
    
    func uploadAnnotations(){
        
        for object in self.points_to_upload{
            self.uploadAnnotation(object as! Array<Any>)
            self.points_to_upload.remove(object)
            
        }
        
        
    }
    
    func uploadAnnotation(_ obj: Array<Any>){
        
    }

    
    

    func areLettersStillVisible() -> Bool{
        let zoom_level = getZoomLevel(self.map)
       
    
        if(zoom_level <= ZOOM_CUT_OFF){
            return true
        }
        else{
            return false
        }
    }
    
    
    
    func addLetterToUploadQueue() {
        
    }
    
    
    func downloadLettersForArea() {
        
    }
    
    
    
    
}

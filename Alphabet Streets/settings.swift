//
//  settings.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 07/11/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import Foundation
import MapKit

let LETTER_WIDTH: CGFloat = 15
let HOVER_HEIGHT: CGFloat = 75
let ZOOM_CUT_OFF: CGFloat = 3
let RESOLUTION: CLLocationDegrees = 1000.0
let LETTER_DENSITY: CGFloat = CGFloat(RESOLUTION)/1000000
let ZOOM_DISTANCE: CLLocationDegrees = 4/RESOLUTION
let METERS_BETWEEN_LOADS: CGFloat = 75


let LETTER_OPACITY_FLOOR: CGFloat = 16
let LETTER_OPACITY_CEIL: CGFloat = 32


func getZoomLevel(mapView: MKMapView) -> CGFloat{
    let MERCATOR_RADIUS:CGFloat = 85445659.44705395
    let longitudeDelta: CLLocationDegrees = mapView.region.span.longitudeDelta
    let mapWidthInPixels: CGFloat = mapView.bounds.size.width
    let zoomScale: CGFloat = CGFloat(longitudeDelta) * MERCATOR_RADIUS * CGFloat(M_PI) / (180.0 * mapWidthInPixels);
    let zoom: CGFloat = zoomScale/LETTER_WIDTH
    return zoom
}

func getMetersBetweenLetterRefreshes(mapView: MKMapView) -> CLLocationDegrees{

    return CLLocationDegrees(METERS_BETWEEN_LOADS * getZoomLevel(mapView: mapView))
}

func getTapingDistance() -> CLLocationDistance{
    return 25
}


func getHoverHeight(mapView: MKMapView) -> CGFloat{
    return HOVER_HEIGHT/getZoomLevel(mapView: mapView)
    
}

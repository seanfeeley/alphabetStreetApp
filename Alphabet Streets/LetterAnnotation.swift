//
//  LetterAnnotation.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 03/11/2016.
//  Copyright © 2016 sean-feeley. All rights reserved.
//

import Foundation

import MapKit


class LetterAnnotation: MKPointAnnotation{
    
    var letterId: UInt32!
    var letterFile: Int!
    var objectId: String = "xxxxxx"
    var image: UIImage = UIImage()
    let zoomFactor: CGFloat = LETTER_WIDTH
    var toUpdate: Bool = false
    var isHovering: Bool = false
    var z: CGFloat = 0
    
    init(coord: CLLocationCoordinate2D) {
        super.init()
        self.coordinate=coord
        self.generateObjectId()
        self.generateRandomLetter()
        self.generateRandomCoordShift()
        self.letterFile = 16
        
    }
    
    init(other:LetterAnnotation){
        super.init()
        self.coordinate = other.coordinate
        self.letterId = other.letterId
        self.letterFile = other.letterFile
        self.objectId = other.objectId
        self.image = other.image
        
    }
    
    init(active: ActiveLetter){
        super.init()
        self.objectId=active.objectId
        self.coordinate=active.getCoordinate()
        self.generateRandomLetter()
    }
    
    
    init(objectId:String){
        super.init()
        self.objectId=objectId
        self.revertCoordinate()
        self.generateRandomLetter()
    }
    
    
    
    
    
    func getView( _ mapView: MKMapView) -> MKAnnotationView {
        
        
        
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: self.objectId)
        
        if anView == nil {
            anView = MKAnnotationView(annotation: self, reuseIdentifier: self.objectId)
            
            anView!.canShowCallout = true
        }
        else {
            anView!.annotation = self
        }
        let newWidth:CGFloat = self.getLetterWidth(mapView)
        self.setImageFile(newWidth)
        anView!.image = self.getResizedImage(newWidth)
        
        anView!.alpha = self.getLetterOpacity(newWidth)
        anView!.layer.zPosition = self.getZPosition()


        
        return anView!
    }
    
    func getZPosition() -> CGFloat{
        if self.isHovering == true{
            return 1
        }
        return 0
    }

    func getLetterWidth( _ mapView: MKMapView) -> CGFloat{
        
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
        
        pixels=pixels/getZoomLevel(mapView)
        return pixels
        
        
    }
    
    func getLetterOpacity(_ width: CGFloat) -> CGFloat{
        
        let opacity: CGFloat = 1
        
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
    


    func getResizedImage(_ newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    





    

    func generateObjectId(){
        let shortentedLat=String(format: "%.3f", self.coordinate.latitude)
        let shortentedLon=String(format: "%.3f", self.coordinate.longitude)
        self.objectId="\(shortentedLat)/\(shortentedLon)"
        
        
    }
    
    func revertCoordinate(){
        let shortentedLat = CLLocationDegrees(self.objectId.components(separatedBy: "/")[0])
        let shortentedLon = CLLocationDegrees(self.objectId.components(separatedBy: "/")[1])
        self.coordinate.latitude = shortentedLat!
        self.coordinate.latitude = shortentedLon!
        self.generateRandomCoordShift()
        
    }
    
    
    
    func generateRandomLetter(){
        self.letterId = UInt32( get_random_doubles(1)[0] * 26 )
        
    }
    
    func generateRandomCoordShift(){
        let randoms = get_random_doubles(2)
        let latShift: CLLocationDegrees = CLLocationDegrees ( randoms[0] * Double(LETTER_DENSITY)/2)
        let lonShift: CLLocationDegrees = CLLocationDegrees ( randoms[0] * Double(LETTER_DENSITY)/2)
        self.coordinate.latitude = self.coordinate.latitude - CLLocationDegrees(LETTER_DENSITY)/4 + latShift
        self.coordinate.longitude = self.coordinate.longitude - CLLocationDegrees(LETTER_DENSITY)/4 + lonShift
    }
    
    func get_random_doubles(_ count: Int) -> [Double]{
        var seed:Double = Double(self.getRandomSeed())
        var randoms:[Double] = []
        var c = 0
        while c < count{
//            print(seed)
            seed = get_psuedo_random_int(seed)
            randoms.append(seed / 10000.0)
            c = c + 1
        }
        return randoms
    }
    
    
    func get_psuedo_random_int(_ number: Double) -> Double{
        let whole_number:Int = Int(number)
        let squared: Int = whole_number * whole_number
        let squared_string: NSString = String(format: "%08d",squared) as NSString
        let middle_string: String = (squared_string.substring(with: NSRange(location:2, length: 4)) as NSString) as String
        var middle_int:Int = 0
        if middle_string.characters.count != 0{
            middle_int = Int(middle_string as String)!
        }
        let middle_double:Double = Double(middle_int)
//        print("\(number) -> \(squared) -> \(squared_string) -> \(middle_string) -> \(middle_int) -> \(middle_double)")
        return middle_double
    }

    
    func getRandomSeed() -> Int {
        let number: Int = self.get_objectid_hash_number()
        let absNumber:Int = abs(Int(number))
        var absNumberStr:String = String(absNumber)
        let absNumberStrReverse:String = String(absNumberStr.characters.reversed())
        let big_seed:Double = Double(absNumberStrReverse)!
        let wee_seed:Double = big_seed / pow(10.0,Double(absNumberStrReverse.characters.count))
        let seed:Int = Int(wee_seed * 10000)
        return seed
    }
    
    func get_objectid_hash_number() -> Int{
        let md5_hex = self.MD5(self.objectId)
        let md5_string:String = md5_hex!.map { String(format: "%02hhx", $0) }.joined()
        let md5_short_string = (md5_string as NSString).substring(to: 4)
        let i:Int = Int(md5_short_string, radix:16)!
        return i
    }
    
    func MD5(_ string: String) -> Data? {
        guard let messageData = string.data(using:String.Encoding.utf8) else { return nil }
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData
    }
    
    func reverseNumber(_ number:Int) -> Int{
        let absNumber:Int = abs(number)
        var absNumberStr:String = String(absNumber)
        let absNumberStrReverse:String = String(absNumberStr.characters.reversed().dropLast(4))
        let absNumberReverse:Int = Int(absNumberStrReverse)!
        print(absNumberReverse)
        return absNumberReverse
    }
    

    

    
    

    
    func setImageFile(_ width: CGFloat){
        self.setLetterFileResolution(width)
        self.image = UIImage(named:"letter_\(String(format: "%02d", letterFile))_\(String(format: "%02d", letterId)).png")!
        
    }
    
    
    func setLetterFileResolution(_ width: CGFloat){
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
    

    
}



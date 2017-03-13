//
//  RemoteLetterAnnotation.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 12/03/2017.
//  Copyright © 2017 sean-feeley. All rights reserved.
//

import Foundation
import MapKit
import Parse

class RemoteLetter: PFObject, PFSubclassing {
    @NSManaged var  oid: NSString?
    @NSManaged var  clat: NSNumber?
    @NSManaged var  clon: NSNumber?
    @NSManaged var  olat: NSNumber?
    @NSManaged var  olon: NSNumber?
    
    override init(){
        super.init()
    }
    
    init(letter: ActiveLetter) {
        super.init()
        self.oid = letter.objectId as NSString
        self.clat = letter.latitude as NSNumber
        self.clon = letter.longitude as NSNumber
        self.olat = letter.original_latitude as NSNumber
        self.olon = letter.original_longitude as NSNumber
        self.acl = make_acl()
    }
    
    func make_acl() -> PFACL{
        let acl = PFACL()
        acl.getPublicReadAccess = true
        acl.getPublicWriteAccess = true
        return acl
    }
    
    class func parseClassName() -> String {
        return "ActiveLetters"
    }
}



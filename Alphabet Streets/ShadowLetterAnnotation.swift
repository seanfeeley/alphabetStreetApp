//
//  ShadowLetterAnnotation.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 12/03/2017.
//  Copyright © 2017 sean-feeley. All rights reserved.
//

import Foundation
import MapKit


class HoverAnnotation: LetterAnnotation {
    
    init(letter: LetterAnnotation){
        super.init(other: letter)
    }
    
    
    
    override func setImageFile(_ width: CGFloat){
        self.setLetterFileResolution(width)
        self.image = UIImage(named:"hover_letter_\(String(format: "%02d", letterFile))_\(String(format: "%02d", letterId)).png")!
        
    }
    
    override func getZPosition() -> CGFloat{
        return 0.5
    }
    
    override func getLetterOpacity(_ width: CGFloat) -> CGFloat{
        
        let opacity: CGFloat = 0.3
        
        
        return opacity
        
    }
    
    
}

//
//  help_screen.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 17/04/2017.
//  Copyright © 2017 sean-feeley. All rights reserved.
//

import UIKit
import Foundation

class HelpScreenClass: UIViewController{
    
    
    @IBOutlet var help: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("init bruv")
    }

}

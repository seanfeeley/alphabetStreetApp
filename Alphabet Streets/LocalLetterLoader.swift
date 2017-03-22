//
//  LocalLetterLoader.swift
//  Alphabet Streets
//
//  Created by Sean Feeley on 12/03/2017.
//  Copyright © 2017 sean-feeley. All rights reserved.
//

import Foundation

class LocalLetterLoader {
    var data_saving_key: String
    
    init(data_saving_key: String){
        self.data_saving_key=data_saving_key
    }
    
    
    func getAllLetters() -> [String: ActiveLetter]{
        if let data = UserDefaults.standard.data(forKey: self.data_saving_key),
            let local_letters = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: ActiveLetter] {
            
            
            return local_letters
        } else {
            
            return [:]
        }
    }
    
    func addLetterToData(_ letter: ActiveLetter){
        var local_letters = self.getAllLetters()
        local_letters[letter.objectId]=letter
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: local_letters)
        UserDefaults.standard.set(encodedData, forKey: self.data_saving_key)
    }
    
    
}

//
//  UIKitButton.swift
//  Elemnt
//
//  Created by Keaton Burleson on 9/25/18.
//

import Foundation
import UIKit

class UIKitButton: UIButton{
    override init(frame: CGRect) {
        super.init(frame: frame)
        setRadius()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setRadius()
    }
    
    func setRadius(){
        self.layer.cornerRadius = 4.0
        self.layer.masksToBounds = true
    }
}

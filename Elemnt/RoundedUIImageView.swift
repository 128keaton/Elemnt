//
//  RoundedUIImageView.swift
//  Elemnt
//
//  Created by Keaton Burleson on 9/25/18.
//

import Foundation
import UIKit

class RoundedUIImageView: AsyncImageView{
    override init(frame: CGRect) {
        super.init(frame: frame)
        setFrame()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFrame()
    }
    
    func setFrame(){
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 0.1
    }
}

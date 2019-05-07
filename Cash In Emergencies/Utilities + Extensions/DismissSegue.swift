//
//  DismissSegue.swift
//  Cash in Emergencies
//
//  Created by Matthew Cheetham on 27/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import Foundation

class DismissSegue: UIStoryboardSegue {
    
    override func perform() {
        source.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

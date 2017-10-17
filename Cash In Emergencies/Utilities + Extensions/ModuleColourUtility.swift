//
//  ModuleColourUtility.swift
//  Cash In Emergencies
//
//  Created by Joel Trew on 12/10/2017.
//  Copyright © 2017 3 SIDED CUBE. All rights reserved.
//

import Foundation
import ThunderBasics
import DMSSDK

/// Provides utility methods for hardcoded colours
class ModuleColourUtility {
    
    /// Fallback colour if none of the hardcoded values amtch the provided input
    private static var fallBackColour = UIColor(hexString: "ed1b2e")!
    
    /// Returns a hardcoded module colour for a given module
    ///
    /// - Parameter module: the module to find the matching colour for
    /// - Returns: a specified hardcoded colour or a fallback colour
    class func colour(for module: Module) -> UIColor {
        
        guard let hierarchy = module.metadata?["hierarchy"] as? String else {

            return fallBackColour
        }
        return ModuleColourUtility.colour(for: hierarchy)
    }
    
    /// Returns a hardcoded module colour for a given module hierarchy
    ///
    /// - Parameter moduleHierarchy: a string of the hierarchy of the module i.e "2"
    /// - Returns: a specified hardcoded colour or a fallback colour
    class func colour(for moduleHierarchy: String) -> UIColor {
        switch moduleHierarchy {
            
        case "1": return UIColor(hexString: "9D9FA2")
        case "2": return UIColor(hexString: "F47D78")
        case "3": return UIColor(hexString: "C5E1B1")
        case "4": return UIColor(hexString: "9BD7D7")
        case "5": return UIColor(hexString: "0079A7")
            
        default:
            return fallBackColour
        }
    }
}

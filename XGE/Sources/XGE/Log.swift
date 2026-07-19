//
//  Log.swift
//  XGE
//
//  Created by Douglas McNamara on 8/23/25.
//

import Foundation

@MainActor
open class Log {
    
    @MainActor
    private static var _instance:Log?
    
    public static var instance:Log {
        get { _instance! }
    }
    
    public static var hasInstance:Bool {
        get { _instance != nil }
    }
    
    public init() {
        Log._instance = self
    }
    
    open func put(_ value:Any) {
        print("\(value)")
    }
}


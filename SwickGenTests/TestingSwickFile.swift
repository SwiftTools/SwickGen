//
// Copyright (c) 2016 Swick contributors
// This program is made available under the terms of the MIT License.
//

// This file is used only for testing Swick

//public protocol TestingProtocol {
//    var getSetString: String { get set }
//    var getArrayString: [String] { get }
//}
//
//private protocol TestingProtocolTypealias {
//    typealias T
//}

protocol Math {
    func sum(a: Int, b: Int) -> Int
}

class TestingSwickFile {
    static let filename = #file
    
//    static let staticLetStringTypeInference = "string"
//    
//    static let staticLetArrayString: [String] = ["string", "string"]
//    
//    static func staticFuncClosure(
//        closure: String -> Int,
//        @autoclosure autoclosure: () -> Int,
//        @noescape noescapeClosure: () -> Int,
//        @autoclosure(escaping) escapingAutoclosure: () -> Int)
//    {
//        escapingAutoclosure()
//    }
//    
//    final func templateFunc<T>(t: T) -> T {
//        return t
//    }
//    
//    @inline(__always) func staticFuncInlineAlways<T: Equatable>(t: T) -> String {
//        return "string"
//    }
    
    @inline(never) func funcInlineNever<T, U: CollectionType where U.Generator.Element == T>(u: U) -> String? {
        return "string"
    }
    
}
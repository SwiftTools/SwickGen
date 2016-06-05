////
//// Copyright (c) 2016 Swick contributors
//// This program is made available under the terms of the MIT License.
////
//
//import Quick
//import Nimble
//
//private class SourceKitStructureScanningLoggerMock {
//    func logUnexpectedDeclaration(declaration: Declaration, inScanner: AnyObject) {
//    }
//}
//
//class SwickGenSpec: QuickSpec {
//    override func spec() {
//        describe("SourceKitStructureScanner") {
//            let logger = SourceKitStructureScanningLoggerMock()
//            
//            it("can scan swift files") {
//                let existingFileName = TestingSwickFile.filename
//                
//                if let structure: SourceKitStructure = SourceKitStructureScanner(sourceKitStructure: existingFileName, logger: logger)?.scanStructure() {
//                    
//                    expect(structure.substructure.count).to(equal(4))
//                    
//                    let structure_TestingSwickFile = structure.substructure[0]
//                    
//                    expect(structure_TestingSwickFile.kind).to(equal(SourceKitKind.decl_class))
//                    expect(structure_TestingSwickFile.name).to(equal("TestingSwickFile"))
//                    expect(structure_TestingSwickFile.accessibility).to(equal(SourceKitAccessibility.Internal))
//                    expect(structure_TestingSwickFile.substructure.count).to(equal(1))
//                    
//                    let structure_TestingSwickFile_filename = structure_TestingSwickFile.substructure[0]
//                    
//                    expect(structure_TestingSwickFile_filename.kind).to(equal(SourceKitKind.decl_var_static))
//                    expect(structure_TestingSwickFile_filename.accessibility).to(equal(SourceKitAccessibility.Internal))
//                    expect(structure_TestingSwickFile_filename.typename).to(equal("filename")) // Unfortunately, type inference doesn't work
//                    expect(structure_TestingSwickFile_filename.name).to(equal("filename"))
//                    
//                    let structure_TestingProtocol = structure.substructure[1]
//                    
//                    expect(structure_TestingProtocol.kind).to(equal(SourceKitKind.decl_protocol))
//                    expect(structure_TestingProtocol.accessibility).to(equal(SourceKitAccessibility.Public))
//                    
//                    let structure_TestingProtocol_getSetString = structure_TestingProtocol.substructure[0]
//                    
//                    expect(structure_TestingProtocol_getSetString.kind).to(equal(SourceKitKind.decl_var_instance))
//                    expect(structure_TestingProtocol_getSetString.accessibility).to(equal(SourceKitAccessibility.Public))
//                    expect(structure_TestingProtocol_getSetString.setter_accessibility).to(equal(SourceKitAccessibility.Public))
//                    
//                } else {
//                    XCTFail("failed to open file '\(existingFileName)'")
//                }
//            }
//        }
//    }
//}
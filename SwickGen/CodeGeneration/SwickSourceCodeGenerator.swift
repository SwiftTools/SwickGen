import Switt

class CodeSynthesizer {
    func synthesize(parameterName parameterName: ParameterName) -> String {
        switch parameterName {
        case .None:
            return "_"
        case .Some(let name):
            return name
        }
    }
    
    func synthesize(typeAnnotation typeAnnotation: TypeAnnotation) -> String {
        return synthesize(type: typeAnnotation.type)
    }
    
    func synthesize(throwing throwing: Throwing) -> String {
        switch throwing {
        case .Throws:
            return "throws"
        case .Rethrows:
            return "rethrows"
        }
    }
    
    func synthesize(typeIdentifierElement typeIdentifierElement: TypeIdentifierElement) -> String {
        let genericArguments: String = typeIdentifierElement.genericArguments.flatMap { (genericArguments: GenericArguments) -> String in
            return "<" + genericArguments.types.array.map(synthesize).joinWithSeparator(", ") + ">"
        } ?? ""
        return typeIdentifierElement.name + genericArguments
    }
    
    func synthesize(type type: Type) -> String {
        switch type {
        case .Array(let type):
            return "[" + synthesize(type: type) + "]"
        case .Closure(let closureType):
            return synthesize(type: closureType.argument)
                + (closureType.throwing.flatMap{ " " + synthesize(throwing: $0) } ?? "")
                + " -> "
                + synthesize(type: closureType.returnType)
        case .Dictionary(let key, let value):
            return "[" + synthesize(type: key) + ":" + synthesize(type: value) + "]"
        case .Identifier(let typeIdentifier):
            return typeIdentifier.elements.array.map(synthesize).joinWithSeparator(".")
        case .ImplicitlyUnwrappedOptional(let type):
            return synthesize(type: type) + "1"
        case .Optional(let type):
            return synthesize(type: type) + "?"
        case .ProtocolComposition(let protocolCompositionType):
            return "ProtocolComposition UNSUPPORTED"
        case .ProtocolType(let type):
            return synthesize(type: type) + ".Protocol"
        case .Tuple(let tupleType):
            return "Tuple UNSUPPORTED"
        case .TypeType(let type):
            return synthesize(type: type) + ".Type"
        }
    }
    
    func synthesize(functionResult functionResult: FunctionResult?) -> String {
        return functionResult.flatMap { synthesize(type: $0.type) } ?? "Void"
    }
}

class SwickSourceCodeGenerator {
    private let output = StringStream()
    private let file: SwiftFile
    
    init(file: SwiftFile) {
        self.file = file
    }
    
    private func vars(proto: Protocol) {
        output << "let mockManager: Swick.MockManager"
    }
    
    struct FuncParts {
        // func routine<A0: Swick.Matcher where A0.MatchingType == String>(a: A0) -> Void
        
        var name: String // routine
        
        var genericParametersJoined: String
        var argumentsJoined: String
        var matcherArgumentsJoined: String
        var argumentTypesJoined: String
        var argumentNamesJoined: String
        var matchingFuncsJoined: String
        var functionResult: String
        var functionId: String
        var stubBuilder: String
    }
    
    private func funcParts(function: ProtocolFunc) -> FuncParts? {
        var funcParts: FuncParts?
        
        switch function.name {
        case .Function(let name):
            if function.signature.curry.count > 1 {
                funcParts = nil
                output << "// Function is not handled: \(name)"
                output << "// Currying is not supported (and I doubt I would support that)"
            } else {
                var genericParameters: [String] = [] // "A0: Swick.Matcher"
                var requirementClauses: [String] = [] // "A0.MatchingType == String"
                var arguments: [String] = [] // "a: String"
                var argumentNames: [String] = [] // "a"
                var matcherArguments: [String] = [] // "a: A0"
                var argumentTypes: [String] = [] // "String"
                var matchingFuncs: [String] = [] // a.valueIsMatching(args.0)
                
                for (index, parameter) in function.signature.parameters.enumerate() {
                    let genericParameterName = "A\(index)"
                    let typeName = CodeSynthesizer().synthesize(typeAnnotation: parameter.type)
                    let localName = "a\(index)"
                    
                    genericParameters.append("\(genericParameterName): Swick.Matcher")
                    requirementClauses.append("\(genericParameterName).MatchingType == \(typeName)")
                    
                    let externalParameterName = parameter.externalName
                        ?? (index == 0 ? nil : parameter.localName)
                    
                    let argumentExtLocalNames = externalParameterName
                        .flatMap({ CodeSynthesizer().synthesize(parameterName: $0) + " " + localName })
                        ?? localName
                    
                    arguments.append(
                        argumentExtLocalNames + ": " + typeName
                    )
                    matcherArguments.append(
                        argumentExtLocalNames + ": " + genericParameterName
                    )
                    argumentTypes.append(typeName)
                    matchingFuncs.append("\(localName).valueIsMatching(args.\(index))")
                    argumentNames.append(localName)
                }
                
                let genericParametersInternal: String = [
                    genericParameters.joinWithSeparator(", "),
                    requirementClauses.joinWithSeparator(", ")
                    ].joinWithSeparator(" where ")
                let genericParametersJoined = genericParametersInternal.isEmpty ? "" : "<\(genericParametersInternal)>"
                
                let argumentsJoined = arguments.joinWithSeparator(", ")
                let matcherArgumentsJoined = matcherArguments.joinWithSeparator(", ")
                let argumentTypesJoined = argumentTypes.joinWithSeparator(", ")
                let matchingFuncsJoined = matchingFuncs.joinWithSeparator(" && ")
                let argumentNamesJoined = argumentNames.joinWithSeparator(", ")
                
                let functionResult = CodeSynthesizer().synthesize(functionResult: function.signature.result)
                let functionId = "\(name)(\(argumentsJoined))->\(functionResult)"
                
                let stubBuilder = "Swick.StubForFunctionBuilder<(\(argumentTypesJoined)), \(functionResult)>"
                
                funcParts = FuncParts(
                    name: name,
                    genericParametersJoined: genericParametersJoined,
                    argumentsJoined: argumentsJoined,
                    matcherArgumentsJoined: matcherArgumentsJoined,
                    argumentTypesJoined: argumentTypesJoined,
                    argumentNamesJoined: argumentNamesJoined,
                    matchingFuncsJoined: matchingFuncsJoined,
                    functionResult: functionResult,
                    functionId: functionId,
                    stubBuilder: stubBuilder
                )
            }
        case .Operator(let name):
            funcParts = nil
            output << "// Operator is not handled: \(name)"
            output << "// Operators aren't supported yet"
        }
        
        return funcParts
    }
    
    private func stubBuilder(proto: Protocol) {
        output << "class StubBuilder: Swick.StubBuilder {"
        output.indent {
            output << "private let mockManager: Swick.MockManager"
            output << ""
            output << "required init(mockManager: Swick.MockManager) {"
            output << "    self.mockManager = mockManager"
            output << "}"
            output << ""
            for function in proto.funcs {
                if let funcParts = funcParts(function) {
                    stubBuilderFunc(funcParts)
                    output << ""
                }
            }
        }
        output << "}"
    }
    
    private func stubBuilderFunc(funcParts: FuncParts) {
        output << "func \(funcParts.name)\(funcParts.genericParametersJoined)(\(funcParts.matcherArgumentsJoined)) -> \(funcParts.stubBuilder) {"
        output.indent {
            matcher(funcParts)
            output << "return \(funcParts.stubBuilder)("
            output << "    functionId: \"\(funcParts.functionId)\","
            output << "    mockManager: mockManager,"
            output << "    matcher: matcher"
            output << ")"
        }
        output << "}"
    }
    
    private func expectationBuilder(proto: Protocol) {
        output << "class ExpectationBuilder: Swick.ExpectationBuilder {"
        output.indent {
            output << "private let mockManager: Swick.MockManager"
            output << "private let times: Swick.FunctionalMatcher<UInt>"
            output << "private let fileLine: Swick.FileLine"
            output << ""
            output << "required init(mockManager: Swick.MockManager, times: Swick.FunctionalMatcher<UInt>, fileLine: Swick.FileLine) {"
            output << "    self.mockManager = mockManager"
            output << "    self.times = times"
            output << "    self.fileLine = fileLine"
            output << "}"
            output << ""
            for function in proto.funcs {
                if let funcParts = funcParts(function) {
                    expectationBuilderFunc(funcParts)
                    output << ""
                }
            }
        }
        output << "}"
    }
    
    private func matcher(funcParts: FuncParts) {
        output << "let matcher = Swick.FunctionalMatcher<(\(funcParts.argumentTypesJoined))>(matchingFunction: { (args: (\(funcParts.argumentTypesJoined))) -> Bool in"
        output << "    return \(funcParts.matchingFuncsJoined)"
        output << "})"
    }
    
    private func expectationBuilderFunc(funcParts: FuncParts) {
        output << "func \(funcParts.name)\(funcParts.genericParametersJoined)(\(funcParts.matcherArgumentsJoined)) {"
        output.indent {
            matcher(funcParts)
            output << ""
            output << "mockManager.addExpecatation("
            output << "    functionId: \"\(funcParts.functionId)\","
            output << "    fileLine: fileLine,"
            output << "    times: times,"
            output << "    matcher: matcher"
            output << ")"
        }
        output << "}"
    }
    
    private func initializer(proto: Protocol) {
        output << "init(mockManager: Swick.MockManager) {"
        output << "    self.mockManager = mockManager"
        output << "}"
    }
    
    private func convenienceInitializer(proto: Protocol) {
        output << "convenience init(file: StaticString = #file, line: UInt = #line) {"
        output << "    self.init(mockManager: Swick.SwickMockManager(fileLine: Swick.FileLine(file: file, line: line)))"
        output << "}"
    }
    
    private func mockedFuncs(proto: Protocol) {
        for function in proto.funcs {
            if let funcParts = funcParts(function) {
                mockedFunc(funcParts)
                output << ""
            }
        }
    }
    
    private func mockedFunc(funcParts: FuncParts) {
        output << "func \(funcParts.name)(\(funcParts.argumentsJoined)) -> \(funcParts.functionResult) {"
        output << "    return try! mockManager.call(functionId: \"\(funcParts.functionId)\", args: (\(funcParts.argumentNamesJoined)))"
        output << "}"
    }
    
    private func mockProtocol(proto: Protocol) {
        output << "class \(proto.name)Mock: \(proto.name), MockType {"
        output.indent {
            vars(proto)
            output << ""
            stubBuilder(proto)
            output << ""
            expectationBuilder(proto)
            output << ""
            initializer(proto)
            output << ""
            convenienceInitializer(proto)
            output << ""
            mockedFuncs(proto)
        }
        output << "}"
    }
    
    func mockFile() -> String {
        output << "import Swick"
        output << ""
        
        for proto in file.protocols {
            mockProtocol(proto)
            output << ""
        }
        return output.string
    }
}
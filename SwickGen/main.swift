//
// Copyright (c) 2016 Swick contributors
// This program is made available under the terms of the MIT License.
//

import Cocoa
import Switt

class StringStream {
    private(set) var string: String = ""
    private var indentation: String = ""
    
    func appendLine(string: String) {
        self.string += indentation + string + "\n"
    }
    
    func indent(@noescape closure: () -> ()) {
        let oldIndentation = indentation
        indentation += "    "
        
        closure()
        
        indentation = oldIndentation
    }
}

func <<(output: StringStream, input: String) {
    output.appendLine(input)
}

func <<(output: StringStream, @noescape closure: () -> ()) {
    output.indent(closure)
}

if let file = SwiftFileParserImpl().parseFile(TestingSwickFile.filename) {
    let code = SwickSourceCodeGenerator(file: file).mockFile()
    print(code)
} else {
    print("error")
}

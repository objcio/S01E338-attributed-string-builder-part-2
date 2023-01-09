import Cocoa

protocol AttributedStringConvertible {
    func attributedString(environment: Environment) -> [NSAttributedString]
}

struct Environment {
    var attributes: [NSAttributedString.Key: Any] = [:]
}

extension String: AttributedStringConvertible {
    func attributedString(environment: Environment) -> [NSAttributedString] {
        [.init(string: self, attributes: environment.attributes)]
    }
}

extension AttributedString: AttributedStringConvertible {
    func attributedString(environment: Environment) -> [NSAttributedString] {
        [.init(self)]
    }
}

struct Build: AttributedStringConvertible {
    var build: (Environment) -> [NSAttributedString]

    func attributedString(environment: Environment) -> [NSAttributedString] {
        build(environment)
    }
}

@resultBuilder
struct AttributedStringBuilder {
    static func buildBlock(_ components: AttributedStringConvertible...) -> some AttributedStringConvertible {
        Build { environment in
            components.flatMap { $0.attributedString(environment: environment) }
        }
    }

    static func buildOptional<C: AttributedStringConvertible>(_ component: C?) -> some AttributedStringConvertible {
        Build { environment in
            component?.attributedString(environment: environment) ?? []
        }
    }
}

struct Joined<Content: AttributedStringConvertible>: AttributedStringConvertible {
    var separator: AttributedStringConvertible = "\n"
    @AttributedStringBuilder var content: Content

    func attributedString(environment: Environment) -> [NSAttributedString] {
        [single(environment: environment)]
    }

    func single(environment: Environment) -> NSAttributedString {
        let pieces = content.attributedString(environment: environment)
        guard let f = pieces.first else { return .init() }
        let result = NSMutableAttributedString(attributedString: f)
        let sep = separator.attributedString(environment: environment)
        for piece in pieces.dropFirst() {
            for sepPiece in sep {
                result.append(sepPiece)
            }
            result.append(piece)
        }
        return result
    }
}

extension AttributedStringConvertible {
    func joined(separator: AttributedStringConvertible = "\n") -> some AttributedStringConvertible {
        Joined(separator: separator, content: {
            self
        })
    }

    func run(environment: Environment) -> NSAttributedString {
        Joined(separator: "", content: {
            self
        }).single(environment: environment)
    }
}


#if DEBUG
@AttributedStringBuilder
var example: some AttributedStringConvertible {
    "Hello, World!"
    if 2 > 1 {
        "Test"
    }
    try! AttributedString(markdown: "Hello *world*")
}

import SwiftUI

let sampleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "Tiempos Text", size: 14)!
]

struct DebugPreview: PreviewProvider {
    static var previews: some View {
        let attStr = example
            .joined()
            .run(environment: .init(attributes: sampleAttributes))
        Text(AttributedString(attStr))
    }
}
#endif

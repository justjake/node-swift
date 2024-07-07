import SwiftSyntax
import SwiftSyntaxMacros

struct NodeNameMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let identifier = declaration.as(VariableDeclSyntax.self)?.identifier else {
            context.diagnose(.init(node: Syntax(declaration), message: .expectedProperty))
            return []
        }

        guard let attributes = node.nodeAttributes else {
            context.diagnose(.init(node: Syntax(node), message: .expectedName))
            return []
        }

        return []

        // return ["""
        // @NodeActor static let $\(identifier) = \
        //     NodeProperty(attributes: \(attributes), \\_NodeSelf.\(identifier))
        // """]
    }
}

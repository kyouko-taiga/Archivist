import SwiftSyntax

extension PatternBindingSyntax {

  /// `true` iff `self` denotes a computed property.
  var isComputedProperty: Bool {
    switch accessorBlock?.accessors {
    case .some(.accessors(let a)):
      for k in a.map(\.accessorSpecifier.tokenKind) {
        if (k == .keyword(.didSet)) || (k == .keyword(.willSet)) { return true }
      }
      return false

    case .some(.getter):
      return true

    default:
      return false
    }
  }

  /// The expression of `self`'s type.
  var typeSyntax: ExprSyntax {
    
    if let a = typeAnnotation {
      ExprSyntax("\(a.type).self")
    } else {
      ExprSyntax("type(of: \(pattern))")
    }
  }

}

extension VariableDeclSyntax {

  /// `true` iff `self` denotes a `let` property.
  var isLet: Bool {
    bindingSpecifier.tokenKind == .keyword(.let)
  }

  /// `true` iff `self` denotes a computed property.
  var isComputedProperty: Bool {
    if let b = bindings.uniqueElement {
      return b.isComputedProperty
    } else {
      return false
    }
  }

}

/// Returns a function accepting a declaration modifier and returning `true` iff the kind of that
/// modifier is contained in `tokens`.
func isOneOf<T: Collection<TokenKind>>(_ tokens: T) -> (DeclModifierSyntax) -> Bool {
  { (m) in tokens.contains(m.name.tokenKind) }
}

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public struct ArchivableMacro {}

extension ArchivableMacro: ExtensionMacro {

  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // Nothing to do if there is an explicit conformance already.
    if protocols.isEmpty { return [] }

    let s: DeclSyntax = """
    extension \(type.trimmed): Archivable {}
    """
    return [s.cast(ExtensionDeclSyntax.self)]
  }

}

extension ArchivableMacro: MemberMacro {

  public static func expansion<Decl: DeclGroupSyntax, Context: MacroExpansionContext>(
    of attribute: AttributeSyntax,
    providingMembersOf decl: Decl,
    in context: Context
  ) throws -> [DeclSyntax] {
    if let d = decl.as(EnumDeclSyntax.self) {
      try expansion(of: attribute, providingMembersOf: d, in: context)
    } else if let d = decl.as(StructDeclSyntax.self) {
      try expansion(of: attribute, providingMembersOf: d, in: context)
    } else {
      throw MacroExpansionErrorMessage(
        "@Archivable can only be attached to an enum or struct declaration.")
    }
  }

  /// Returns the expansion of the macro attached to an enum declaration.
  public static func expansion<Context: MacroExpansionContext>(
    of attribute: AttributeSyntax,
    providingMembersOf declaration: EnumDeclSyntax,
    in context: Context
  ) throws -> [DeclSyntax] {
    let cs = declaration.memberBlock.members
      .compactMap({ (m) in m.decl.as(EnumCaseDeclSyntax.self) })
    let es = cs.flatMap(\.elements)

    let i = try enumDeserializer(es, in: context)
    let w = try enumSerializer(es, in: context)
    return [DeclSyntax(i), DeclSyntax(w)]
  }

  /// Returns the expansion of the macro attached to a struct declaration.
  public static func expansion<Context: MacroExpansionContext>(
    of attribute: AttributeSyntax,
    providingMembersOf declaration: StructDeclSyntax,
    in context: Context
  ) throws -> [DeclSyntax] {
    let (bs, ds) = archivableMembers(of: declaration)
    for d in ds {
      context.diagnose(d)
    }

    let i = try structDeserializer(bs, in: context)
    let w = try structSerializer(bs, in: context)
    return [DeclSyntax(i), DeclSyntax(w)]
  }

  /// Returns the deserializer for an enum containing `es`.
  private static func enumDeserializer<Context: MacroExpansionContext>(
    _ es: [EnumCaseElementSyntax], in context: Context
  ) throws -> InitializerDeclSyntax {
    let ns = parameterNames(in: context)

    if es.isEmpty {
      return try InitializerDeclSyntax(deserializerHead(in: context, namingParameters: ns)) {
        "fatalError()"
      }
    } else {
      return try InitializerDeclSyntax(deserializerHead(in: context, namingParameters: ns)) {
        try SwitchExprSyntax("switch try \(ns.archive).readByte()") {
          for (i, e) in es.enumerated() {
            SwitchCaseSyntax("case \(raw: i):") { ExprSyntax("self = \(rhs(e))") }
          }
          SwitchCaseSyntax("default:") { "throw ArchiveError.invalidInput" }
        }
      }
    }

    func rhs(_ e: EnumCaseElementSyntax) -> ExprSyntax {
      let callee = ExprSyntax(".\(e.name)")
      if let clause = e.parameterClause, !clause.parameters.isEmpty {
        return ExprSyntax(
          FunctionCallExprSyntax(callee: callee) {
            for p in clause.parameters {
              LabeledExprSyntax(
                label: p.firstName?.text,
                expression: ExprSyntax(
                  "try \(ns.archive).read(\(p.type).self, in: &\(ns.context))"))
            }
          })
      } else {
        return callee
      }
    }
  }

  /// Returns the serializer for an enum containing `es`.
  private static func enumSerializer<Context: MacroExpansionContext>(
    _ es: [EnumCaseElementSyntax], in context: Context
  ) throws -> FunctionDeclSyntax {
    let ns = parameterNames(in: context)
    return try FunctionDeclSyntax(serializerHead(in: context, namingParameters: ns)) {
      try SwitchExprSyntax("switch self") {
        for (i, e) in es.enumerated() {
          let (p, ms) = pattern(e)
          SwitchCaseSyntax(p) {
            ExprSyntax("\(ns.archive).write(byte: \(raw: i))")
            for m in ms { ExprSyntax("try \(ns.archive).write(\(m), in: &\(ns.context))") }
          }
        }
      }
    }

    func pattern(_ e: EnumCaseElementSyntax) -> (SyntaxNodeString, [TokenSyntax]) {
      if let clause = e.parameterClause, !clause.parameters.isEmpty {
        let ns = (0 ..< clause.parameters.count).map({ (i) in context.makeUniqueName("x\(i)") })
        let ss = ns.map(\.text).joined(separator: ", ")
        return (SyntaxNodeString("case let .\(e.name)(\(raw: ss)):"), ns)
      } else {
        return (SyntaxNodeString("case .\(e.name):"), [])
      }
    }
  }

  /// Returns the members of `declaration` that must be archived.
  private static func archivableMembers(
    of declaration: StructDeclSyntax
  ) -> ([PatternBindingSyntax], [Diagnostic]) {
    var bs: [PatternBindingSyntax] = []
    var ds: [Diagnostic] = []

    for m in declaration.memberBlock.members {
      guard
        let v = m.decl.as(VariableDeclSyntax.self),
        !v.modifiers.contains(where: isOneOf([.keyword(.static), .keyword(.lazy)])),
        !v.isComputedProperty,
        !v.bindings.isEmpty
      else { continue }

      if v.bindings.count > 1 {
        let m = MacroExpansionErrorMessage("@Archivable does not support binding lists.")
        ds.append(.init(node: v, message: m))
      } else if let b = v.bindings.first, (!v.isLet || b.initializer == nil) {
        bs.append(b)
      }
    }

    return (bs, ds)
  }

  /// Returns the deserializer for a struct containing `bs`.
  private static func structDeserializer<Context: MacroExpansionContext>(
    _ bs: [PatternBindingSyntax], in context: Context
  ) throws -> InitializerDeclSyntax {
    let ns = parameterNames(in: context)
    return try InitializerDeclSyntax(deserializerHead(in: context, namingParameters: ns)) {
      for b in bs {
        "self.\(b.pattern) = try \(ns.archive).read(\(b.typeSyntax), in: &\(ns.context))"
      }
    }
  }

  /// Returns the serializer for a struct containing `bs`.
  private static func structSerializer<Context: MacroExpansionContext>(
    _ bs: [PatternBindingSyntax], in context: Context
  ) throws -> FunctionDeclSyntax {
    let ns = parameterNames(in: context)
    return try FunctionDeclSyntax(serializerHead(in: context, namingParameters: ns)) {
      for b in bs {
        "try \(ns.archive).write(\(b.pattern), in: &\(ns.context))"
      }
    }
  }

  /// Returns the declaration of a deserializer sans body.
  private static func deserializerHead<Context: MacroExpansionContext>(
    in context: Context,
    namingParameters ns: (archive: TokenSyntax, context: TokenSyntax)
  ) -> SyntaxNodeString {
    let a = context.makeUniqueName("Archive")
    return """
      public init<\(a)>(
        from \(ns.archive): inout ReadableArchive<\(a)>, in \(ns.context): inout Any
      ) throws
      """
  }

  /// Returns the declaration of a serializer sans body.
  private static func serializerHead<Context: MacroExpansionContext>(
    in context: Context,
    namingParameters ns: (archive: TokenSyntax, context: TokenSyntax)
  ) -> SyntaxNodeString {
    let a = context.makeUniqueName("Archive")
    return """
    public func write<\(a)>(
      to \(ns.archive): inout WriteableArchive<\(a)>, in \(ns.context): inout Any
    ) throws
    """
  }

  /// Returns parameter names for the archive and context of a serializer or deserializer.
  private static func parameterNames(
    in context: MacroExpansionContext
  ) -> (archive: TokenSyntax, context: TokenSyntax) {
    let a = context.makeUniqueName("archive")
    let c = context.makeUniqueName("context")
    return (a, c)
  }

}

@main
struct ArchivistMacros: CompilerPlugin {

  var providingMacros: [Macro.Type] = [ArchivableMacro.self]

}

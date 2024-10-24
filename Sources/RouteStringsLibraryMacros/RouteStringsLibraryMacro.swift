import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

enum RouteStringsMacroError: Error {
    case onlyApplicableToRouteCollection
    case bootFunctionMissing
    case bootFunctionMissingBody
    case bootFunctionMissingSegmentInArgument
    case bootFunctionMultipleSegments
    case bootFunctionSegmentNotStringSegmentSyntax
    case couldNotIdentifyFunctionName
}

public struct RouteStringsMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        
        try Self.verifyConformanceToRouteCollection(declaration: declaration)
        
        let bootFunction = try Self.findBootFunction(declaration: declaration)
        
        guard let body = bootFunction.body else {
            throw RouteStringsMacroError.bootFunctionMissingBody
        }
        
        var functions = [String]()
        
        for statement in body.statements {
            
            guard let item = statement.item.as(FunctionCallExprSyntax.self) else {
                continue
            }
            
            guard let calledExpression = item.calledExpression.as(MemberAccessExprSyntax.self) else {
                continue
            }
            
            guard ["get", "post", "put", "delete", "patch"].contains(calledExpression.declName.trimmedDescription) else {
                continue
            }
            
            var functionName: String? = nil
            var path = [String]()
            
            for argument in item.arguments {
                if let expression = argument.expression.as(StringLiteralExprSyntax.self) {
                    
                    guard let firstSegment = expression.segments.first else {
                        throw RouteStringsMacroError.bootFunctionMissingSegmentInArgument
                    }
                    
                    guard expression.segments.count == 1 else {
                        throw RouteStringsMacroError.bootFunctionMultipleSegments
                    }
                    
                    guard let segment = firstSegment.as(StringSegmentSyntax.self) else {
                        throw RouteStringsMacroError.bootFunctionSegmentNotStringSegmentSyntax
                    }
                    
                    path += [segment.content.trimmedDescription]
                    
                } else if let expresssion = argument.expression.as(DeclReferenceExprSyntax.self) {
                    
                    guard argument.label?.text == "use" else {
                        continue
                    }
                    
                    functionName = expresssion.baseName.trimmedDescription
                }
            }
            
            guard let functionName else {
                throw RouteStringsMacroError.couldNotIdentifyFunctionName
            }
            
            functions +=
                [#"""
                static func \#(functionName)(\#(Self.argumentsCode(path: path))query: [String : String?]? = nil) -> String? {
                
                    \#(Self.pathCode(path: path))
                    var urlComponents = URLComponents()
                    
                    urlComponents.path = path
                    
                    urlComponents.queryItems = query?.map { key, value in
                        URLQueryItem(name: key, value: value)
                    }
                    
                    return urlComponents.string
                }
                """#]
        }
        
        let code = "\n" + functions.joined(separator: "\n\n")
        
        return [DeclSyntax(stringLiteral: code)]
    }
    
    private static func pathCode(path: [String]) -> String {
        
        var code =
                #"""
                var path = ""\#n\#n
                """#
        
        for element in path {
            if element.hasPrefix(":") {
                
                let cleanedElement = element.dropFirst()
                
                code +=
                #"""
                guard let percentEncoded\#(cleanedElement) = \#(cleanedElement).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    return nil
                }
                
                path += "/\(percentEncoded\#(cleanedElement))"\#n
                """#
                
            } else if element.hasPrefix("*") {
                continue
            } else {
                code += #"path += "/\#(element)"\#n"#
            }
        }
        
        return code
    }
    
    private static func argumentsCode(path: [String]) -> String {
        
        var arguments = [String]()
        
        for element in path {
            if element.hasPrefix(":") {
                arguments += ["\(element.dropFirst()): String"]
            }
        }
        
        if !arguments.isEmpty {
            return arguments.joined(separator: ", ") + ", "
        }
        
        return ""
    }
    
    private static func findBootFunction(declaration: some DeclGroupSyntax) throws -> FunctionDeclSyntax {
        
        guard let bootFunction = declaration.memberBlock.members.first(where: { member in
            
            if !member.decl.is(FunctionDeclSyntax.self) {
                return false
            }
            
            return member.trimmedDescription
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: " ", with: "")
                .hasPrefix("funcboot(routes:RoutesBuilder)throws{")
            
        }) else {
            throw RouteStringsMacroError.bootFunctionMissing
        }
        
        return bootFunction.decl.as(FunctionDeclSyntax.self)!
    }
    
    private static func verifyConformanceToRouteCollection(declaration: some DeclGroupSyntax) throws {
        
        var hasRouteCollection: Bool = false
        
        for inheritedType in declaration.inheritanceClause?.inheritedTypes ?? [] {
            if inheritedType.type.trimmedDescription == "RouteCollection" {
                hasRouteCollection = true
                break
            }
        }
        
        guard hasRouteCollection else {
            throw RouteStringsMacroError.onlyApplicableToRouteCollection
        }
    }
}

@main
struct RouteStringsLibraryPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RouteStringsMacro.self,
    ]
}

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(RouteStringsLibraryMacros)
import RouteStringsLibraryMacros

let testMacros: [String: Macro.Type] = [
    "RouteStrings": RouteStringsMacro.self,
]
#endif

final class RouteStringsLibraryTests: XCTestCase {
    
    func testEmpty() throws {
        #if canImport(RouteStringsLibraryMacros)
        assertMacroExpansion(
            """
            @RouteStrings
            struct Controller: Codable, RouteCollection {
                func boot(routes: RoutesBuilder) throws {
                }
            }
            """,
            expandedSource:
            """
            struct Controller: Codable, RouteCollection {
                func boot(routes: RoutesBuilder) throws {
                }
            }
            """,
            macros: testMacros)
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testNoArgumentsProducesFunctionsWithOnlyQuery() throws {
        #if canImport(RouteStringsLibraryMacros)
        assertMacroExpansion(
            #"""
            @RouteStrings
            struct Controller: Codable, RouteCollection {
                func boot(routes: RoutesBuilder) throws {
                    sessionRoute.get("order", use: getOrders)
                }
            }
            """#,
            expandedSource:
            #"""
            struct Controller: Codable, RouteCollection {
                func boot(routes: RoutesBuilder) throws {
                    sessionRoute.get("order", use: getOrders)
                }

                static func getOrders(query: [String : String?]? = nil) -> String? {

                    var path = ""

                    path += "/order"

                    var urlComponents = URLComponents()

                    urlComponents.path = path

                    urlComponents.queryItems = query?.map { key, value in
                        URLQueryItem(name: key, value: value)
                    }

                    return urlComponents.string
                }
            }
            """#,
            macros: testMacros)
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testRouteStrings() throws {
        #if canImport(RouteStringsLibraryMacros)
        assertMacroExpansion(
            #"""
            @RouteStrings
            struct Controller: Codable, RouteCollection {
                func boot(routes: RoutesBuilder) throws {
                    sessionRoute.get("order", ":id", use: getOrder)
                    routes.post("retailer", ":retailerPublicId", "order", ":id", use: postOrder)
                }
            }
            """#,
            expandedSource:
            #"""
            struct Controller: Codable, RouteCollection {
                func boot(routes: RoutesBuilder) throws {
                    sessionRoute.get("order", ":id", use: getOrder)
                    routes.post("retailer", ":retailerPublicId", "order", ":id", use: postOrder)
                }

                static func getOrder(id: String, query: [String : String?]? = nil) -> String? {

                    var path = ""

                    path += "/order"
            
                    path += "/\(id)"

                    var urlComponents = URLComponents()

                    urlComponents.path = path

                    urlComponents.queryItems = query?.map { key, value in
                        URLQueryItem(name: key, value: value)
                    }

                    return urlComponents.string
                }

                static func postOrder(retailerPublicId: String, id: String, query: [String : String?]? = nil) -> String? {

                    var path = ""

                path += "/retailer"
                path += "/\(retailerPublicId)"
                path += "/order"
                path += "/\(id)"

                    var urlComponents = URLComponents()
                    
                    urlComponents.path = path
                    
                    urlComponents.queryItems = query?.map { key, value in
                        URLQueryItem(name: key, value: value)
                    }
                    
                    return urlComponents.string
                }
            }
            """#,
            macros: testMacros)
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

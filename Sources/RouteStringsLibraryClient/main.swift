import RouteStringsLibrary
import Foundation

// Dummy Vapor types //
struct RoutesBuilder {
    func get(_: String..., use: () -> Void) {}
}

protocol RouteCollection {
    func boot(routes: RoutesBuilder) throws
}
// Dummy Vapor types //

@RouteStrings
struct Controller: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("retailer", ":retailerPublicId", "order", ":orderId", use: getOrder)
        routes.get("retailer", ":retailerPublicId", "order", use: getOrders)
    }
    
    // Dummy route handlers
    func getOrder() {}
    func getOrders() {}
}

print(Controller.getOrders(retailerPublicId: "dsjd809sd",
                           query: ["search" : "meow",
                                   "per" : "100",
                                   "page" : "1"]) ?? "<wut>")

print(Controller.getOrder(retailerPublicId: "dsjd809sd",
                          orderId: "12345") ?? "<wut>")

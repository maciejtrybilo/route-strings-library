Working with server side rendered web, especially with HTMX, there is a need to refer to a lot of endpoints that are defined in the same codebase and it's a little awkward to do it in a stringly fasion like this
```swift
tr(.on(.click, "window.location.href='/orders/\(item.orderId)';"))
```
or like this
```swift
.hx.get(nextPageURL())
...
    private func nextPageURL() -> String {
        var urlComponents = URLComponents()
        urlComponents.queryItems = [URLQueryItem(name: "page", value: "\(pageNumber + 1)"),
                                    URLQueryItem(name: "per", value: "\(per)")]
        return "/orders-content?" + urlComponents.query!
    }
```

This repository contains the `@RouteStrings` Swift macro that can be applied on a Vapor route collection. The macro generates a function for each route that takes all parameters as arguments and returns the url string
```Swift
@RouteStrings
struct OrdersController: RouteCollection, Sendable {
    
    let sessionRoute: RoutesBuilder
    
    func boot(routes: RoutesBuilder) throws {
        sessionRoute.get("orders-content", use: getOrdersContent)
        sessionRoute.get("orders", ":id", use: getOrder)
    }
...
```

Now it's impossible to make a mistake and it's easier to navigate to the endpoint implementation:
```Swift
tr(.on(.click, "window.location.href='\(OrdersController.getOrder(id: item.orderId)!)';"))

  .hx.get(nextPageURL())
...
    private func nextPageURL() -> String {
        
        OrdersController.getOrdersContent(query: ["page" : "\(pageNumber + 1)",
                                                  "per" : "\(per)"])!
    }
```

Note: The macro ignores routes with widlcards which makes sense I think. It doesn't support grouped routes currently.

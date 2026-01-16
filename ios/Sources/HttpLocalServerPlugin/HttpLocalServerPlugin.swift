// import Foundation
// import Capacitor

// /**
//  * Please read the Capacitor iOS Plugin Development Guide
//  * here: https://capacitorjs.com/docs/plugins/ios
//  */
// @objc(HttpLocalServerPlugin)
// public class HttpLocalServerPlugin: CAPPlugin, CAPBridgedPlugin {
//     public let identifier = "HttpLocalServerPlugin"
//     public let jsName = "HttpLocalServer"
//     public let pluginMethods: [CAPPluginMethod] = [
//         CAPPluginMethod(name: "echo", returnType: CAPPluginReturnPromise)
//     ]
//     private let implementation = HttpLocalServer()

//     @objc func echo(_ call: CAPPluginCall) {
//         let value = call.getString("value") ?? ""
//         call.resolve([
//             "value": implementation.echo(value)
//         ])
//     }
// }

import Foundation
import Capacitor
@objc(HttpLocalServerPlugin)
public class HttpLocalServerPlugin: CAPPlugin, CAPBridgedPlugin, HttpLocalServerDelegate {
    public let identifier = "HttpLocalServerPlugin"
    public let jsName = "HttpLocalServer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "connect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "disconnect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sendResponse", returnType: CAPPluginReturnPromise)
    ]
    var localServer: HttpLocalServer?

    @objc func connect(_ call: CAPPluginCall) {
        if localServer == nil {
            localServer = HttpLocalServer(delegate: self)
        }
        localServer?.connect(call)
    }

    @objc func disconnect(_ call: CAPPluginCall) {
        if localServer != nil {
            localServer?.disconnect(call)
        } else {
            call.resolve()
        }
    }

    @objc func sendResponse(_ call: CAPPluginCall) {
        guard let requestId = call.getString("requestId"),
              let body = call.getString("body") else {
            call.reject("Missing requestId or body")
            return
        }
        HttpLocalServer.handleJsResponse(requestId: requestId, body: body)
        call.resolve()
    }

    // Delegate method
    public func httpLocalServerDidReceiveRequest(_ data: [String: Any]) {
        notifyListeners("onRequest", data: data)
    }
}

// import Foundation

// @objc public class HttpLocalServer: NSObject {
//     @objc public func echo(_ value: String) -> String {
//         print(value)
//         return value
//     }
// }

// import Foundation

// @objc public class HttpLocalServer: NSObject {
//     @objc public func echo(_ value: String) -> String {
//         print(value)
//         return value
//     }
// }

import Foundation
import GCDWebServer
import Capacitor

public protocol HttpLocalServerDelegate: AnyObject {
    func httpLocalServerDidReceiveRequest(_ data: [String: Any])
}

@objc public class HttpLocalServer: NSObject {
    var webServer: GCDWebServer?
    weak var delegate: HttpLocalServerDelegate?
    static var pendingResponses = [String: (String) -> Void]()
    static let queue = DispatchQueue(label: "HttpLocalServer.pendingResponses")

    public init(delegate: HttpLocalServerDelegate) {
        self.delegate = delegate
    }

    @objc public func connect(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.webServer = GCDWebServer()

            self.webServer?.addHandler(
                match: { method, url, headers, path, query in
                        GCDWebServerRequest(method: method, url: url, headers: headers, path: path, query: query)
                },
                processBlock: { request in
                    let method = request.method
                    let path = request.url.path
                    var body: String? = nil

                    if let dataRequest = request as? GCDWebServerDataRequest, let text = String(data: dataRequest.data, encoding: .utf8) {
                        body = text
                    }

                    let requestId = UUID().uuidString
                    var responseString: String? = nil

                    // Set up a semaphore so we can block until JS responds or timeout (3s)
                    let semaphore = DispatchSemaphore(value: 0)
                    Self.queue.async {
                        Self.pendingResponses[requestId] = { responseBody in
                            responseString = responseBody
                            semaphore.signal()
                        }
                    }

                    // Notify delegate (plugin) with the request info
                    let req: [String: Any?] = [
                        "requestId": requestId,
                        "method": method,
                        "path": path,
                        "body": body
                    ]
                    self.delegate?.httpLocalServerDidReceiveRequest(req.compactMapValues { $0 })

                    // Wait for JS response or timeout
                    _ = semaphore.wait(timeout: .now() + 3.0)
                    Self.queue.async {
                        Self.pendingResponses.removeValue(forKey: requestId)
                    }
                    let reply = responseString ?? "{\"error\":\"Timeout waiting for JS response\"}"

                    let response = GCDWebServerDataResponse(text: reply)
                    response?.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
                    response?.setValue("GET,POST,OPTIONS", forAdditionalHeader: "Access-Control-Allow-Methods")
                    response?.setValue("origin, content-type, accept, authorization", forAdditionalHeader: "Access-Control-Allow-Headers")
                    response?.setValue("3600", forAdditionalHeader: "Access-Control-Max-Age")
                    response?.contentType = "application/json"
                    return response!
                }
            )

            let port: UInt = 8080
            do {
                try self.webServer?.start(options: [
                    GCDWebServerOption_Port: port,
                    GCDWebServerOption_BonjourName: "",
                    GCDWebServerOption_BindToLocalhost: false
                ])
                let ip = Self.getWiFiAddress() ?? "127.0.0.1"
                call.resolve([
                    "ip": ip,
                    "port": port
                ])
            } catch {
                call.reject("Failed to start server: \(error.localizedDescription)")
            }
        }
    }

    @objc public func disconnect(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            self?.webServer?.stop()
            self?.webServer = nil
            call.resolve()
        }
    }

    // Called by plugin when JS responds
    static func handleJsResponse(requestId: String, body: String) {
        queue.async {
            if let callback = pendingResponses[requestId] {
                callback(body)
                pendingResponses.removeValue(forKey: requestId)
            }
        }
    }

    // Helper: get WiFi IP address (IPv4)
    static func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" { // WiFi interface
                        var addr = interface.ifa_addr.pointee
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        break
                    }
                }
                ptr = interface.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}

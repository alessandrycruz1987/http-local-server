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

// MARK: - Protocol
public protocol HttpLocalServerDelegate: AnyObject {
    func httpLocalServerDidReceiveRequest(_ data: [String: Any])
}

// MARK: - HttpLocalServer
@objc public class HttpLocalServer: NSObject {
    // MARK: - Properties
    private var webServer: GCDWebServer?
    private weak var delegate: HttpLocalServerDelegate?
    
    private static var pendingResponses = [String: (String) -> Void]()
    private static let queue = DispatchQueue(label: "com.cappitolian.HttpLocalServer.pendingResponses", qos: .userInitiated)
    
    private let defaultTimeout: TimeInterval = 5.0
    private let defaultPort: UInt = 8080
    
    // MARK: - Initialization
    public init(delegate: HttpLocalServerDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Public Methods
    @objc public func connect(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                call.reject("Server instance deallocated")
                return
            }
            
            // Stop existing server if running
            if self.webServer?.isRunning == true {
                self.webServer?.stop()
            }
            
            self.webServer = GCDWebServer()
            self.setupHandlers()
            
            do {
                try self.startServer()
                let ip = Self.getWiFiAddress() ?? "127.0.0.1"
                call.resolve([
                    "ip": ip,
                    "port": self.defaultPort
                ])
            } catch {
                call.reject("Failed to start server: \(error.localizedDescription)")
            }
        }
    }
    
    @objc public func disconnect(_ call: CAPPluginCall? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                call?.reject("Server instance deallocated")
                return
            }
            
            self.disconnect()
            call?.resolve()
        }
    }
    
    // MARK: - Static Methods
    static func handleJsResponse(requestId: String, body: String) {
        queue.async {
            if let callback = pendingResponses[requestId] {
                callback(body)
                pendingResponses.removeValue(forKey: requestId)
            }
        }
    }
    
    // MARK: - Private Methods
    private func disconnect() {
        webServer?.stop()
        webServer = nil
        
        // Clear pending responses
        Self.queue.async {
            Self.pendingResponses.removeAll()
        }
    }
    
    private func setupHandlers() {
        guard let webServer = webServer else { return }
        
        // GET requests
        webServer.addDefaultHandler(
            forMethod: "GET",
            request: GCDWebServerRequest.self,
            processBlock: { [weak self] request in
                return self?.processRequest(request) ?? self?.errorResponse() ?? GCDWebServerResponse()
            }
        )
        
        // POST requests (with body)
        webServer.addDefaultHandler(
            forMethod: "POST",
            request: GCDWebServerDataRequest.self,
            processBlock: { [weak self] request in
                return self?.processRequest(request) ?? self?.errorResponse() ?? GCDWebServerResponse()
            }
        )
        
        // PUT requests (with body)
        webServer.addDefaultHandler(
            forMethod: "PUT",
            request: GCDWebServerDataRequest.self,
            processBlock: { [weak self] request in
                return self?.processRequest(request) ?? self?.errorResponse() ?? GCDWebServerResponse()
            }
        )
        
        // PATCH requests (with body)
        webServer.addDefaultHandler(
            forMethod: "PATCH",
            request: GCDWebServerDataRequest.self,
            processBlock: { [weak self] request in
                return self?.processRequest(request) ?? self?.errorResponse() ?? GCDWebServerResponse()
            }
        )
        
        // DELETE requests
        webServer.addDefaultHandler(
            forMethod: "DELETE",
            request: GCDWebServerRequest.self,
            processBlock: { [weak self] request in
                return self?.processRequest(request) ?? self?.errorResponse() ?? GCDWebServerResponse()
            }
        )
        
        // OPTIONS requests (CORS preflight)
        webServer.addDefaultHandler(
            forMethod: "OPTIONS",
            request: GCDWebServerRequest.self,
            processBlock: { [weak self] request in
                return self?.corsResponse() ?? GCDWebServerResponse()
            }
        )
    }
    
    private func processRequest(_ request: GCDWebServerRequest) -> GCDWebServerResponse {
        let method = request.method
        let path = request.url.path
        let body = extractBody(from: request)
        let headers = request.headers
        let query = request.query
        
        let requestId = UUID().uuidString
        var responseString: String?
        
        // Setup semaphore for synchronous waiting
        let semaphore = DispatchSemaphore(value: 0)
        
        Self.queue.async {
            Self.pendingResponses[requestId] = { responseBody in
                responseString = responseBody
                semaphore.signal()
            }
        }
        
        // Notify delegate with request info
        var requestData: [String: Any] = [
            "requestId": requestId,
            "method": method,
            "path": path
        ]
        
        if let body = body {
            requestData["body"] = body
        }
        
        if let headers = headers as? [String: String], !headers.isEmpty {
            requestData["headers"] = headers
        }
        
        if let query = query, !query.isEmpty {
            requestData["query"] = query
        }
        
        delegate?.httpLocalServerDidReceiveRequest(requestData)
        
        // Wait for JS response or timeout
        let result = semaphore.wait(timeout: .now() + defaultTimeout)
        
        // Cleanup
        Self.queue.async {
            Self.pendingResponses.removeValue(forKey: requestId)
        }
        
        // Handle timeout
        if result == .timedOut {
            let timeoutResponse = "{\"error\":\"Request timeout\",\"requestId\":\"\(requestId)\"}"
            return createJsonResponse(timeoutResponse, statusCode: 408)
        }
        
        let reply = responseString ?? "{\"error\":\"No response from handler\"}"
        return createJsonResponse(reply)
    }
    
    private func extractBody(from request: GCDWebServerRequest) -> String? {
        guard let dataRequest = request as? GCDWebServerDataRequest else {
            return nil
        }
        
        return String(data: dataRequest.data, encoding: .utf8)
    }
    
    private func createJsonResponse(_ body: String, statusCode: Int = 200) -> GCDWebServerDataResponse {
        let response = GCDWebServerDataResponse(text: body)
        response?.statusCode = statusCode
        response?.contentType = "application/json"
        
        // CORS headers
        response?.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
        response?.setValue("GET, POST, PUT, PATCH, DELETE, OPTIONS", forAdditionalHeader: "Access-Control-Allow-Methods")
        response?.setValue("Origin, Content-Type, Accept, Authorization", forAdditionalHeader: "Access-Control-Allow-Headers")
        response?.setValue("true", forAdditionalHeader: "Access-Control-Allow-Credentials")
        response?.setValue("3600", forAdditionalHeader: "Access-Control-Max-Age")
        
        return response ?? GCDWebServerDataResponse()
    }
    
    private func corsResponse() -> GCDWebServerDataResponse {
        return createJsonResponse("{}", statusCode: 204)
    }
    
    private func errorResponse() -> GCDWebServerDataResponse {
        return createJsonResponse("{\"error\":\"Server error\"}", statusCode: 500)
    }
    
    private func startServer() throws {
        guard let webServer = webServer else {
            throw NSError(
                domain: "HttpLocalServer",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "WebServer not initialized"]
            )
        }
        
        let options: [String: Any] = [
            GCDWebServerOption_Port: defaultPort,
            GCDWebServerOption_BonjourName: "",
            GCDWebServerOption_BindToLocalhost: false,
            GCDWebServerOption_AutomaticallySuspendInBackground: false
        ]
        
        try webServer.start(options: options)
    }
    
    // MARK: - Network Utilities
    static func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        
        defer {
            freeifaddrs(ifaddr)
        }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            // Check for IPv4 interface
            guard addrFamily == UInt8(AF_INET) else { continue }
            
            let name = String(cString: interface.ifa_name)
            
            // WiFi interface (en0) or cellular (pdp_ip0)
            guard name == "en0" || name == "pdp_ip0" else { continue }
            
            var addr = interface.ifa_addr.pointee
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            
            let result = getnameinfo(
                &addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            
            guard result == 0 else { continue }
            
            address = String(cString: hostname)
            
            // Prefer en0 (WiFi) over pdp_ip0 (cellular)
            if name == "en0" {
                break
            }
        }
        
        return address
    }
}
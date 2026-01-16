// package com.cappitolian.plugins.httplocalservice;

// import android.util.Log;

// public class LocalIp {

//     public String echo(String value) {
//         Log.i("Echo", value);
//         return value;
//     }
// }

// package com.cappitolian.plugins.httplocalservice;

// import android.util.Log;

// public class LocalIp {

//     public String echo(String value) {
//         Log.i("Echo", value);
//         return value;
//     }
// }

package com.cappitolian.plugins.httplocalservice;

import android.content.Context;
import android.net.wifi.WifiManager;
import android.text.format.Formatter;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import fi.iki.elonen.NanoHTTPD;
import java.io.IOException;
import java.util.UUID;
import java.util.concurrent.*;
import java.util.HashMap;
import java.util.Map;

public class HttpLocalServer {
    private LocalNanoServer server;
    private String localIp;
    private int port = 8080;
    private Plugin plugin;

    // Map to wait for responses from JS (key: requestId)
    private static final ConcurrentHashMap<String, CompletableFuture<String>> pendingResponses = new ConcurrentHashMap<>();

    public HttpLocalServer(Plugin plugin) {
        this.plugin = plugin;
    }

    public void connect(PluginCall call) {
        if (server == null) {
            localIp = getLocalIpAddress(plugin.getContext());
            server = new LocalNanoServer(localIp, port, plugin);
            try {
                server.start();
                JSObject ret = new JSObject();
                ret.put("ip", localIp);
                ret.put("port", port);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to start server: " + e.getMessage());
            }
        } else {
            call.reject("Server is already running");
        }
    }

    public void disconnect(PluginCall call) {
        if (server != null) {
            server.stop();
            server = null;
        }
        call.resolve();
    }

    // Called by plugin when JS responds
    public static void handleJsResponse(String requestId, String body) {
        CompletableFuture<String> future = pendingResponses.remove(requestId);
        if (future != null) {
            future.complete(body);
        }
    }

    // Helper to get local WiFi IP Address
    private String getLocalIpAddress(Context context) {
        WifiManager wm = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        if (wm != null && wm.getConnectionInfo() != null) {
            return Formatter.formatIpAddress(wm.getConnectionInfo().getIpAddress());
        }
        return "127.0.0.1"; // fallback
    }

    private static class LocalNanoServer extends NanoHTTPD {
        private Plugin plugin;

        public LocalNanoServer(String hostname, int port, Plugin plugin) {
            super(hostname, port);
            this.plugin = plugin;
        }

        @Override
        public Response serve(IHTTPSession session) {
            String path = session.getUri();
            String method = session.getMethod().name();

            // Read body if needed
            String body = "";
            if (session.getMethod() == Method.POST || session.getMethod() == Method.PUT) {
                try {
                    // Crear un mapa para almacenar los datos parseados
                    HashMap<String, String> files = new HashMap<>();
                    session.parseBody(files);
                    
                    // El body viene en el mapa con la clave "postData"
                    body = files.get("postData");
                    
                    // Si postData es null, intentar obtener de los parámetros (para form-data)
                    if (body == null || body.isEmpty()) {
                        // Para application/x-www-form-urlencoded
                        body = session.getQueryParameterString();
                    }
                    
                    // Log para debug
                    System.out.println("Body received: " + body);
                    
                } catch (Exception e) {
                    System.err.println("Error parsing body: " + e.getMessage());
                    e.printStackTrace();
                }
            }

            // Generate a unique requestId
            String requestId = UUID.randomUUID().toString();

            // Prepare data for JS
            JSObject req = new JSObject();
            req.put("requestId", requestId);
            req.put("method", method);
            req.put("path", path);
            req.put("body", body);
            req.put("headers", getHeadersAsJson(session)); // Opcional: para debug

            // Future to wait for JS response
            CompletableFuture<String> future = new CompletableFuture<>();
            pendingResponses.put(requestId, future);

            // Send event to JS
            if (plugin instanceof com.cappitolian.plugins.httplocalservice.HttpLocalServerPlugin) {
                ((com.cappitolian.plugins.httplocalservice.HttpLocalServerPlugin) plugin).fireOnRequest(req);
            }

            String jsResponse = null;
            try {
                // Wait up to 55 seconds for JS response
                jsResponse = future.get(55, TimeUnit.SECONDS);
            } catch (TimeoutException e) {
                jsResponse = "{\"error\": \"Timeout waiting for JS response\"}";
            } catch (Exception e) {
                jsResponse = "{\"error\": \"Error waiting for JS response\"}";
            } finally {
                pendingResponses.remove(requestId);
            }

            Response response = newFixedLengthResponse(Response.Status.OK, "application/json", jsResponse);
            addCorsHeaders(response);
            return response;
        }

        // Método auxiliar para obtener headers como JSObject
        private JSObject getHeadersAsJson(IHTTPSession session) {
            JSObject headers = new JSObject();
            try {
                for (Map.Entry<String, String> entry : session.getHeaders().entrySet()) {
                    headers.put(entry.getKey(), entry.getValue());
                }
            } catch (Exception e) {
                // ignore
            }
            return headers;
        }

        private void addCorsHeaders(Response response) {
            response.addHeader("Access-Control-Allow-Origin", "*");
            response.addHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
            response.addHeader("Access-Control-Allow-Headers", "origin, content-type, accept, authorization");
            response.addHeader("Access-Control-Max-Age", "3600");
        }
    }
}
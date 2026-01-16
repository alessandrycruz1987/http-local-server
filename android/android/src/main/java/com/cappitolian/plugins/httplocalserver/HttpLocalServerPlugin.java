// package com.cappitolian.plugins.httplocalserver;

// import com.getcapacitor.JSObject;
// import com.getcapacitor.Plugin;
// import com.getcapacitor.PluginCall;
// import com.getcapacitor.PluginMethod;
// import com.getcapacitor.annotation.CapacitorPlugin;

// @CapacitorPlugin(name = "HttpLocalServer")
// public class HttpLocalServerPlugin extends Plugin {

//     private HttpLocalServer implementation = new HttpLocalServer();

//     @PluginMethod
//     public void echo(PluginCall call) {
//         String value = call.getString("value");

//         JSObject ret = new JSObject();
//         ret.put("value", implementation.echo(value));
//         call.resolve(ret);
//     }
// }

// package com.cappitolian.plugins.httplocalserver;

// import com.getcapacitor.JSObject;
// import com.getcapacitor.Plugin;
// import com.getcapacitor.PluginCall;
// import com.getcapacitor.PluginMethod;
// import com.getcapacitor.annotation.CapacitorPlugin;

// @CapacitorPlugin(name = "HttpLocalServer")
// public class HttpLocalServerPlugin extends Plugin {

//     private HttpLocalServer implementation = new HttpLocalServer();

//     @PluginMethod
//     public void echo(PluginCall call) {
//         String value = call.getString("value");

//         JSObject ret = new JSObject();
//         ret.put("value", implementation.echo(value));
//         call.resolve(ret);
//     }
// }

package com.cappitolian.plugins.httplocalservice;

import com.getcapacitor.*;
import com.getcapacitor.annotation.CapacitorPlugin;
import org.json.JSONException;
import org.json.JSONObject;

@CapacitorPlugin(name = "HttpLocalServer")
public class HttpLocalServerPlugin extends Plugin {

    private HttpLocalServer localServer;

    @PluginMethod
    public void connect(PluginCall call) {
        if (localServer == null) {
            localServer = new HttpLocalServer(this);
        }
        localServer.connect(call);
    }

    // Add this method:
    public void fireOnRequest(JSObject req) {
        notifyListeners("onRequest", req, true);
    }

    @PluginMethod
    public void disconnect(PluginCall call) {
        if (localServer != null) {
            localServer.disconnect(call);
        } else {
            call.resolve();
        }
    }

    @PluginMethod
    public void sendResponse(PluginCall call) {
        String requestId = call.getString("requestId");
        String body = call.getString("body");
        if (requestId == null || body == null) {
            call.reject("Missing requestId or body");
            return;
        }
        HttpLocalServer.handleJsResponse(requestId, body);
        call.resolve();
    }
}
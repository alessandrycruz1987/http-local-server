package com.cappitolian.plugins.httplocalserver;

import com.getcapacitor.Logger;

public class HttpLocalServer {

    public String echo(String value) {
        Logger.info("Echo", value);
        return value;
    }
}

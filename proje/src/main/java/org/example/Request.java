package org.example;

import com.google.gson.JsonObject;

public class Request {
    private String type;
    private JsonObject payload;
    private String requestId;

    public Request() {}

    public Request(String type, JsonObject payload, String requestId) {
        this.type = type;
        this.payload = payload;
        this.requestId = requestId;
    }

    public String getType() {
        return type;
    }

    public JsonObject getPayload() {
        return payload;
    }

    public String getRequestId() {
        return requestId;
    }

    @Override
    public String toString() {
        return "Request{" +
                "type='" + type + '\'' +
                ", payload=" + payload +
                ", requestId='" + requestId + '\'' +
                '}';
    }
}
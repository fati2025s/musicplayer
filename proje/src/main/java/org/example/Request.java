package org.example;

import com.google.gson.JsonObject;

public class Request {
    private String type;
    private JsonObject payload;

    public Request() {}

    public Request(String type, JsonObject payload) {
        this.type = type;
        this.payload = payload;
    }

    public String getType() {
        return type;
    }

    public JsonObject getPayload() {
        return payload;
    }

    @Override
    public String toString() {
        return "Request{" +
                "type='" + type + '\'' +
                ", payload=" + payload +
                '}';
    }
}

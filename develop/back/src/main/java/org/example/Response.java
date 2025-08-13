package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

public class Response {
    private String success;
    private String message;
    private JsonObject data;
    private String requestId;

    public Response(String success, String message) {
        this.success = success;
        this.message = message;
        this.data = new JsonObject();
    }

    public Response(String success, String message, JsonObject data) {
        this.success = success;
        this.message = message;
        this.data = data;
    }

    public Response(String success, String message, JsonObject data, String requestId) {
        this.success = success;
        this.message = message;
        this.data = data;
        this.requestId = requestId;
    }

    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public String getRequestId() {
        return requestId;
    }

    public JsonObject getData() {
        return data;
    }

    public String toJson() {
        return new Gson().toJson(this);
    }
}

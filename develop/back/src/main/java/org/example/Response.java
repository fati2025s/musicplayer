package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

public class Response {
    private String status;       // success | error
    private String message;
    private JsonObject data;
    private String requestId;

    public Response(String status, String message) {
        this.status = status;
        this.message = message;
        this.data = new JsonObject();
    }

    public Response(String status, String message, JsonObject data) {
        this.status = status;
        this.message = message;
        this.data = data != null ? data : new JsonObject();
    }

    public Response(String status, String message, JsonObject data, String requestId) {
        this.status = status;
        this.message = message;
        this.data = data != null ? data : new JsonObject();
        this.requestId = requestId;
    }

    public String getStatus() {
        return status;
    }

    public String getMessage() {
        return message;
    }

    public JsonObject getData() {
        return data;
    }

    public void setData(JsonObject data) {
        this.data = data;
    }

    public String getRequestId() {
        return requestId;
    }

    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public String toJson() {
        return new Gson().toJson(this);
    }
}

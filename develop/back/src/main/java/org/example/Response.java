package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

public class Response {
    private String status;
    private String message;
    private JsonObject data;
    private String requestId;

    public Response(String status, String message) {
        this(status, message, new JsonObject(), null);
    }

    public Response(String status, String message, JsonObject data) {
        this(status, message, data, null);
    }

    public Response(String status, String message, JsonObject data, String requestId) {
        this.status = status;
        this.message = message;
        this.data = (data != null) ? data : new JsonObject();
        this.requestId = requestId;
    }

    public static Response success(String message) {
        return new Response("success", message);
    }

    public static Response success(String message, JsonObject data) {
        return new Response("success", message, data);
    }

    public static Response error(String message) {
        return new Response("error", message);
    }

    public static Response error(String message, JsonObject data) {
        return new Response("error", message, data);
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
        this.data = (data != null) ? data : new JsonObject();
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

    @Override
    public String toString() {
        return "Response{" +
                "status='" + status + '\'' +
                ", message='" + message + '\'' +
                ", data=" + data +
                ", requestId='" + requestId + '\'' +
                '}';
    }
}

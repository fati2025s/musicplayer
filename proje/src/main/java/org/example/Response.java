package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

public class Response {
    private String success;
    private String message;
    private JsonObject data;

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

    public String toJson() {
        return new Gson().toJson(this);
    }
}

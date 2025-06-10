package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.io.*;
import java.net.Socket;
import java.util.function.DoubleToIntFunction;

public class ClientHandler extends Thread {
    private final Socket socket;
    private final Gson json = new Gson();

    private final static Contoroller handler = new Contoroller();

    public ClientHandler(Socket socket) {
        this.socket = socket;
    }

    @Override
    public void run() {
        try (
                BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()))
        ) {
            String requestLine;
            while ((requestLine = reader.readLine()) != null) {
                System.out.println("Received from client: " + requestLine);
                Request request = json.fromJson(requestLine, Request.class);
                Response response = handleRequest(request);
                writer.write(json.toJson(response));
                writer.newLine();
                writer.flush();
            }


        } catch (IOException e) {
            System.out.println("kjddc");
            e.printStackTrace();
        }
    }

    private Response handleRequest(Request req) {
        //System.out.println("eshah");
        switch (req.getType()) {
            case "register":
                handler.register(req.getPayload());
                break;
            case "login":
                handler.login(req.getPayload());
                break;
            case "deletesong":
                handler.deleteSong(req.getPayload());
                break;
            case "getsong":
                handler.getSong(req.getPayload());
                break;
            case "getsongs":
                handler.getSongs(req.getPayload());
                break;
            case "addPlaylist":
                handler.addPlaylist(req.getPayload());
                break;
            case "deletePlaylist":
                handler.deletePlaylist(req.getPayload());
                break;
            case "getplaylist":
                handler.getPlaylist(req.getPayload());
                break;
            case "getplaylists":
                handler.getPlaylists(req.getPayload());
                break;

                default:
                return new Response("error", "try another request");
        }
        return new Response("success", "Done");
    }
}

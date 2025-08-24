package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.io.*;
import java.net.Socket;
import java.util.HashMap;
import java.util.Map;
import java.util.function.DoubleToIntFunction;

public class ClientHandler extends Thread {
    private final Socket socket;
    private final Gson json = new Gson();
    static Map<Socket, User> sessions = new HashMap<>();

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
                System.out.println(json.toJson(response));
                writer.write(json.toJson(response)+"end\n");
                writer.flush();
            }


        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private Response handleRequest(Request req) {
        System.out.println("Parsed type: " + req.getType());
        //System.out.println("Payload: " + req.getPayload());

        switch (req.getType()) {

            case "register":
                boolean result = handler.register(req.getPayload());
                if (result) {
                    sessions.put(socket,json.fromJson(req.getPayload(),User.class));
                    return new Response("success", "user registered");
                }
                return new Response("error", "user already exists");
            case "login":
                boolean nati=handler.login(req.getPayload());
                if (nati){
                    sessions.put(socket,json.fromJson(req.getPayload(),User.class));
                    return new Response("success", "user logged in");
                }
                return new Response("error", "user not logged in");
            case "changePassword":
                User user0 = sessions.get(socket);
                boolean resu = handler.changePassword(user0,req.getPayload());
                if (resu)
                    return new Response("success", "user password changed");
                return new Response("error", "can't change password");
            case "changeUsername":
                User user12 = sessions.get(socket);
                boolean esu = handler.changeUsername(user12,req.getPayload());
                if (esu)
                    return new Response("success", "user password changed");
                return new Response("error", "can't change password");
            case "deleteUser":
                User user = sessions.get(socket);
                handler.deleteUser(user,req.getPayload());
                return new Response("success", "user deleted");
            case "deletesong":
                boolean result1 = handler.deleteSong(sessions.get(socket),req.getPayload());
                if (result1)
                    return new Response("success", "music deleted");
                return new Response("error", "can't delete music");
            case "addsong":
                if (sessions.get(socket) == null) {
                    return new Response("error", "not logged in");
                }
                boolean nati1=handler.addSong(sessions.get(socket),req.getPayload());
                if(nati1)
                    return new Response("success", "song added");
                return new Response("error", "song not added");
            case "addlikesong":
                if (sessions.get(socket) == null) {
                    return new Response("error", "not logged in");
                }
                boolean nati2=handler.addlikesong(sessions.get(socket),req.getPayload());
                if(nati2)
                    return new Response("success", "song liked");
                return new Response("error", "song not liked");
            case "deletlikesong":
                if (sessions.get(socket) == null) {
                    return new Response("error", "not logged in");
                }
                boolean nati3=handler.deletlikesong(sessions.get(socket),req.getPayload());
                if(nati3)
                    return new Response("success", "song disliked");
                return new Response("error", "song not disliked");
            /*case "getsong":
                User loggedInUser1 = sessions.get(socket);
                if (loggedInUser1 == null) {
                    return new Response("error", "not logged in");
                }
                if(handler.getSong(loggedInUser1,req.getPayload())==null)
                    return new Response("error", "song not found");
                return new Response("success", "song found");*/
            /*case "getsongsname":
                User loggedInUser2 = sessions.get(socket);
                if (loggedInUser2 == null) {
                    return new Response("error", "not logged in");
                }
                if(handler.getSongsname(loggedInUser2,req.getPayload()) == null)
                    return new Response("error", "songs not found");
                return new Response("success", "songs found");
            case "getsongs":
                User loggedInUser5 = sessions.get(socket);
                if (loggedInUser5 == null) {
                    return new Response("error", "not logged in");
                }
                if(handler.getSongs(loggedInUser5,req.getPayload()) == null)
                    return new Response("error", "songs not found");
                return new Response("success", "songs found");
            case "getsongsartist":
                User loggedInUser3 = sessions.get(socket);
                if (loggedInUser3 == null) {
                    return new Response("error", "not logged in");
                }
                if(handler.getSongsartist(loggedInUser3,req.getPayload()) == null)
                    return new Response("error", "songs not found");
                return new Response("success", "songs found");
            case "getsongstedad":
                User loggedInUser4 = sessions.get(socket);
                if (loggedInUser4 == null) {
                    return new Response("error", "not logged in");
                }
                if(handler.getSongstedad(loggedInUser4,req.getPayload()) == null)
                    return new Response("error", "songs not found");
                return new Response("success", "songs found");*/
            case "addPlaylist":
                boolean nati5 = handler.addPlaylist(sessions.get(socket),req.getPayload());
                if(nati5)
                    return new Response("success", "playlist added");
                return new Response("error", "playlist not added");
            case "deletePlaylist":
                boolean nati8 = handler.deletePlaylist(sessions.get(socket),req.getPayload());
                if(nati8)
                    return new Response("success", "playlist deleted");
                return new Response("error", "playlist not deleted");
            /*case "getplaylist":
                handler.getPlaylist(req.getPayload());
            case "getplaylists":
                handler.getPlaylists(req.getPayload());*/
            default:
                return new Response("error", "try another request");
        }
        //return new Response("success", "Done");
    }
}
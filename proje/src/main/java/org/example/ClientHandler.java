package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.io.*;
import java.net.Socket;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.util.Base64;
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

    private static String saveBase64File(String base64, String dirPath, String fileName) throws IOException {
        byte[] data = Base64.getDecoder().decode(base64);
        File dir = new File(dirPath);
        if (!dir.exists()) dir.mkdirs();
        File out = new File(dir, fileName);
        Files.write(out.toPath(), data, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
        // مسیر نسبی برای ذخیره در دیتابیس
        return out.getPath();
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
                    JsonObject obj = new JsonObject();
                    obj.add("user", json.toJsonTree(json.fromJson(req.getPayload(),User.class)));
                    return new Response("success", "user registered",obj);
                }
                return new Response("error", "user already exists");
            case "login":
                boolean nati = handler.login(req.getPayload());
                if (nati) {
                    String username = req.getPayload().get("username").getAsString();
                    User dbUser = handler.databass.findUserByUsername(username);
                    sessions.put(socket, dbUser);
                    JsonObject obj = new JsonObject();
                    obj.add("user", json.toJsonTree(dbUser));
                    return new Response("success", "user logged in", obj);
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
                sessions.remove(socket);
                return new Response("success", "user deleted");
            case "logout":
                sessions.remove(socket);
                return new Response("success", "user logout");
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
            case "toggleLikeMusic":
                boolean liked = handler.toggleLikeMusic(sessions.get(socket), req.getPayload());
                if (liked) {
                    User dbUser = handler.databass.findUserByUsername(sessions.get(socket).getUsername());
                    sessions.put(socket, dbUser);

                    Map<String, Object> data = new HashMap<>();
                    data.put("likedSongs", dbUser.getLikedSongs());

                    return new Response("success", "music like updated", data);
                }
                return new Response("error", "failed to update like");
            case "addPlaylist":
                boolean nati5 = handler.addPlaylist(sessions.get(socket), req.getPayload());
                if (nati5) {
                    User dbUser = handler.databass.findUserByUsername(sessions.get(socket).getUsername());
                    sessions.put(socket, dbUser); // مهم! آپدیت سشن از دیتابیس
                    Map<String, Object> data = new HashMap<>();
                    data.put("playlists", dbUser.getPlaylists());

                    return new Response("success", "playlist added", data);
                }
                return new Response("error", "playlist not added");

            case "deletePlaylist":
                boolean nati8 = handler.deletePlaylist(sessions.get(socket), req.getPayload());
                if (nati8) {
                    User dbUser = handler.databass.findUserByUsername(sessions.get(socket).getUsername());
                    sessions.put(socket, dbUser);

                    Map<String, Object> data = new HashMap<>();
                    data.put("playlists", dbUser.getPlaylists());

                    return new Response("success", "playlist deleted", data);
                }
                return new Response("error", "playlist not deleted");

            case "uploadProfileImage": {
                User cur = sessions.get(socket);
                if (cur == null) return new Response("error", "not logged in");
                String fileName = req.getPayload().get("fileName").getAsString();
                String base64 = req.getPayload().get("base64Data").getAsString();

                try {
                    String relativePath = saveBase64File(
                            base64,
                            "uploads/profile/" + cur.getUsername(),
                            fileName
                    );
                    Map<String, Object> data = new HashMap<>();
                    data.put("path", relativePath);

                    /*JsonObject payload = new JsonObject();
                    payload.addProperty("path", relativePath);

                    boolean bool = handler.addProfile(sessions.get(socket),payload);
                    if(!bool)
                        return new Response("error", "path dont sabt",data);*/
                    return new Response("success", "profile image uploaded", data);
                } catch (IOException e) {
                    e.printStackTrace();
                    return new Response("error", "failed to save profile image");
                }
            }

            case "addProfileImage": {
                User cur = sessions.get(socket);
                if (cur == null) return new Response("error", "not logged in");
                boolean ok = handler.addProfile(cur, req.getPayload());
                if (ok) {
                    User dbUser = handler.databass.findUserByUsername(cur.getUsername());
                    sessions.put(socket, dbUser);
                    Map<String, Object> data = new HashMap<>();
                    data.put("profileImages", dbUser.getProfilePicturePath());
                    data.put("currentProfileIndex", dbUser.getCurrentProfileIndex());
                    return new Response("success", "profile image added", data);
                }
                return new Response("error", "failed to add profile image");
            }

            case "removeProfileImage": {
                User cur = sessions.get(socket);
                if (cur == null) return new Response("error", "not logged in");
                boolean ok = handler.removeProfile(cur, req.getPayload());
                if (ok) {
                    User dbUser = handler.databass.findUserByUsername(cur.getUsername());
                    sessions.put(socket, dbUser);
                    Map<String, Object> data = new HashMap<>();
                    data.put("profileImages", dbUser.getProfilePicturePath());
                    data.put("currentProfileIndex", dbUser.getCurrentProfileIndex());
                    return new Response("success", "profile image removed", data);
                }
                return new Response("error", "failed to remove profile image");
            }

            case "setCurrentProfileImage": {
                User cur = sessions.get(socket);
                if (cur == null) return new Response("error", "not logged in");
                boolean ok = handler.setCurrentProfile(cur, req.getPayload());
                if (ok) {
                    User dbUser = handler.databass.findUserByUsername(cur.getUsername());
                    sessions.put(socket, dbUser);
                    Map<String, Object> data = new HashMap<>();
                    data.put("currentProfileIndex", dbUser.getCurrentProfileIndex());
                    return new Response("success", "current profile image set", data);
                }
                return new Response("error", "failed to set current profile image");
            }
            default:
                return new Response("error", "try another request");
        }
    }
}
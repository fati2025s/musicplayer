package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

import java.io.*;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

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
                System.out.println(" Received: " + requestLine);

                Request request = json.fromJson(requestLine, Request.class);
                Response response = handleRequest(request);

                if (request.getRequestId() != null) {
                    response.setRequestId(request.getRequestId());
                }

                String jsonResponse = json.toJson(response);
                System.out.println(" Sending: " + jsonResponse);

                writer.write(jsonResponse + "\n");
                writer.flush();
            }
        } catch (IOException e) {
            System.out.println(" Client disconnected");
        }
    }

    private Response handleRequest(Request req) {
        System.out.println("🔎 Parsed type: " + req.getType());

        switch (req.getType()) {
            case "register":
                boolean reg = handler.register(req.getPayload());
                if (reg) {
                    sessions.put(socket, json.fromJson(req.getPayload(), User.class));
                    return new Response("success", "user registered");
                }
                return new Response("error", "user already exists");

            case "login":
                boolean loggedIn = handler.login(req.getPayload());
                if (loggedIn) {
                    sessions.put(socket, json.fromJson(req.getPayload(), User.class));
                    return new Response("success", "user logged in");
                }
                return new Response("error", "invalid login");

            case "changePassword":
                User user0 = sessions.get(socket);
                if (user0 == null) return new Response("error", "not logged in");
                boolean passChanged = handler.changePassword(user0, req.getPayload());
                return passChanged
                        ? new Response("success", "password changed")
                        : new Response("error", "can't change password");

            case "addPlaylist":
                boolean added = handler.addPlaylist(sessions.get(socket), req.getPayload());
                return added
                        ? new Response("success", "playlist added")
                        : new Response("error", "playlist not added");

            case "deletePlaylist":
                boolean deleted = handler.deletePlaylist(sessions.get(socket), req.getPayload());
                return deleted
                        ? new Response("success", "playlist deleted")
                        : new Response("error", "playlist not deleted");
            case "sharePlaylist": {
    User sender = sessions.get(socket);
    if (sender == null) return new Response("error", "not logged in");

    
    String targetUserId = req.getPayload().get("targetUserId").getAsString();
    int playlistId = req.getPayload().get("playlistId").getAsInt();

    
    User targetUser = handler.databass.findUserById(targetUserId);
    if (targetUser == null) {
        return new Response("error", "target user not found");
    }

    
    if (!targetUser.canReceiveShares()) {
        return new Response("error", "user does not accept shared playlists");
    }

    PlayList playlistToShare = null;
    for (PlayList p : sender.getPlaylists()) {
        if (p.getId() == playlistId) {
            playlistToShare = p;
            break;
        }
    }
    if (playlistToShare == null) {
        return new Response("error", "playlist not found");
    }

    PlayList copied = new PlayList(
            playlistToShare.getId(),
            playlistToShare.getName(),
            targetUser
    );
    copied.setSongs(new ArrayList<>(playlistToShare.getMusics()));

    targetUser.addPlaylist(copied);

    handler.databass.write(handler.databass.users);

    return new Response("success", "playlist shared successfully");
}


            //case "getplaylist":
              //  return handler.getPlaylist(req.getPayload());

            case "addsong":
                User u = sessions.get(socket);
                if (u == null) return new Response("error", "not logged in");
                boolean songAdded = handler.addSong(u, req.getPayload());
                return songAdded
                        ? new Response("success", "song added")
                        : new Response("error", "song not added");

            case "deletesong":
                User u2 = sessions.get(socket);
                if (u2 == null) return new Response("error", "not logged in");
                boolean songDeleted = handler.deleteSong(u2, req.getPayload());
                return songDeleted
                        ? new Response("success", "song deleted")
                        : new Response("error", "song not deleted");

            case "getsong":
                User u3 = sessions.get(socket);
                if (u3 == null) return new Response("error", "not logged in");
                if (handler.getSong(u3, req.getPayload()) == null)
                    return new Response("error", "song not found");
                return new Response("success", "song found");

            case "uploadSongFile": {
                User currentUser = sessions.get(socket);
                if (currentUser == null) {
                    return new Response("error", "not logged in");
                }
                try {
                    String base64Data = req.getPayload().get("base64Data").getAsString();
                    String fileName = req.getPayload().get("fileName").getAsString();
                    JsonObject meta = req.getPayload().has("meta")
                            ? req.getPayload().getAsJsonObject("meta")
                            : null;

                    byte[] fileBytes = Base64.getDecoder().decode(base64Data);

                    String safeFileName = System.currentTimeMillis() + "_" + fileName;
                    File userDir = new File("uploads" + File.separator + currentUser.getUsername());
                    if (!userDir.exists()) userDir.mkdirs();

                    File outputFile = new File(userDir, safeFileName);
                    try (FileOutputStream fos = new FileOutputStream(outputFile)) {
                        fos.write(fileBytes);
                    }

                    Song newSong = new Song();
                    newSong.setId((int) (System.currentTimeMillis() % Integer.MAX_VALUE));
                    newSong.setName(meta != null && meta.has("title") ? meta.get("title").getAsString() : fileName);
                    newSong.setArtist(new Artist(meta != null && meta.has("artist") ? meta.get("artist").getAsString() : "Unknown"));
                    newSong.setFilePath(outputFile.getAbsolutePath());
                    newSong.setSource("uploaded");

                    Databass db = handler.databass;
                    if (currentUser.getSongs() == null) currentUser.setSongs(new ArrayList<>());
                    currentUser.getSongs().add(newSong);
                    db.write(db.users);

                    JsonObject fileData = new Gson().toJsonTree(newSong).getAsJsonObject();
                    return new Response("success", "file uploaded and linked to user", fileData);
                } catch (Exception e) {
                    e.printStackTrace();
                    return new Response("error", "file upload failed");
                }
            }

            default:
                return new Response("error", "unknown request type");
        }
    }
}



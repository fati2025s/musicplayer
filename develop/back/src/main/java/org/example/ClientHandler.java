package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.io.*;
import java.net.Socket;
import java.util.ArrayList;
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
    System.out.println("hi");
    System.out.println("Received from client: " + requestLine);

    Request request = json.fromJson(requestLine, Request.class);
    Response response = handleRequest(request);
    
    if (request.getRequestId() != null) {
    response.setRequestId(request.getRequestId());
}

    if (request.getRequestId() != null) {
        response.getData().addProperty("requestId", request.getRequestId());
    }

    String jsonResponse = json.toJson(response);
    System.out.println(jsonResponse);
    writer.write(jsonResponse + "end\n");
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
            case "getsong":
                User loggedInUser1 = sessions.get(socket);
                if (loggedInUser1 == null) {
                    return new Response("error", "not logged in");
                }
                if(handler.getSong(loggedInUser1,req.getPayload())==null)
                    return new Response("error", "song not found");
                return new Response("success", "song found");
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
                boolean nati2 = handler.addPlaylist(sessions.get(socket),req.getPayload());
                if(nati2)
                    return new Response("success", "playlist added");
                return new Response("error", "playlist not added");
            case "deletePlaylist":
                boolean nati3 = handler.deletePlaylist(sessions.get(socket),req.getPayload());
                if(nati3)
                    return new Response("success", "playlist deleted");
                return new Response("error", "playlist not deleted");
            case "getplaylist":
                handler.getPlaylist(req.getPayload());
            case "getplaylists":
                handler.getPlaylists(req.getPayload());
                case "uploadSongFile": {
    User currentUser = sessions.get(socket);
    if (currentUser == null) {
        return new Response("error", "not logged in");
    }

    try {
        String base64Data = req.getPayload().get("base64Data").getAsString();
        String fileName = req.getPayload().get("fileName").getAsString();
        JsonObject meta = null;
        if (req.getPayload().has("meta")) {
            meta = req.getPayload().getAsJsonObject("meta");
        }

        byte[] fileBytes = java.util.Base64.getDecoder().decode(base64Data);

        String safeFileName = System.currentTimeMillis() + "_" + fileName;

        File userDir = new File("uploads" + File.separator + currentUser.getUsername());
        if (!userDir.exists()) userDir.mkdirs();

        File outputFile = new File(userDir, safeFileName);
        try (FileOutputStream fos = new FileOutputStream(outputFile)) {
            fos.write(fileBytes);
        }

       Song newSong = new Song();
newSong.setId((int) (System.currentTimeMillis() % Integer.MAX_VALUE));
newSong.setName(meta != null && meta.has("title") && meta.get("title") != null 
        ? meta.get("title").getAsString() 
        : fileName);
newSong.setArtist(new Artist(meta != null && meta.has("artist") && meta.get("artist") != null 
        ? meta.get("artist").getAsString() 
        : "Unknown"));
newSong.setFilePath(outputFile != null ? outputFile.getAbsolutePath() : "");
newSong.setSource("uploaded");


        Databass db = handler.databass;
        if (currentUser.getSongs() == null) currentUser.setSongs(new ArrayList<>());
        currentUser.getSongs().add(newSong);
        db.write(db.users);

        JsonObject fileData = new Gson().toJsonTree(newSong).getAsJsonObject();
        return new Response("success", "file uploaded and linked to user", fileData);

    } catch (IllegalArgumentException | IOException e) {
        e.printStackTrace();
        return new Response("error", "file upload failed");
    }
}


            default:
                return new Response("error", "try another request");
        }
        //return new Response("success", "Done");
    }
}

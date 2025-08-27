package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.io.*;
import java.net.Socket;
import java.util.*;

public class ClientHandler implements Runnable {
    private final Socket socket;
    private final Gson gson = new Gson();

    private static final Controller controller = new Controller();
    private static final int CHUNK_SIZE = 64 * 1024;

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
        Request request = gson.fromJson(requestLine, Request.class);

        if ("uploadSongFile".equals(request.getType())) {
            System.out.println("Received: uploadSongFile (base64 skipped)");
        } else {
            System.out.println("Received: " + requestLine);
        }

        Response response = handleRequest(request, writer);

        if (request.getRequestId() != null && response != null) {
            response.setRequestId(request.getRequestId());
        }

        if (response != null) {
            String jsonResponse = gson.toJson(response);

            if ("uploadSongFile".equals(request.getType())) {
                System.out.println("Response: " + response.getStatus() + " - " + response.getMessage());
            } else {
                System.out.println("Sending: " + jsonResponse);
            }

            try {
                writer.write(jsonResponse + "\n");
                writer.flush();
            } catch (IOException e) {
                System.err.println("Failed to send response: " + e.getMessage());
                break;
            }
        }
    }
} catch (IOException e) {
    System.out.println("Client disconnected: " + socket);
    }
}


    private Response handleRequest(Request req, BufferedWriter writer) {
         String type = req.getType();
    JsonObject payload = req.getPayload();

   User currentUser = null;
if (!"register".equals(type) && !"login".equals(type)) {
    currentUser = authenticate(payload);

    if (currentUser == null) {
        System.out.println("[AUTH] Authentication failed, falling back to guest user.");
        currentUser = controller.database.findUserByUsername("guest");

        if (currentUser == null) {
            System.out.println("Don't worry about Auth.it is doing it's job");
            currentUser = new User(
                "guest-id",
                "guest",
                "guest@example.com",
                "nopass"
            );
            controller.database.addUser(currentUser);
        }
        
    }
}


        switch (type) {
            case "register":
                return handleRegister(payload);
            case "login":
                return handleLogin(payload);
            case "logout":
                return handleLogout(currentUser);

            case "changePassword": {
                boolean changed = controller.changePassword(currentUser, payload);
                return new Response(changed ? "success" : "error",
                        changed ? "password changed" : "password not changed");
            }
            case "changeUserInfo":
                return handleChangeUserInfo(currentUser, payload);
                case "listLikedSongs": {
    JsonArray arr = controller.listLikedSongs(currentUser);
    JsonObject data = new JsonObject();
    data.add("songs", arr);

    return Response.success("liked songs fetched", data);
}


                

            case "addPlaylist": {
                boolean created = controller.addPlaylist(currentUser, payload);
                return new Response(created ? "success" : "error",
                        created ? "playlist added" : "playlist already exists");
            }
            case "deletePlaylist": {
                boolean deleted = controller.deletePlaylist(currentUser, payload);
                return new Response(deleted ? "success" : "error",
                        deleted ? "playlist deleted" : "playlist not found or not owner");
            }
            case "renamePlaylist":
                return handleRenamePlaylist(currentUser, payload);
            case "sharePlaylist":
                return handleSharePlaylist(currentUser, payload);
                case "deleteAccount":
                return handleDeleteAccount(currentUser);


            case "addSong": {
    boolean added = controller.addSongAsGuest(payload);
    if (added && currentUser != null && !"guest".equals(currentUser.getUsername())) {

        int lastSongId = controller.getLastGeneratedSongId();
        controller.markSongAddedByUser(currentUser, lastSongId);
    }
    return new Response(
        added ? "success" : "error",
        "add song"
    );
}

            case "deleteSong": {
                boolean deleted = controller.deleteSong(currentUser, payload);
                return new Response(deleted ? "success" : "error",
                        deleted ? "song deleted" : "song not found");
            }
            case "uploadSongFile":
                return handleUploadSongFile(currentUser, payload);
            case "downloadSong":
    return handleFileDownload(writer, currentUser, payload);


 case "listSongsAddedByMe":
    return new Response("success", "songs added by me", 
            wrapArray("songs", controller.listSongsAddedByMe(currentUser)));


            case "listSongs":
                return new Response("success", "songs listed", wrapArray("songs", controller.listSongs(currentUser)));
            case "listPlaylists":
                return new Response("success", "playlists listed", wrapArray("playlists", controller.listPlaylists(currentUser)));

                case "toggleLikeSong": {
    int songId = payload.get("songId").getAsInt();
    boolean nowLiked = controller.toggleLike(currentUser, songId);
    return new Response("success", nowLiked ? "liked" : "unliked");
}

        default:
            return new Response("error", "unknown request type: " + type);}
}


    private Response handleLogout(User user) {
        return controller.logout(user) ? new Response("success", "user logged out") : new Response("error", "logout failed");
    }

    private Response handleChangeUserInfo(User user, JsonObject payload) {
        return controller.changeUserInfo(user, payload)
                ? new Response("success", "user info updated")
                : new Response("error", "update failed");
    }

    private Response handleFileDownload(BufferedWriter writer, User currentUser, JsonObject payload) {
    int songId = payload.get("songId").getAsInt();
   User guest = controller.database.findUserByUsername("guest");
    Song s = controller.findSongById(guest, songId);

    if (s == null || s.getFilePath() == null)
        return new Response("error", "song not found");

    File f = new File(s.getFilePath());
    if (!f.exists()) return new Response("error", "file missing on server");

    try {
        sendFileInChunks(writer, f, "download");
        return new Response("success", "download started");
    } catch (IOException e) {
        e.printStackTrace();
        return new Response("error", "download failed");
    }
}


    private Response handleRenamePlaylist(User user, JsonObject payload) {
        return controller.renamePlaylist(user, payload)
                ? new Response("success", "playlist renamed")
                : new Response("error", "rename failed");
    }

    private Response handleSharePlaylist(User user, JsonObject payload) {
        return controller.sharePlaylist(user, payload)
                ? new Response("success", "playlist shared")
                : new Response("error", "share failed");
    }

    private Response handleCheckSharePermission(User user, JsonObject payload) {
        boolean allowed = controller.checkSharePermission(user, payload);
        return new Response("success", allowed ? "share allowed" : "share denied");
    }


    private Response handleRegister(JsonObject payload) {
        boolean registered = controller.register(payload);
        if (registered) {
            JsonObject data = new JsonObject();
            data.addProperty("username", payload.get("username").getAsString());
            return new Response("success", "user registered", data);
        }
        return new Response("error", "user already exists");
    }

    private Response handleLogin(JsonObject payload) {
        User loggedIn = controller.login(payload);
        if (loggedIn != null) {
            JsonObject data = new JsonObject();
            data.addProperty("username", loggedIn.getUsername());
            return new Response("success", "user authenticated", data);
        }
        return new Response("error", "invalid login");
    }

    private Response handleUploadSongFile(User currentUser, JsonObject payload) {
        try {
            String base64Data = payload.get("base64Data").getAsString();
            String fileName = payload.get("fileName").getAsString();
            JsonObject meta = payload.has("meta") ? payload.getAsJsonObject("meta") : null;

            byte[] fileBytes = Base64.getDecoder().decode(base64Data);

            String safeFileName = System.currentTimeMillis() + "_" + fileName;
            File userDir = new File(Database.UPLOADS_ROOT + File.separator + currentUser.getUsername());
            if (!userDir.exists()) userDir.mkdirs();

            File outputFile = new File(userDir, safeFileName);
            try (FileOutputStream fos = new FileOutputStream(outputFile)) {
                fos.write(fileBytes);
            }

            Song newSong = new Song();
            newSong.setId(Database.songIdGenerator.incrementAndGet());
            newSong.setName(meta != null && meta.has("title") ? meta.get("title").getAsString() : fileName);
            newSong.setArtist(new Artist(meta != null && meta.has("artist") ? meta.get("artist").getAsString() : "Unknown"));
            newSong.setFilePath(outputFile.getAbsolutePath());
            newSong.setSource("uploaded");

            controller.database.addSong(currentUser, newSong);
            controller.markSongAddedByUser(currentUser, newSong.getId());


            JsonObject fileData = gson.toJsonTree(newSong).getAsJsonObject();
            return new Response("success", "file uploaded and linked to user", fileData);
        } catch (Exception e) {
            e.printStackTrace();
            return new Response("error", "file upload failed");
        }
    }

    User authenticate(JsonObject payload) {
        if (!payload.has("username") || !payload.has("password")) return null;
        String username = payload.get("username").getAsString();
        String password = payload.get("password").getAsString();
        User u = controller.database.findUserByUsername(username);
        return (u != null && u.getPassword().equals(password)) ? u : null;
    }

    private Response handleDeleteAccount(User user) {
    if (user == null || "guest".equals(user.getUsername())) {
        return new Response("error", "cannot delete guest or null user");
    }

    boolean deleted = controller.deleteAccount(user);
    return new Response(
        deleted ? "success" : "error",
        deleted ? "account deleted" : "delete failed"
    );
}


    private JsonObject wrapArray(String key, JsonArray arr) {
        JsonObject o = new JsonObject();
        o.add(key, arr);
        return o;
    }

    private void sendFileInChunks(BufferedWriter writer, File file, String mode) throws IOException {
        long fileSize = file.length();
        String fileName = file.getName();

        Response start = new Response("success", mode + "_start");
        JsonObject startData = new JsonObject();
        startData.addProperty("fileName", fileName);
        startData.addProperty("fileSize", fileSize);
        startData.addProperty("chunkSize", CHUNK_SIZE);
        start.setData(startData);
        writer.write(gson.toJson(start) + "\n");
        writer.flush();

        try (InputStream in = new BufferedInputStream(new FileInputStream(file))) {
            byte[] buffer = new byte[CHUNK_SIZE];
            int read;
            int index = 0;
            while ((read = in.read(buffer)) != -1) {
                String b64 = Base64.getEncoder().encodeToString(Arrays.copyOf(buffer, read));
                Response chunk = new Response("success", mode + "_chunk");
                JsonObject d = new JsonObject();
                d.addProperty("index", index++);
                d.addProperty("base64", b64);
                chunk.setData(d);
                writer.write(gson.toJson(chunk) + "\n");
                writer.flush();
            }
        }

        Response done = new Response("success", mode + "_complete");
        writer.write(gson.toJson(done) + "\n");
        writer.flush();
    }
}

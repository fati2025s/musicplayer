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
                Request request;
                try {
                    request = gson.fromJson(requestLine, Request.class);
                } catch (Exception e) {
                    System.out.println("Invalid request JSON: " + requestLine);
                    sendRawError(writer, null, "invalid_json", "Could not parse request");
                    continue;
                }

                if ("uploadSongFile".equals(request.getType())) {
                    System.out.println("Received: uploadSongFile (base64 skipped)");
                } else {
                    System.out.println("Received: " + requestLine);
                }

                JsonObject payload = request.getPayload();
                User currentUser = null;

                if (!"register".equals(request.getType()) && !"login".equals(request.getType())) {
                    currentUser = authenticate(payload);
                    if (currentUser == null) {
                        System.out.println("[AUTH] Authentication failed or not provided — using guest user.");
                        currentUser = controller.database.findUserByUsername("guest");
                        if (currentUser == null) {
                            currentUser = new User("guest-id", "guest", "guest@example.com", "nopass");
                            controller.database.addUser(currentUser);
                        }
                    }
                }

                Object handlerResult;
                try {
                    handlerResult = handleRequestObject(request, currentUser, writer);
                } catch (Exception e) {
                    e.printStackTrace();
                    sendRawError(writer, request.getRequestId(), "server_error", "Internal server error");
                    continue;
                }

                if (handlerResult instanceof JsonObject) {
                    JsonObject respObj = (JsonObject) handlerResult;
                    if (request.getRequestId() != null) {
                        respObj.addProperty("requestId", request.getRequestId());
                    }
                    String jsonResponse = gson.toJson(respObj);
                    if ("uploadSongFile".equals(request.getType())) {
                        System.out.println("Response: " + safeShorten(jsonResponse));
                    } else {
                        System.out.println("Sending: " + jsonResponse);
                    }
                    writer.write(jsonResponse + "\n");
                    writer.flush();
                }
            }
        } catch (IOException e) {
            System.out.println("Client disconnected: " + socket + " (" + e.getMessage() + ")");
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }
    
    private Object handleRequestObject(Request req, User currentUser, BufferedWriter writer) throws IOException {
        String type = req.getType();
        JsonObject payload = req.getPayload();

        switch (type) {
            case "register":
                return wrapBoolResponse(controller.register(payload), "user registered", "user already exists");

            case "login": {
                User logged = controller.login(payload);
                if (logged != null) {
                    JsonObject data = new JsonObject();
                    data.addProperty("username", logged.getUsername());
                    return buildResponse("success", "user authenticated", data);
                } else {
                    return buildResponse("error", "invalid login", null);
                }
            }

            case "logout":
                return wrapBoolResponse(controller.logout(currentUser), "user logged out", "logout failed");

            case "changePassword": {
                boolean changed = controller.changePassword(currentUser, payload);
                return wrapSimple(changed, "password changed", "password not changed");
            }

            case "changeUserInfo":
                return wrapBoolResponse(controller.changeUserInfo(currentUser, payload), "user info updated", "update failed");

            case "listLikedSongs": {
                JsonArray arr = controller.listLikedSongs(currentUser);
                JsonObject data = new JsonObject();
                data.add("songs", arr);
                return buildResponse("success", "liked songs fetched", data);
            }

            case "addPlaylist": {
                JsonObject resp = controller.addPlaylist(currentUser, payload);
                return resp;
            }

            case "deletePlaylist": {
                JsonObject resp = controller.deletePlaylist(currentUser, payload);
                return resp;
            }

            case "renamePlaylist": {
                JsonObject resp = controller.renamePlaylist(currentUser, payload);
                return resp;
            }

            case "sharePlaylist": {
                JsonObject resp = controller.sharePlaylist(currentUser, payload);
                return resp;
            }

            case "deleteAccount":
                return handleDeleteAccount(currentUser);

            case "addSong": {
                boolean added = controller.addSongAsGuest(payload);
                return wrapSimple(added, "song added", "add song failed");
            }

            case "deleteSong": {
                JsonObject resp = controller.deleteSong(currentUser, payload);
                return resp;
            }

            case "addSongToPlaylist": {
                boolean added = controller.addSongToPlaylist(currentUser, payload);
                return wrapSimple(added, "song added to playlist", "failed to add song to playlist");
            }

            case "uploadSongFile": {
                return handleUploadSongFile(currentUser, payload);
            }

            case "downloadSong": {
                return handleFileDownload(writer, currentUser, payload);
            }

            case "listSongs": {
                User guest = controller.database.findUserByUsername("guest");
                if (guest == null) {
                    guest = new User("guest-id", "guest", "guest@example.com", "nopass");
                    controller.database.addUser(guest);
                }
                JsonArray arr = controller.listSongs(guest);
                return buildResponse("success", "songs listed", wrapArray("songs", arr));
            }

            case "listPlaylists": {
                JsonArray arr = controller.listPlaylists(currentUser);
                return buildResponse("success", "playlists listed", wrapArray("playlists", arr));
            }

            case "toggleLikeSong": {
                int songId = payload.get("songId").getAsInt();
                boolean nowLiked = controller.toggleLike(currentUser, songId);
                return wrapSimple(true, nowLiked ? "liked" : "unliked", nowLiked ? "liked" : "unliked");
            }

            default:
                return buildResponse("error", "unknown request type: " + type, null);
        }
    }

    private JsonObject handleDeleteAccount(User currentUser) {
        if (currentUser == null || "guest".equals(currentUser.getUsername())) {
            return buildResponse("error", "cannot delete guest or null user", null);
        }
        boolean deleted = controller.deleteAccount(currentUser);
        return buildResponse(deleted ? "success" : "error", deleted ? "account deleted" : "delete failed", null);
    }

    private JsonObject handleUploadSongFile(User currentUser, JsonObject payload) {
        try {
            if (currentUser == null) {
                return buildResponse("error", "not authenticated", null);
            }
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

            User guest = controller.database.findUserByUsername("guest");
            if (guest == null) {
                guest = new User("guest-id", "guest", "guest@example.com", "nopass");
                controller.database.addUser(guest);
            }
            controller.database.addSong(guest, newSong);

            JsonObject fileData = gson.toJsonTree(newSong).getAsJsonObject();
            return buildResponse("success", "file uploaded and linked to user + guest", fileData);
        } catch (Exception e) {
            e.printStackTrace();
            return buildResponse("error", "file upload failed", null);
        }
    }

    private JsonObject handleFileDownload(BufferedWriter writer, User currentUser, JsonObject payload) throws IOException {
        int songId = payload.get("songId").getAsInt();
        User guest = controller.database.findUserByUsername("guest");
        if (guest == null) {
            return buildResponse("error", "guest user not found", null);
        }

        Song s = controller.findSongById(guest, songId);
        if (s == null || s.getFilePath() == null) {
            return buildResponse("error", "song not found", null);
        }

        File f = new File(s.getFilePath());
        if (!f.exists()) return buildResponse("error", "file missing on server", null);

        try {
            JsonObject startResp = new JsonObject();
            startResp.addProperty("status", "success");
            startResp.addProperty("message", "download_start");
            JsonObject d = new JsonObject();
            d.addProperty("fileName", f.getName());
            d.addProperty("fileSize", f.length());
            d.addProperty("chunkSize", CHUNK_SIZE);
            startResp.add("data", d);
            writer.write(gson.toJson(startResp) + "\n");
            writer.flush();

            sendFileInChunks(writer, f, "download_chunk", "download_complete");

            return buildResponse("success", "download started", null);
        } catch (IOException e) {
            e.printStackTrace();
            return buildResponse("error", "download failed", null);
        }
    }

    private void sendFileInChunks(BufferedWriter writer, File file, String chunkMessage, String doneMessage) throws IOException {

        try (InputStream in = new BufferedInputStream(new FileInputStream(file))) {
            byte[] buffer = new byte[CHUNK_SIZE];
            int read;
            int index = 0;
            while ((read = in.read(buffer)) != -1) {
                String b64 = Base64.getEncoder().encodeToString(Arrays.copyOf(buffer, read));
                JsonObject chunk = new JsonObject();
                chunk.addProperty("status", "success");
                chunk.addProperty("message", chunkMessage);
                JsonObject d = new JsonObject();
                d.addProperty("index", index++);
                d.addProperty("base64", b64);
                chunk.add("data", d);
                writer.write(gson.toJson(chunk) + "\n");
                writer.flush();
            }
        }

        JsonObject done = new JsonObject();
        done.addProperty("status", "success");
        done.addProperty("message", doneMessage);
        writer.write(gson.toJson(done) + "\n");
        writer.flush();
    }

    private JsonObject buildResponse(String status, String message, JsonObject data) {
        JsonObject resp = new JsonObject();
        resp.addProperty("status", status);
        resp.addProperty("message", message);
        if (data != null) resp.add("data", data);
        return resp;
    }

    private JsonObject wrapArray(String key, JsonArray arr) {
        JsonObject o = new JsonObject();
        o.add(key, arr);
        return o;
    }

    private JsonObject wrapBoolResponse(boolean ok, String okMsg, String errMsg) {
        return buildResponse(ok ? "success" : "error", ok ? okMsg : errMsg, null);
    }

    private JsonObject wrapSimple(boolean ok, String okMsg, String errMsg) {
        return buildResponse("success", ok ? okMsg : errMsg, null);
    }

    private void sendRawError(BufferedWriter writer, String requestId, String code, String message) {
        try {
            JsonObject resp = new JsonObject();
            resp.addProperty("status", "error");
            resp.addProperty("code", code);
            resp.addProperty("message", message);
            if (requestId != null) resp.addProperty("requestId", requestId);
            writer.write(gson.toJson(resp) + "\n");
            writer.flush();
        } catch (IOException e) {
        }
    }

    private String safeShorten(String s) {
        if (s == null) return "";
        if (s.length() > 200) return s.substring(0, 200) + "...";
        return s;
    }

    private User authenticate(JsonObject payload) {
        if (payload == null) return null;
        if (!payload.has("username") || !payload.has("password")) return null;
        String username = payload.get("username").getAsString();
        String password = payload.get("password").getAsString();
        User u = controller.database.findUserByUsername(username);
        return (u != null && u.getPassword().equals(password)) ? u : null;
    }
}

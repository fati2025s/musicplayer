package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

import java.io.*;
import java.net.Socket;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class ClientHandler extends Thread {
    private final Socket socket;
    private final Gson gson = new Gson();

    private static final Map<Socket, User> activeSessions = new ConcurrentHashMap<>();
    private static final Map<String, Socket> userToSocket = new ConcurrentHashMap<>();

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
                System.out.println("Received: " + requestLine);

                Request request = gson.fromJson(requestLine, Request.class);
                Response response = handleRequest(request, writer);

                if (request.getRequestId() != null && response != null) {
                    response.setRequestId(request.getRequestId());
                }

                if (response != null) {
                    String jsonResponse = gson.toJson(response);
                    System.out.println("Sending: " + jsonResponse);
                    writer.write(jsonResponse + "\n");
                    writer.flush();
                }
            }
        } catch (IOException e) {
            System.out.println("⚠ Client disconnected: " + socket);
        } finally {
            cleanupUser();
        }
    }

    private Response handleRequest(Request req, BufferedWriter writer) {
        String type = req.getType();
        JsonObject payload = req.getPayload();

        boolean requiresAuth = !"register".equals(type) && !"login".equals(type);

        User currentUser = null;
        if (requiresAuth) {
            AuthResult auth = requireSession();
            if (!auth.isOk()) return auth.getErrorResponse();
            currentUser = auth.getUser();
        }

        switch (type) {
            case "register": {
                boolean registered = controller.register(payload);
                if (registered) {
                    User tmp = gson.fromJson(payload, User.class);
                    User savedUser = controller.database.findUserByUsername(tmp.getUsername());

                    bindSession(savedUser);

                    JsonObject data = new JsonObject();
                    data.addProperty("username", savedUser.getUsername());
                    return new Response("success", "user registered & logged in", data);
                }
                return new Response("error", "user already exists");
            }

            case "login": {
                User loggedInUser = controller.login(payload);
                if (loggedInUser != null) {
                    Socket existing = userToSocket.get(loggedInUser.getUsername());
                    if (existing != null && !existing.equals(this.socket) && !existing.isClosed()) {
                        return new Response("error", "user already logged in from another device");
                    }

                    bindSession(loggedInUser);

                    JsonObject data = new JsonObject();
                    data.addProperty("username", loggedInUser.getUsername());
                    return new Response("success", "user logged in", data);
                }
                return new Response("error", "invalid login");
            }

            case "logout": {
                boolean ok = unbindSession();
                return ok ? new Response("success", "user logged out")
                          : new Response("error", "no active session");
            }

            case "changePassword": {
                boolean changed = controller.changePassword(currentUser, payload);
                return changed ? new Response("success", "password changed")
                        : new Response("error", "password not changed");
            }

            case "addPlaylist": {
                boolean added = controller.addPlaylist(currentUser, payload);
                return added ? new Response("success", "playlist added")
                        : new Response("error", "playlist already exists");
            }

            case "deletePlaylist": {
                boolean deleted = controller.deletePlaylist(currentUser, payload);
                return deleted ? new Response("success", "playlist deleted")
                        : new Response("error", "playlist not found or not owner");
            }

            case "addSong": {
                boolean added = controller.addSong(currentUser, payload);
                return added ? new Response("success", "song added")
                        : new Response("error", "song already exists");
            }

            case "deleteSong": {
                boolean deleted = controller.deleteSong(currentUser, payload);
                return deleted ? new Response("success", "song deleted")
                        : new Response("error", "song not found");
            }

            case "getSong": {
                Song song = controller.getSong(currentUser, payload);
                return song != null
                        ? new Response("success", "song found", gson.toJsonTree(song).getAsJsonObject())
                        : new Response("error", "song not found");
            }

            case "listSongs": {
                return new Response("success", "songs listed", wrapArray("songs", controller.listSongs(currentUser)));
            }

            case "streamSong":
            case "downloadSong": {
                int songId = payload.get("songId").getAsInt();
                Song s = controller.findSongById(currentUser, songId);
                if (s == null || s.getFilePath() == null)
                    return new Response("error", "song not found");

                File f = new File(s.getFilePath());
                if (!f.exists()) return new Response("error", "file missing on server");

                try {
                    sendFileInChunks(writer, f, type.equals("streamSong") ? "stream" : "download");
                    return new Response("success", type + " started");
                } catch (IOException e) {
                    e.printStackTrace();
                    return new Response("error", type + " failed");
                }
            }

            case "uploadSongFile": {
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
                    newSong.setId(Controller.songIdGenerator.incrementAndGet());
                    newSong.setName(meta != null && meta.has("title") ? meta.get("title").getAsString() : fileName);
                    newSong.setArtist(new Artist(meta != null && meta.has("artist") ? meta.get("artist").getAsString() : "Unknown"));
                    newSong.setFilePath(outputFile.getAbsolutePath());
                    newSong.setSource("uploaded");

                    controller.database.addSong(currentUser, newSong);

                    JsonObject fileData = gson.toJsonTree(newSong).getAsJsonObject();
                    return new Response("success", "file uploaded and linked to user", fileData);
                } catch (Exception e) {
                    e.printStackTrace();
                    return new Response("error", "file upload failed");
                }
            }

            default:
                return new Response("error", "unknown request type: " + type);
        }
    }

    private JsonObject wrapArray(String key, com.google.gson.JsonArray arr) {
        JsonObject o = new JsonObject();
        o.add(key, arr);
        return o;
    }

    private void sendFileInChunks(BufferedWriter writer, File file, String mode) throws IOException {
        long fileSize = file.length();
        String fileName = file.getName();
        int chunkSize = CHUNK_SIZE;

        try {
            Response start = new Response("success", mode + "_start");
            JsonObject startData = new JsonObject();
            startData.addProperty("fileName", fileName);
            startData.addProperty("fileSize", fileSize);
            startData.addProperty("chunkSize", chunkSize);
            start.setData(startData);
            writer.write(gson.toJson(start) + "\n");
            writer.flush();

            try (InputStream in = new BufferedInputStream(new FileInputStream(file))) {
                byte[] buffer = new byte[chunkSize];
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
        } catch (IOException e) {
            System.err.println("Error while sending file: " + e.getMessage());
            cleanupUser();
            throw e;
        }
    }


    private void bindSession(User user) {
        User prev = activeSessions.put(this.socket, user);
        if (prev != null && prev.getUsername() != null) {
            userToSocket.remove(prev.getUsername(), this.socket);
        }
        Socket old = userToSocket.put(user.getUsername(), this.socket);
        if (old != null && !old.equals(this.socket)) {
            try {
                old.close();
            } catch (IOException ignored) {}
        }
    }

    private boolean unbindSession() {
        User removed = activeSessions.remove(this.socket);
        if (removed != null && removed.getUsername() != null) {
            userToSocket.remove(removed.getUsername(), this.socket);
            return true;
        }
        return false;
    }

    private AuthResult requireSession() {
        User user = activeSessions.get(this.socket);
        if (user == null) {
            return AuthResult.error(new Response("error", "no active session (please login)"));
        }
        return AuthResult.ok(user);
    }

    private void cleanupUser() {
        unbindSession();
    }

    private static class AuthResult {
        private final User user;
        private final Response errorResponse;

        private AuthResult(User user, Response errorResponse) {
            this.user = user;
            this.errorResponse = errorResponse;
        }

        public static AuthResult ok(User user) {
            return new AuthResult(user, null);
        }

        public static AuthResult error(Response response) {
            return new AuthResult(null, response);
        }

        public boolean isOk() {
            return user != null;
        }

        public User getUser() {
            return user;
        }

        public Response getErrorResponse() {
            return errorResponse;
        }
    }
}

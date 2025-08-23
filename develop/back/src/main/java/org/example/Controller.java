package org.example;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

public class Controller {
    final Database database = new Database();

    public static final AtomicInteger songIdGenerator = new AtomicInteger(1000);
    public static final AtomicInteger playlistIdGenerator = new AtomicInteger(5000);


   public boolean register(JsonObject payload) {
    String username = payload.get("username").getAsString();
    String password = payload.get("password").getAsString();
    String email = payload.get("email").getAsString();

    User u = new User();
    u.setId(UUID.randomUUID().toString());
    u.setUsername(username);
    u.setPassword(password);
    u.setEmail(email);

    return database.addUser(u);
}



    public User login(JsonObject payload) {
        String username = payload.get("username").getAsString();
        String password = payload.get("password").getAsString();
        return database.findUserByUsernameAndPassword(username, password);
    }

    public boolean changePassword(User user, JsonObject payload) {
        String oldPw = payload.get("oldPassword").getAsString();
        String newPw = payload.get("newPassword").getAsString();
        return database.updatePassword(user, oldPw, newPw);
    }


    public boolean addPlaylist(User user, JsonObject payload) {
        String name = payload.get("name").getAsString();

        if (database.findPlaylistByName(user, name) != null) {
            return false;
        }

        Playlist p = new Playlist(
                playlistIdGenerator.incrementAndGet(),
                name,
                user
        );
        p.setLiked(false);

        return database.addPlaylist(user, p);
    }

    public boolean deletePlaylist(User user, JsonObject payload) {
        int id = payload.get("playlistId").getAsInt();
        Playlist pl = database.findPlaylistById(user, id);
        if (pl == null) return false;

        if (!Objects.equals(pl.getOwner(), user)) {
            return false;
        }
        return database.deletePlaylist(user, id);
    }

    public boolean sharePlaylist(User user, int playlistId, String targetUsername) {
        Playlist pl = database.findPlaylistById(user, playlistId);
        if (pl == null) return false;

        if (!Objects.equals(pl.getOwner(), user)) {
            return false;
        }

        User target = database.findUserByUsername(targetUsername);
        if (target == null) return false;

        Playlist copy = new Playlist(
                playlistIdGenerator.incrementAndGet(),
                pl.getName() + "_shared",
                pl.getOwner()
        );
        copy.setSongs(new ArrayList<>(pl.getSongs()));

        return database.addPlaylist(target, copy);
    }


    public boolean addSong(User user, JsonObject payload) {
        String title = payload.get("title").getAsString();
        String artistName = payload.get("artist").getAsString();

        if (database.findSongByName(user, title) != null) {
            return false;
        }

        Song song = new Song();
        song.setId(songIdGenerator.incrementAndGet());
        song.setName(title);
        song.setArtist(new Artist(artistName));
        song.setSource(payload.has("source") ? payload.get("source").getAsString() : "manual");

        return database.addSong(user, song);
    }

    public boolean deleteSong(User user, JsonObject payload) {
        int id = payload.get("songId").getAsInt();
        return database.deleteSong(user, id);
    }

    public Song getSong(User user, JsonObject payload) {
        int id = payload.get("songId").getAsInt();
        return database.findSongById(user, id);
    }

    public JsonArray listSongs(User user) {
        List<Song> songs = database.getSongs(user);
        JsonArray arr = new JsonArray();
        for (Song s : songs) {
            JsonObject o = new JsonObject();
            o.addProperty("id", s.getId());
            o.addProperty("title", s.getName());
            o.addProperty("artist", s.getArtist() != null ? s.getArtist().getName() : "Unknown");
            o.addProperty("source", s.getSource());
            arr.add(o);
        }
        return arr;
    }

    public Song findSongById(User user, int songId) {
        return database.findSongById(user, songId);
    }


    public boolean addSongToPlaylist(User user, int playlistId, Song song) {
        return database.addSongToPlaylist(user, playlistId, song);
    }

    public boolean removeSongFromPlaylist(User user, int playlistId, int songId) {
        return database.removeSongFromPlaylist(user, playlistId, songId);
    }
}

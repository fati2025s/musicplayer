package org.example;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.util.*;

public class Controller {
    final Database database = new Database();

    public boolean register(JsonObject payload) {
        String username = payload.get("username").getAsString();
        String password = payload.get("password").getAsString();
        String email = payload.get("email").getAsString();

        if (database.findUserByUsername(username) != null) return false;
        if (database.findUserByEmail(email) != null) return false;

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

    public boolean logout(User user) {
        return database.logoutUser(user);
    }

    public boolean changePassword(User user, JsonObject payload) {
        String oldPw = payload.get("oldPassword").getAsString();
        String newPw = payload.get("newPassword").getAsString();

        if (!user.getPassword().equals(oldPw)) return false;
        return database.updatePassword(user, oldPw, newPw);
    }

    public boolean changeUserInfo(User user, JsonObject payload) {
        if (payload.has("email")) {
            String newEmail = payload.get("email").getAsString();
            if (!newEmail.equals(user.getEmail()) && database.findUserByEmail(newEmail) != null)
                return false;
            user.setEmail(newEmail);
        }
        return database.updateUser(user);
    }

   public boolean addPlaylist(User user, JsonObject payload) {
    String name = payload.get("name").getAsString();

    if (database.findPlaylistByName(user, name) != null) return false;

    Playlist p = new Playlist(0, name, user.getUsername());
    p.setShared(false);
    p.setReadOnly(false);

    return database.addPlaylist(user, p);
}


    public boolean deletePlaylist(User user, JsonObject payload) {
    int id = payload.get("playlistId").getAsInt();
    Playlist pl = database.findPlaylistById(user, id);
    if (pl == null) return false;
    if (!Objects.equals(pl.getOwnerUsername(), user.getUsername())) return false;
    return database.deletePlaylist(user, id);
}

public boolean renamePlaylist(User user, JsonObject payload) {
    int playlistId = payload.get("playlistId").getAsInt();
    String newName = payload.get("newName").getAsString();
    Playlist pl = database.findPlaylistById(user, playlistId);
    if (pl == null) return false;
    if (!Objects.equals(pl.getOwnerUsername(), user.getUsername())) return false;
    return database.renamePlaylist(user, playlistId, newName);
}


   public boolean sharePlaylist(User user, JsonObject payload) {
    int playlistId = payload.get("playlistId").getAsInt();

    String targetUsername = payload.has("targetUsername")
            ? payload.get("targetUsername").getAsString()
            : null;

    Playlist pl = database.findPlaylistById(user, playlistId);
    if (pl == null) return false;

    if (!Objects.equals(pl.getOwnerUsername(), user.getUsername())) return false;

    if (targetUsername == null) return false;
    User target = database.findUserByUsername(targetUsername);

    if (target == null) return false;

    Playlist ref = new Playlist(0, pl.getName(), pl.getOwnerUsername());
    ref.setSongs(new ArrayList<>(pl.getSongs()));
    ref.setShared(true);
    ref.setReadOnly(true);

    return database.addPlaylist(target, ref);
}



    public JsonArray listPlaylists(User user) {
    List<Playlist> pls = database.getPlaylists(user);
    JsonArray arr = new JsonArray();
    for (Playlist p : pls) {
        JsonObject o = new JsonObject();
        o.addProperty("id", p.getId());
        o.addProperty("name", p.getName());

        String ownerUsername = p.getOwnerUsername();
        o.addProperty("owner", ownerUsername == null ? "" : ownerUsername);
        o.addProperty("ownerUsername", ownerUsername == null ? "" : ownerUsername);

        o.addProperty("isShared", p.isShared());
        o.addProperty("readOnly", p.isReadOnly());
        o.addProperty("numberOfSongs", p.getNumberOfSongs());
        arr.add(o);
    }
    return arr;
}


public boolean addSongAsGuest(JsonObject payload) {
    String title = payload.get("title").getAsString();
    String artistName = payload.get("artist").getAsString();

    User guest = database.findUserByUsername("guest");
    if (guest == null) {
        guest = new User("guest-id", "guest", "guest@example.com", "nopass");
        database.addUser(guest);
    }

    if (database.findSongByName(guest, title) != null) return false;

    Song song = new Song();
    song.setId(Database.songIdGenerator.incrementAndGet());
    song.setName(title);
    song.setArtist(new Artist(artistName));
    song.setSource(payload.has("source") ? payload.get("source").getAsString() : "manual");
    song.setLikeCount(0);

    boolean added = database.addSong(guest, song);
    if (added) {
        lastGeneratedSongId = song.getId();
    }
    return added;
}

private int lastGeneratedSongId = -1;
public int getLastGeneratedSongId() {
    return lastGeneratedSongId;
}

public boolean markSongAddedByUser(User user, int songId) {
    return database.addSongByUser(user, songId);
}

public boolean deleteAccount(User user) {
    if (user == null) return false;
    return database.removeUser(user);
}




    public boolean deleteSong(User user, JsonObject payload) {
        int id = payload.get("songId").getAsInt();
        return database.deleteSong(user, id);
    }

    public Song findSongById(User user, int songId) {
        return database.findSongById(user, songId);
    }

    public JsonArray listSongs(User user) {
    User guest = database.findUserByUsername("guest");
    if (guest == null) {
        return new JsonArray();
    }

    List<Song> songs = database.getSongs(guest);
    JsonArray arr = new JsonArray();
    for (Song s : songs) {
        JsonObject o = new JsonObject();
        o.addProperty("id", s.getId());
        o.addProperty("title", s.getName());
        o.addProperty("artist", s.getArtist() != null ? s.getArtist().getName() : "Unknown");
        o.addProperty("source", s.getSource());
        o.addProperty("likeCount", s.getLikeCount());
        arr.add(o);
    }
    return arr;
}


    public JsonArray listTopLikedSongs() {
        List<Song> songs = database.getAllSongsSortedByLikes();
        JsonArray arr = new JsonArray();
        for (Song s : songs) {
            JsonObject o = new JsonObject();
            o.addProperty("id", s.getId());
            o.addProperty("title", s.getName());
            o.addProperty("artist", s.getArtist() != null ? s.getArtist().getName() : "Unknown");
            o.addProperty("likeCount", s.getLikeCount());
            arr.add(o);
        }
        return arr;
    }


    public JsonArray listLikedSongs(User user) {
    List<Song> liked = database.getLikedSongs(user);
    JsonArray arr = new JsonArray();
    for (Song song : liked) {
        arr.add(song.getId());
    }
    return arr;
}


public JsonArray listSongsAddedByMe(User user) {
    List<Integer> ids = database.getSongsAddedByUser(user);
    JsonArray arr = new JsonArray();
    for (Integer id : ids) {
        Song s = database.findSongById(user, id);
        if (s != null) {
            JsonObject o = new JsonObject();
            o.addProperty("id", s.getId());
            o.addProperty("title", s.getName());
            o.addProperty("artist", s.getArtist() != null ? s.getArtist().getName() : "Unknown");
            o.addProperty("source", s.getSource());
            o.addProperty("likeCount", s.getLikeCount());
            arr.add(o);
        }
    }
    return arr;
}


   public boolean toggleLike(User user, int songId) {
    return database.toggleLike(user, songId);
}








    public boolean checkSharePermission(User user, JsonObject payload) {
    int playlistId = payload.get("playlistId").getAsInt();
    Playlist pl = database.findPlaylistById(user, playlistId);
    return pl != null && Objects.equals(pl.getOwnerUsername(), user.getUsername());
}

}

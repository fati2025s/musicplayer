package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

import java.util.ArrayList;
import java.util.List;

public class Contoroller {
    private final Gson json = new Gson();
    Databass databass = new Databass();

    public synchronized boolean register(JsonObject userJson) {
        //User user = json.fromJson(userJson, User.class);
        if(databass.exitingUser(json.fromJson(userJson, User.class)))
            return false;
        System.out.println("yooohooo");
        databass.addUser(json.fromJson(userJson, User.class));
        return true;
    }

    public synchronized boolean login(JsonObject user){
        User user1 = json.fromJson(user, User.class);
        if(databass.exitingUserL(user1.getUsername(), user1.getPassword()))
            return true;
        return false;
    }

    public synchronized void deleteUser(User user,JsonObject userJson){
        User user1 = json.fromJson(userJson, User.class);
        databass.deletuser(user1);
    }

    public synchronized boolean addSong(User user,JsonObject song) {
        if(databass.vojodmusic(json.fromJson(song, Song.class),user))
            return false;
        databass.addmusic(json.fromJson(song, Song.class),user);
        return true;
    }

    public synchronized boolean toggleLikeMusic(User user, JsonObject payload) {
        int musicId = payload.get("musicId").getAsInt();
        return databass.toggleLike(user, musicId);
    }


    public synchronized boolean deleteSong(User user,JsonObject song) {

        if(databass.vojodmusic(json.fromJson(song, Song.class),user)) {
            databass.removemusic(json.fromJson(song, Song.class),user);
            return true;
        }
        return false;
    }

    public synchronized Song getSong(User user,JsonObject songs) {
        Song song = json.fromJson(songs, Song.class);
        if(databass.vojodmusic(song,user)){
            return song;
        }
        return null;
    }

    public synchronized boolean addPlaylist(User user,JsonObject playlist) {
        if(databass.vojodplay(json.fromJson(playlist, PlayList.class),user))
            return false;
        databass.addplaylist(json.fromJson(playlist, PlayList.class),user);
        return true;
    }

    public synchronized boolean deletePlaylist(User user, JsonObject payload) {
        int playlistId = payload.get("playlistId").getAsInt();
        PlayList toRemove = null;
        for (PlayList p : user.getPlaylists()) {
            if (p.getId() == playlistId) {
                toRemove = p;
                break;
            }
        }
        if (toRemove != null) {
            databass.removplaylist(toRemove, user);
            return true;
        }
        return false;
    }

    public synchronized boolean changePassword(User use,JsonObject user) {
        User user1 = json.fromJson(user, User.class);
        if(databass.exitingUser(user1)){
            databass.changePassword(use,user1);
            return true;
        }
        return false;
    }

    public synchronized boolean changeUsername(User use,JsonObject user) {
        User user1 = json.fromJson(user, User.class);
        if(databass.exitingUser(user1)){
            databass.changeUsername(use,user1);
            return true;
        }
        return false;
    }

    public synchronized boolean updateUser(JsonObject user) {
        return true;
    }

    public synchronized boolean addProfile(User user, JsonObject payload) {
        String path = payload.get("path").getAsString();
        return databass.addProfilePath(path, user);
    }

    public synchronized boolean removeProfile(User user, JsonObject payload) {
        String path = payload.get("path").getAsString();
        return databass.removeProfilePath(path, user);
    }

    public synchronized boolean setCurrentProfile(User user, JsonObject payload) {
        if (payload == null || !payload.has("currentProfileIndex") || payload.get("currentProfileIndex").isJsonNull()) {
            System.out.println("payload null یا currentProfileIndex موجود نیست!");
            return false;
        }

        try {
            int index = payload.get("currentProfileIndex").getAsInt();
            return databass.setCurrentProfileIndex(user, index);
        } catch (NumberFormatException e) {
            System.out.println("currentProfileIndex عدد صحیح نیست!");
            return false;
        }
    }
}
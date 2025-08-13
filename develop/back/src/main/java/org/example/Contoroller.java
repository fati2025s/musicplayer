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
        databass.addUser(json.fromJson(userJson, User.class));
        return true;
    }

    public synchronized boolean login(JsonObject user){
        User user1 = json.fromJson(user, User.class);
        if(databass.exitingUserL(user1.getUsername(), user1.getPassword()))
            return true;
        return false;
    }

    public synchronized boolean addSong(User user,JsonObject song) {
        if(databass.vojodmusic(json.fromJson(song, Song.class),user))
            return false;
        databass.addmusic(json.fromJson(song, Song.class),user);
        return true;
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

    public synchronized boolean deletePlaylist(User user,JsonObject playlist) {
        if(databass.vojodplay(json.fromJson(playlist, PlayList.class),user)) {
            databass.removplaylist(json.fromJson(playlist, PlayList.class),user);
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

    public synchronized boolean updateUser(JsonObject user) {
        return true;
    }

    public synchronized PlayList getPlaylist(JsonObject playlist) {
        return json.fromJson(playlist, PlayList.class);
    }

    public synchronized List<PlayList> getPlaylists(JsonObject playlists) {
        List<PlayList> playlistList = new ArrayList<>();
        /*for (JsonObject playlist : playlists) {
            playlistList.add(json.fromJson(playlist, PlayList.class));
        }*/
        return playlistList;
    }
}

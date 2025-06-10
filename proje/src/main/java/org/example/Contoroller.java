package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

import java.util.ArrayList;
import java.util.List;

public class Contoroller {
    List<User> users=new ArrayList<>();
    List<Song> songs=new ArrayList<>();
    List<PlayList> playlists=new ArrayList<>();
    private final Gson json = new Gson();

    public synchronized boolean register(JsonObject userJson) {
        String username = userJson.get("username").getAsString();

        for (User existingUser : users) {
            if (existingUser.getUsername().equals(username)) {
                return false;
            }
        }
        users.add(json.fromJson(userJson, User.class));
        return true;
    }


    public synchronized boolean login(JsonObject user){
        for(User user1 : users) {
            if(user1.getUsername().equals(user.get("username").getAsString())) {
                if(user.get("password").getAsString().equals(user1.getPassword())) {
                    return true;
                }
                return false;
            }
        }
        return false;
    }

    public synchronized void addSong(JsonObject song) {
        songs.add(json.fromJson(song, Song.class));
    }

    public synchronized void addPlaylist(JsonObject playlist) {
        playlists.add(json.fromJson(playlist, PlayList.class));
    }

    public synchronized boolean deleteSong(JsonObject song) {
        for(Song song1 : songs) {
            if(song1.equals(json.fromJson(song, Song.class))) {
                songs.remove(song1);
                return true;
            }
        }
        return false;
    }

    public synchronized boolean deletePlaylist(JsonObject playlist) {
        for(PlayList playlist1 : playlists) {
            if(playlist1.equals(json.fromJson(playlist, PlayList.class))) {
                playlists.remove(playlist1);
                return true;
            }
        }
        return false;
    }

    public synchronized boolean changePassword(JsonObject user) {
        for(User user1 : users) {
            if(user1.getUsername().equals(user.get("username").getAsString())) {
                User user2=json.fromJson(user, User.class);
                user1.setPassword(user.get("password").getAsString());
                return true;
            }
        }

        return false;
    }

    public synchronized boolean updateUser(JsonObject user) {
        return true;
    }

    public synchronized Song getSong(JsonObject songs) {
        return json.fromJson(songs, Song.class);
    }

    public synchronized List<Song> getSongs(JsonObject songs) {
        List<Song> songList = new ArrayList<>();
        /*for (JsonObject song : songs) {
            songList.add(json.fromJson(song, Song.class));
        }
        return songList;*/
        return songList;
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

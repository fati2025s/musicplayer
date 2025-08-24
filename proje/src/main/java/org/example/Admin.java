package org.example;

import java.util.*;
import java.util.stream.Collectors;

public class Admin extends User {

    private final Databass db;

    public Admin(String id, String username, String email, String password) {
        super(id, username, email, password);
        this.db = new Databass();
    }

    public boolean deleteUser(User user) {
        if(db.exitingUser(user)){
            db.deletuser(user);
            return true;
        }
        return false;
    }

    public List<User> getusers() {
        return db.getusers();
    }

    public User findUserByUsername(String username) {
        return db.findUserByUsername(username);
    }

    public List<PlayList> getAllPlaylists() {
        List<PlayList> playlists = new ArrayList<>();
        for (User user : db.getusers()) {
            if (user.getPlaylists() != null) playlists.addAll(user.getPlaylists());
        }
        return playlists;
    }

    public boolean deletePlaylist(PlayList playlist) {
        boolean removed = false;
        for (User user : db.getusers()) {
            if (db.vojodplay(playlist,user)){
                db.removplaylist(playlist,user);
                removed = true;
            }
        }
        return removed;
    }

    public List<PlayList> getUserPlaylists(User user) {
        return user != null && user.getPlaylists() != null ? user.getPlaylists() : Collections.emptyList();
    }

    public List<Song> getAllSongs() {
        List<Song> songs = new ArrayList<>();
        for (User user : db.getusers()) {
            if (user.getSongs() != null) songs.addAll(user.getSongs());
        }
        return songs;
    }

    public boolean deleteSong(Song song) {
        boolean removed = false;
        for (User user : db.getusers()) {
            if (db.vojodmusic(song,user)){
                db.removemusic(song,user);
                removed = true;
            }
            if (user.getLikedSongs() != null)
                user.getLikedSongs().remove(song);
            //اینجا ایراد داره باید به دیتا بیس وصل شه اونجا کاراشو بکنه
        }
        return removed;
    }

    public List<Song> getMostPlayedSongs() {
        return getAllSongs().stream()
                .sorted(Comparator.comparingInt(Song::getPakhsh).reversed())
                .collect(Collectors.toList());
    }

    public List<Song> getMostLikedSongs() {
        return getAllSongs().stream()
                .sorted(Comparator.comparingInt(Song::getLikeCount).reversed())
                .collect(Collectors.toList());
    }
}
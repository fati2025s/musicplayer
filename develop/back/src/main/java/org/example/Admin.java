package org.example;

import java.util.*;
import java.util.stream.Collectors;

public class Admin extends User {

    private final Database db;

    public Admin(String id, String username, String email, String password) {
        super(id, username, email, password);
        this.db = new Database();
    }

    public boolean deleteUser(User user) { 
        return db.removeUser(user); 
    }

    public List<User> getAllUsers() { 
        return db.getAllUsers(); 
    }

    public User findUserByUsername(String username) { 
        return db.findUserByUsername(username); 
    }

    public List<Playlist> getAllPlaylists() {
        List<Playlist> playlists = new ArrayList<>();
        for (User user : db.getAllUsers()) {
            if (user.getPlaylists() != null) playlists.addAll(user.getPlaylists());
        }
        return playlists;
    }

    public boolean deletePlaylist(Playlist playlist) {
        boolean removed = false;
        for (User user : db.getAllUsers()) {
            if (db.removePlaylist(user, playlist)) removed = true;
        }
        return removed;
    }

    public List<Playlist> getUserPlaylists(User user) {
        return user != null && user.getPlaylists() != null ? user.getPlaylists() : Collections.emptyList();
    }

    public List<Song> getAllSongs() {
        List<Song> songs = new ArrayList<>();
        for (User user : db.getAllUsers()) {
            if (user.getSongs() != null) songs.addAll(user.getSongs());
        }
        return songs;
    }

    public boolean deleteSong(Song song) {
        boolean removed = false;
        for (User user : db.getAllUsers()) {
            if (db.removeSong(user, song)) removed = true;
            if (user.getLikedSongs() != null) user.getLikedSongs().remove(song);
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

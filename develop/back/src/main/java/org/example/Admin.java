package org.example;

import java.util.*;
import java.util.stream.Collectors;

public class Admin extends User {

    private Databass db;

    public Admin(String id, String username, String email, String password) {
        super(id, username, email, password);
        this.db = new Databass();
    }

    public void deleteUser(User user) {
        db.users.remove(user);
        db.write(db.users);
    }

    public List<User> getAllUsers() {
        return db.users;
    }

    public User findUserByUsername(String username) {
        for (User user : db.users) {
            if (user.getUsername().equalsIgnoreCase(username)) {
                return user;
            }
        }
        return null;
    }

    public List<PlayList> getAllPlaylists() {
        List<PlayList> playlists = new ArrayList<>();
        for (User user : db.users) {
            playlists.addAll(user.getPlaylists());
        }
        return playlists;
    }

    public void deletePlaylist(PlayList playlist) {
        for (User user : db.users) {
            user.getPlaylists().remove(playlist);
        }
        db.write(db.users);
    }

    public List<Song> getAllSongs() {
        List<Song> songs = new ArrayList<>();
        for (User user : db.users) {
            songs.addAll(user.getSongs());
        }
        return songs;
    }

    public void deleteSong(Song song) {
        for (User user : db.users) {
            user.getSongs().remove(song);
            user.getLikedSongs().remove(song);
        }
        db.write(db.users);
    }

    public List<Song> getMostPlayedSongs() {
        return getAllSongs().stream()
                .sorted((a, b) -> Integer.compare(b.getPakhsh(), a.getPakhsh()))
                .collect(Collectors.toList());
    }

    public List<Song> getMostLikedSongs() {
        return getAllSongs().stream()
                .sorted((a, b) -> Integer.compare(b.getLikeCount(), a.getLikeCount()))
                .collect(Collectors.toList());
    }

    public List<PlayList> getUserPlaylists(User user) {
        return user.getPlaylists();
    }
}

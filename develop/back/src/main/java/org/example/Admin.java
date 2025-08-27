package org.example;

import java.util.*;
import java.util.stream.Collectors;

public class Admin {

    private final Database db;

    public Admin(Database db) {
        this.db = db;
    }

    public List<User> getAllUsers() {
        return db.getAllUsers();
    }

    public User findUserByUsername(String username) {
        return db.findUserByUsername(username);
    }

    public String getUserInfo(String username) {
        User user = findUserByUsername(username);
        if (user == null) return "User not found";

        List<Song> likedSongs = db.getLikedSongs(user);

        return String.format(
                "ID: %s | Username: %s | Email: %s | Songs: %d | Playlists: %d | Liked Songs: %d",
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getSongs().size(),
                user.getPlaylists().size(),
                likedSongs.size()
        );
    }

    public boolean deleteUser(String username) {
        User u = db.findUserByUsername(username);
        return db.removeUser(u);
    }

    public List<Song> getAllSongs() {
        return db.getAllSongs();
    }

    public boolean deleteSong(int songId) {
        boolean removed = false;

        for (User u : db.getAllUsers()) {
            removed |= u.getSongs().removeIf(s -> s.getId() == songId);
        }

        for (Set<Integer> liked : db.getUserLikedSongs().values()) {
            liked.remove(songId);
        }

        for (User u : db.getAllUsers()) {
            for (Playlist p : u.getPlaylists()) {
                p.getSongs().removeIf(s -> s.getId() == songId);
            }
        }

        if (removed) {
            db.save();
        }

        return removed;
    }

    public List<Song> getTop20MostLikedSongs() {
        return db.getAllSongsSortedByLikes()
                 .stream()
                 .limit(20)
                 .collect(Collectors.toList());
    }
}

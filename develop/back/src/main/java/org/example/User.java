package org.example;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class User {
    private String id;
    private String username;
    private String password;
    private String email;

    private List<String> profilePicturePaths;  
    private List<Song> songs;
    private List<Playlist> playlists;

    private boolean canReceiveShares = true;

    public User(String id, String username, String email, String password) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.password = password;
        this.profilePicturePaths = new ArrayList<>();
        this.songs = new ArrayList<>();
        this.playlists = new ArrayList<>();
    }

    public User() {
        this.profilePicturePaths = new ArrayList<>();
        this.songs = new ArrayList<>();
        this.playlists = new ArrayList<>();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public List<String> getProfilePicturePaths() { return profilePicturePaths; }
    public void setProfilePicturePaths(List<String> profilePicturePaths) { this.profilePicturePaths = profilePicturePaths; }

    public List<Song> getSongs() { return songs; }
    public void setSongs(List<Song> songs) { this.songs = songs; }

    public List<Playlist> getPlaylists() { return playlists; }
    public void setPlaylists(List<Playlist> playlists) { this.playlists = playlists; }

    public boolean canReceiveShares() { return canReceiveShares; }
    public void setCanReceiveShares(boolean canReceiveShares) { this.canReceiveShares = canReceiveShares; }
    public void toggleReceiveShares() { this.canReceiveShares = !this.canReceiveShares; }

    public void updateProfile(String newUsername, String newEmail) {
        this.username = newUsername;
        this.email = newEmail;
    }

    public void changeProfilePicture(String newPath) {
        if (!profilePicturePaths.contains(newPath)) {
            profilePicturePaths.add(newPath);
        }
    }

    public void addPlaylist(Playlist playlist) {
        if (!playlists.contains(playlist)) {
            playlists.add(playlist);
            playlist.setOwnerUsername(this.username);
        }
    }

    public void removePlaylist(Playlist playlist) {
        if (playlist.getOwnerUsername() != null && playlist.getOwnerUsername().equals(this.username)) {
            playlists.remove(playlist);
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(id, user.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}

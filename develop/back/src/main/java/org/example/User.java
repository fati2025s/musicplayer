package org.example;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class User {
    private String id;
    private String username;
    private String email;
    private String password;
    private List<String> profilePicturePaths;  
    private List<Song> songs;
    private List<PlayList> playlists = new ArrayList<>();
    private List<Song> likedSongs = new ArrayList<>();
    private List<Song> likedArtists = new ArrayList<>();
    private boolean canReceiveShares = true;
    

    public User(String id, String username, String email, String password) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.password = password;
        this.profilePicturePaths = new ArrayList<>();
        this.songs = new ArrayList<>();
    }

    public boolean canReceiveShares() {
        return canReceiveShares;
    }

    public void setCanReceiveShares(boolean canReceiveShares) {
        this.canReceiveShares = canReceiveShares;
    }

    public void toggleReceiveShares() {
        this.canReceiveShares = !this.canReceiveShares;
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
    public List<PlayList> getPlaylists() { return playlists; }
    public void setPlaylists(List<PlayList> playlists) { this.playlists = playlists; }
    public List<Song> getLikedSongs() { return likedSongs; }
    public void setLikedSongs(List<Song> likedSongs) { this.likedSongs = likedSongs; }
    public List<Song> getLikedArtists() { return likedArtists; }
    public void setLikedArtists(List<Song> likedArtists) { this.likedArtists = likedArtists; }

    public void updateProfile(String newUsername, String newEmail) {
        this.username = newUsername;
        this.email = newEmail;
    }

    public void likeSong(Song song) {
        if (!likedSongs.contains(song)) {
            likedSongs.add(song);
            song.addLikeCount();
            song.setLiked(true);
        }
    }

    public void addPlaylist(PlayList playlist) {
        if (!playlists.contains(playlist)) {
            playlists.add(playlist);
        }
    }

    public void removePlaylist(PlayList playlist) {
        if (playlist.getUser().equals(this)) {
            playlists.remove(playlist);
        }
    }

    public void changeProfilePicture(String newPath) {
        if (!profilePicturePaths.contains(newPath)) {
            profilePicturePaths.add(newPath);
        }
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(id, user.id) && Objects.equals(username, user.username) && Objects.equals(email, user.email) &&
                Objects.equals(password, user.password) && Objects.equals(profilePicturePaths, user.profilePicturePaths) &&
                Objects.equals(songs, user.songs) && Objects.equals(playlists, user.playlists) &&
                Objects.equals(likedSongs, user.likedSongs) && Objects.equals(likedArtists, user.likedArtists);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, username, email, password, profilePicturePaths, songs, playlists, likedSongs, likedArtists);
    }
    
}

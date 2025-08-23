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
    private List<Playlist> playlists;          
    private List<Song> likedSongs;             
    private List<Artist> likedArtists;         

    private boolean canReceiveShares = true;

    public User(String id, String username, String email, String password) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.password = password;
        this.profilePicturePaths = new ArrayList<>();
        this.songs = new ArrayList<>();
        this.playlists = new ArrayList<>();
        this.likedSongs = new ArrayList<>();
        this.likedArtists = new ArrayList<>();
    }

    public User() {
        this.profilePicturePaths = new ArrayList<>();
        this.songs = new ArrayList<>();
        this.playlists = new ArrayList<>();
        this.likedSongs = new ArrayList<>();
        this.likedArtists = new ArrayList<>();
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

    public List<Song> getLikedSongs() { return likedSongs; }
    public void setLikedSongs(List<Song> likedSongs) { this.likedSongs = likedSongs; }

    public List<Artist> getLikedArtists() { return likedArtists; }
    public void setLikedArtists(List<Artist> likedArtists) { this.likedArtists = likedArtists; }

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
        }
    }

    public void removePlaylist(Playlist playlist) {
        if (playlist.getOwner() != null && playlist.getOwner().equals(this)) {
            playlists.remove(playlist);
        }
    }

    public void likeSong(Song song) {
        if (!likedSongs.contains(song)) {
            likedSongs.add(song);
            song.addLikeCount();
            song.setLiked(true);
        }
    }

    public void likeArtist(Artist artist) {
        if (!likedArtists.contains(artist)) {
            likedArtists.add(artist);
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

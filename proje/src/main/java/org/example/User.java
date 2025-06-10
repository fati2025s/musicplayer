package org.example;

import java.util.List;
import java.util.Map;

public class User {
    private String id;
    private String username;
    private String email;
    private String password;
    private String profilePicturePath;
    private List<PlayList> playlists;
    private List<Song> likedSongs;
    private List<Song> likedArtists;

    public User(String id, String username, String email, String password) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.password = password;
        this.profilePicturePath = null;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getProfilePicturePath() {
        return profilePicturePath;
    }

    public void setProfilePicturePath(String profilePicturePath) {
        this.profilePicturePath = profilePicturePath;
    }

    public List<PlayList> getPlaylists() {
        return playlists;
    }

    public void setPlaylists(List<PlayList> playlists) {
        this.playlists = playlists;
    }

    public List<Song> getLikedSongs() {
        return likedSongs;
    }

    public void setLikedSongs(List<Song> likedSongs) {
        this.likedSongs = likedSongs;
    }

    public List<Song> getLikedArtists() {
        return likedArtists;
    }

    public void setLikedArtists(List<Song> likedArtists) {
        this.likedArtists = likedArtists;
    }


    public void updateProfile(String newUsername, String newEmail) {

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
        /*if (playlist.getUser().equals(this)) {
            playlists.remove(playlist);
        }*/
    }

    public void changeProfilePicture(String newPath) {

    }
}

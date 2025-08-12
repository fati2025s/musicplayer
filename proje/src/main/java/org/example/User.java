package org.example;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public class User {
    private String id;
    private String username;
    private String email;
    private String password;
    private List<File> profilePicturePath;
    private List<Song> songs;
    private List<PlayList> playlists=new ArrayList<>();
    private List<Song> likedSongs;
    private List<Song> likedArtists=new ArrayList<>();

    public User(String id, String username, String email, String password) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.password = password;
        this.profilePicturePath = new ArrayList<>();
        this.likedSongs = new ArrayList<>();
        this.songs = new ArrayList<>();
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

    public void setSongs(List<Song> songs) {
        this.songs = songs;
    }

    public void setProfilePicturePath(List<File> profilePicturePath) {
        this.profilePicturePath = profilePicturePath;
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

    public List<File> getProfilePicturePath() {
        return profilePicturePath;
    }

    public List<Song> getSongs() {
        return songs;
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

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(id, user.id) && Objects.equals(username, user.username) && Objects.equals(email, user.email) &&
                Objects.equals(password, user.password) && Objects.equals(profilePicturePath, user.profilePicturePath) &&
                Objects.equals(songs, user.songs) && Objects.equals(playlists, user.playlists) && Objects.equals(likedSongs, user.likedSongs) &&
                Objects.equals(likedArtists, user.likedArtists);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, username, email, password, profilePicturePath, songs, playlists, likedSongs, likedArtists);
    }
}

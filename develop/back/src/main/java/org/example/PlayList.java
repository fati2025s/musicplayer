package org.example;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class Playlist {
    private int id;
    private String name;
    private String ownerUsername; 
    private List<Song> songs;
    private List<Artist> artists;
    private boolean liked = false;
    private boolean readOnly = false;
    private boolean shared;

    public Playlist(int id, String name, String ownerUsername) {
        this.id = id;
        this.name = name;
        this.ownerUsername = ownerUsername;
        this.songs = new ArrayList<>();
        this.artists = new ArrayList<>();
    }

    public Playlist(int id, String name, String ownerUsername, boolean readOnly) {
        this(id, name, ownerUsername);
        this.readOnly = readOnly;
    }

    public Playlist() {
        this.songs = new ArrayList<>();
        this.artists = new ArrayList<>();
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getOwnerUsername() { return ownerUsername; }
    public void setOwnerUsername(String ownerUsername) { this.ownerUsername = ownerUsername; }

    public List<Song> getSongs() { return songs; }
    public void setSongs(List<Song> songs) { this.songs = songs; }

    public List<Artist> getArtists() { return artists; }

    public boolean isLiked() { return liked; }
    public void setLiked(boolean liked) { this.liked = liked; }

    public boolean isReadOnly() { return readOnly; }
    public void setReadOnly(boolean readOnly) { this.readOnly = readOnly; }

    public boolean isShared() { return shared; }
    public void setShared(boolean shared) { this.shared = shared; }

    public void addSong(Song song) {
        if (readOnly) return;
        songs.add(song);

        Artist artist = song.getArtist();
        if (artist != null) {
            if (!artists.contains(artist)) {
                artists.add(artist);
            }
            artist.getMusics().add(song);
            artist.setNumOfSongs(artist.getNumOfSongs() + 1);
        }
    }

    public void removeSong(Song song) {
        if (readOnly) return;
        songs.remove(song);

        Artist artist = song.getArtist();
        if (artist != null) {
            artist.getMusics().remove(song);
            artist.setNumOfSongs(artist.getNumOfSongs() - 1);

            boolean stillExists = songs.stream()
                    .anyMatch(s -> s.getArtist() != null && s.getArtist().equals(artist));
            if (!stillExists) {
                artists.remove(artist);
            }
        }
    }

    public int getNumberOfSongs() {
        return songs.size();
    }

    public void rename(String newName) {
        if (!readOnly) {
            this.name = newName;
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Playlist playlist = (Playlist) o;
        return id == playlist.id;
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}

package org.example;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class Playlist {
    private int id;
    private String name;
    private User owner;              // فقط یک مالک
    private List<Song> songs;        // آهنگ‌ها
    private List<Artist> artists;    // خواننده‌ها
    private boolean liked = false;   // مثلا برای Favorite
    private boolean readOnly = false; // 🔹 برای کاربرهای غیرمالک

    // 🔹 سازنده
    public Playlist(int id, String name, User owner) {
        this.id = id;
        this.name = name;
        this.owner = owner;
        this.songs = new ArrayList<>();
        this.artists = new ArrayList<>();
    }

    // 🔹 سازنده با readonly
    public Playlist(int id, String name, User owner, boolean readOnly) {
        this(id, name, owner);
        this.readOnly = readOnly;
    }

    // 🔹 سازنده خالی
    public Playlist() {
        this.songs = new ArrayList<>();
        this.artists = new ArrayList<>();
    }

    // --- Getter & Setter ---
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public User getOwner() { return owner; }
    public void setOwner(User owner) { this.owner = owner; }

    public List<Song> getSongs() { return songs; }
    public void setSongs(List<Song> songs) { this.songs = songs; }

    public List<Artist> getArtists() { return artists; }

    public boolean isLiked() { return liked; }
    public void setLiked(boolean liked) { this.liked = liked; }

    public boolean isReadOnly() { return readOnly; }
    public void setReadOnly(boolean readOnly) { this.readOnly = readOnly; }

    // --- مدیریت آهنگ‌ها ---
    public void addSong(Song song) {
        if (readOnly) return; // 🔹 جلوگیری از تغییر
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
        if (readOnly) return; // 🔹 جلوگیری از تغییر
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

    public boolean canUserEdit(User user) {
        return this.owner != null && this.owner.equals(user) && !this.readOnly;
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

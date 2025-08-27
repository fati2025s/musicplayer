package org.example;

import java.util.Objects;

public class Song {
    private int id;
    private String name;
    private String text;
    private Artist artist;
    private String album;
    private String icon;
    private String Qrcode;
    private boolean liked;
    private int pakhsh = 0;
    private String filePath;
    private String source;

    private int likeCount = 0;

    public Song(int id, String name, Artist artist, String album) {
        this.id = id;
        this.name = name;
        this.artist = artist;
        this.album = album;
    }

    public Song() { }

    public String getFilePath() {
        return filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }

    public String getSource() {
        return source;
    }
    public void setSource(String source) {
        this.source = source;
    }

    public String getIcon() {
        return icon;
    }

    public String getQrcode() {
        return Qrcode;
    }

    public int getPakhsh() {
        return pakhsh;
    }

    public void setPakhsh(int pakhsh) {
        this.pakhsh = pakhsh;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public void setQrcode(String qrcode) {
        Qrcode = qrcode;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public int getId() {
        return id;
    }

    public boolean getLiked() {
        return liked;
    }

    public void setLiked(boolean liked) {
        this.liked = liked;
    }

    public String getName() {
        return name;
    }

    public Artist getArtist() {
        return artist;
    }

    public String getAlbum() {
        return album;
    }

    public void setId(int id) {
        this.id = id;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setArtist(Artist artist) {
        this.artist = artist;
    }

    public void setAlbum(String album) {
        this.album = album;
    }

    public int getLikeCount() {
        return likeCount;
    }

    public void addLikeCount() {
        likeCount++;
    }

    public void removeLikeCount() {
        if (likeCount > 0) likeCount--;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        Song song = (Song) o;
        return id == song.id &&
               Objects.equals(name, song.name) &&
               Objects.equals(text, song.text) &&
               Objects.equals(artist, song.artist) &&
               Objects.equals(album, song.album);
    }

    @Override
    public String toString() {
        return "[Name: " + name +
               ", Artist: " + (artist != null ? artist.getName() : "Unknown") +
               ", Album: " + album +
               ", Likes: " + likeCount +
               ", Plays: " + pakhsh + "]";
    }

    public void like() {
        this.setLiked(true);
        addLikeCount();
    }

    public void unlike() {
        this.setLiked(false);
        removeLikeCount();
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, text, artist, album);
    }

    public void setLikeCount(int i) {
    this.likeCount = i;
}

}

package org.example;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class Artist {
    private String name;
    private List<Song> ahang;
    private int numOfSongs=0;

    public Artist(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<Song> getMusics() {
        return ahang;
    }

    public int getNumOfSongs() {
        return numOfSongs;
    }

    public void setMusics(List<Song> musics) {
        this.ahang = musics;
    }

    public void setNumOfSongs(int numOfSongs) {
        this.numOfSongs = numOfSongs;
    }

    @Override
    public String toString() {
        return name+"\n"+numOfSongs+"Music";
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        Artist artist = (Artist) o;
        return numOfSongs == artist.numOfSongs && Objects.equals(name, artist.name) && Objects.equals(ahang, artist.ahang);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, ahang, numOfSongs);
    }
}


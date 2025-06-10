package org.example;

import java.util.ArrayList;
import java.util.List;

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
}


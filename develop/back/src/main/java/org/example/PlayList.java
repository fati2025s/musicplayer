package org.example;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;

public class PlayList {
    private int id;
    private String name;
    private User user;
    private LocalDateTime creationTime;
    public boolean likeplaylist = false;
    private List<Song> music;
    private List<Artist> artists;

    public PlayList(int id, String name, User user, LocalDateTime creationTime) {
        this.music=new ArrayList<>();
        this.id = id;
        this.name = name;
        this.user = user;
        this.creationTime = creationTime;
    }

    public PlayList(){
        this.music=new ArrayList<>();
    }

    public int getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    /*public String getUser() {
        return user;
    }*/

    public LocalDateTime getCreationTime() {
        return creationTime;
    }

    public void setId(int id) {
        this.id = id;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public void setCreationTime(LocalDateTime creationTime) {
        this.creationTime = creationTime;
    }

    public List<Song> getMusics(){
        return music;
    }

    public int getNumberOfMusics(){
        return music.size();
    }

    public void addSong(Song song) {
        music.add(song);
        for(int i=0;i<artists.size();i++) {
            if(song.getArtist().getName().equals(artists.get(i).getName())) {
                song.getArtist().getMusics().add(music.get(i));
                song.getArtist().setNumOfSongs(song.getArtist().getNumOfSongs()+1);
            }
            else if(i==artists.size()-1) {
                artists.add(song.getArtist());
                song.getArtist().getMusics().add(music.get(i));
            }
        }
    }

    public void removeSong(Song song) {
        music.remove(song);
        song.getArtist().getMusics().remove(song);
        song.getArtist().setNumOfSongs(song.getArtist().getNumOfSongs()-1);
        artists.remove(song.getArtist());
    }

    public List<Artist> getArtists(){
        return artists;
    }

    /*public PlayList filter(Filter filter){
        PlayList playList=new PlayList();
        for(int i=0;i<music.size();i++) {
            if (filter.accept(music.get(i))) {
                playList.addSong(music.get(i));
            }
        }
        return playList;
    }

    public void sotrbytime(List<Song> music){
        music.sort(Comparator.comparing(Song::getTime));
    }

    public void sortbyname(List<Song> music){
        music.sort(Comparator.comparing(Song::getName));
    }

    public void sortbytedadpakhsh(List<Song> music){
        music.sort(Comparator.comparing(Song::getPakhsh));
    }*/

    public void setLikeplaylist(boolean likeplaylist) {
        this.likeplaylist = likeplaylist;
    }

    public void dislikeplaylist(){
        this.likeplaylist=false;
    }

    public void likedplaylist() {
        this.setLikeplaylist(true);
    }

    public void rename(String newName) {
        this.setName(newName);
    }

    public void shareWith(User user) {

    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        PlayList playList = (PlayList) o;
        return id == playList.id && likeplaylist == playList.likeplaylist && Objects.equals(name, playList.name) &&
                Objects.equals(user, playList.user) && Objects.equals(creationTime, playList.creationTime) &&
                Objects.equals(music, playList.music) && Objects.equals(artists, playList.artists);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, user, creationTime, likeplaylist, music, artists);
    }
}

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class PlayList {
    private int id; //String id
    private String name;
    private User user;
    private LocalTime creationTime;
    public boolean likeplaylist = false;
    private List<Song> music;
    private int count=0; //این واسه چیه؟
    private List<Artist> artists;
    private int count=0;

    public PlayList(int id, String name, User user, LocalTime creationTime) {
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

    public User getUser() {
        return user;
    }

    public LocalTime getCreationTime() {
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

    public void setCreationTime(LocalTime creationTime) {
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

    public PlayList filter(Filter filter){
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
    }

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

    public void deletePlayList(){

    }
}

public void rename(String newName) {
    this.name = newName;
}

public void delete() {
}
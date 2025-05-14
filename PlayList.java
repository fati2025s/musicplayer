import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

public class PlayList {
    private int id;
    private String name;
    private User user;
    private LocalTime creationTime;
    public boolean likeplaylist = false;
    private List<Song> music;
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

    public String getUser() {
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
    }

    public void removeSong(Song song) {
        music.remove(song);
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

    public List<Object> collectData(DataCollector collector){
        List<Object> data=new ArrayList<>();
        for(int i=0;i<music.size();i++){
            data.add(collector.get(music.get(i)));
        }
        return data;
    }

    public void setLikeplaylist(boolean likeplaylist) {
        this.likeplaylist = likeplaylist;
    }

    public void likedplaylist() {
        this.setLikeplaylist(true);
    }

    public void rename(String newName) {
        this.setName(newName);
    }

    public void shareWith(User user) {

    }

    public void deletList(){

    }
}

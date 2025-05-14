import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class Song {
    private int id;
    private String name;
    private String text;
    private Artist artist;
    private String album;
    private LocalTime time;
    private String icon;
    private String Qrcode;
    private boolean pause;
    private boolean liked;
    private int pakhsh=0;
    public List<Song> likedmusic= new ArrayList<>();

    public Song(int id, String name, Artist artist, String album, LocalTime time, String icon, String Qrcode) {
        this.id = id;
        this.name = name;
        this.artist = artist;
        this.album = album;
        this.time = time;
        this.icon = icon;
        this.Qrcode = Qrcode;
    }

    public String getIcon() {
        return icon;
    }

    public String getQrcode() {
        return Qrcode;
    }

    public int getPakhsh(){
        return pakhsh;
    }

    public void setPakhsh(int pakhsh) {
        this.pakhsh = pakhsh;
    }

    public void setPause(boolean pause) {
        this.pause = pause;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public void setQrcode(String qrcode) {
        Qrcode = qrcode;
    }

    public List<Song> getLikedmusic() {
        return likedmusic;
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

    public LocalTime getTime() {
        return time;
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

    public void setTime(LocalTime time) {
        this.time = time;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        Song song = (Song) o;
        return id == song.id && Objects.equals(name, song.name) && Objects.equals(text, song.text) && Objects.equals(artist, song.artist) && Objects.equals(album, song.album);
    }

    @Override
    public String toString() {
        return "[Name: " + name + ", Artist: " + artist + ", Album: " + album + "]";
    }

    public void play(){
        pakhsh++;

    }

    public void pause(){

    }

    public void next(){

    }

    public void previous(){

    }

    public void like(){
        likedmusic.add(this);
        this.setLiked(true);
    }

    public void unlike(){
        likedmusic.remove(this);
        this.setLiked(false);
    }

    public void share(){

    }

    public void delete(){

    }

    public void takAhang(){

    }

    public void random(){

    }
}

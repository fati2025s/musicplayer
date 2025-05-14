import java.util.List;

public class Admin extends User {

    public Admin(String id, String username, String email, String password) {
        super(id, username, email, password);
    }


    public void deleteUser(User user) {
    }

    public List<User> getAllUsers() {
    }

    public User findUserByUsername(String username) {
    }

    public void updateUserInfo(User user, String newUsername, String newEmail) {
    }


    public List<Playlist> getAllPlaylists() {
    }

    public void deletePlaylist(Playlist playlist) {
    }


    public List<Song> getAllSongs() {
    }

    public void deleteSong(Song song) {
    }

    public void updateSongInfo(Song song, String newTitle, String newArtist) {
    }


    public List<Song> getMostPlayedSongs() {
    }

    public List<Song> getMostLikedSongs() {
    }

    public List<Playlist> getUserPlaylists(User user) {
    }
}

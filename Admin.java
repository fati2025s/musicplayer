import java.util.List;

public class Admin extends User {

    public Admin(String id, String username, String email, String password) {
        super(id, username, email, password);
    }

    public void deleteUser(User user) {
    }

    public List<User> getAllUsers() {
        return null;
    }

    public User findUserByUsername(String username) {
        return null;
    }

    public List<Playlist> getAllPlaylists() {
        return null;
    }

    public void deletePlaylist(Playlist playlist) {
    }

    public List<Song> getAllSongs() {
        return null;
    }

    public void deleteSong(Song song) {
    }

    public List<Song> getMostPlayedSongs() {
        return null;
    }

    public List<Song> getMostLikedSongs() {
        return null;
    }

    public List<Playlist> getUserPlaylists(User user) {
        return user.getPlaylists();
    }
}

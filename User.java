import java.util.List;
import java.util.Map;

public class User {
	private String id;
	private String username;
	private String email;
	private String password;
	private String profilePicturePath;
	private List<Playlist> playlists;
	private List<Song> likedSongs;
	private List<Song> likedArtists;
	private Map<Song, Integer> Playcounts;

	public User(String id, String username, String email, String password) {
		this.id = id;
		this.username = username;
		this.email = email;
		this.password = password;
		this.profilePicturePath = null;
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public String getProfilePicturePath() {
		return profilePicturePath;
	}

	public void setProfilePicturePath(String profilePicturePath) {
		this.profilePicturePath = profilePicturePath;
	}

	public List<Playlist> getPlaylists() {
		return playlists;
	}

	public void setPlaylists(List<Playlist> playlists) {
		this.playlists = playlists;
	}

	public List<Song> getLikedSongs() {
		return likedSongs;
	}

	public void setLikedSongs(List<Song> likedSongs) {
		this.likedSongs = likedSongs;
	}

	public List<Song> getLikedArtists() {
		return likedArtists;
	}

	public void setLikedArtists(List<Song> likedArtists) {
		this.likedArtists = likedArtists;
	}

	public Map<Song, Integer> getPlaycount() {
		return Playcount;
	}

	public void setPlaycount(Map<Song, Integer> playcount) {
		Playcount = playcount;
	}

	public void login() {

	}

	public void logout() {

	}

	public void updateProfile(String newUsername, String newEmail) {

	}

	public void likeSong(Song song) {

	}

	public void addPlaylist(Playlist playlist) {

	}

	public void removePlaylist(Playlist playlist) {

	}

	public void changeProfilePicture(String newPath) {

	}
}

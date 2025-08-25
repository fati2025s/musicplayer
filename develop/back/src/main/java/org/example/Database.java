package org.example;

import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;

public class Database {
    private final Map<String, User> users = new ConcurrentHashMap<>();

    private static final String DB_FILE = "database.json";
    public static final String UPLOADS_ROOT = "uploads";

    private final Gson gson = new GsonBuilder().setPrettyPrinting().create();

    public static final AtomicInteger playlistIdGenerator = new AtomicInteger(1);
    public static final AtomicInteger songIdGenerator = new AtomicInteger(1);

    public Database() {
        loadFromFile();
    }

    private synchronized void saveToFile() {
        try (FileWriter writer = new FileWriter(DB_FILE)) {
            gson.toJson(users, writer);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public synchronized void loadFromFile() {
        try (FileReader reader = new FileReader(DB_FILE)) {
            Type type = new TypeToken<Map<String, User>>() {}.getType();
            Map<String, User> loaded = gson.fromJson(reader, type);
            if (loaded != null) {
                users.clear();
                users.putAll(loaded);
            }
        } catch (IOException e) {
            System.out.println("No existing DB file, starting fresh.");
        }
    }

    public boolean addUser(User user) {
        synchronized (users) {
            if (users.containsKey(user.getUsername())) {
                return false;
            }
            users.put(user.getUsername(), user);
            saveToFile();
            return true;
        }
    }

    public User findUserByUsernameAndPassword(String username, String password) {
        User u = users.get(username);
        if (u != null && u.getPassword().equals(password)) {
            return u;
        }
        return null;
    }

    public User findUserByUsername(String username) {
        return users.get(username);
    }

    public boolean updatePassword(User user, String oldPw, String newPw) {
        synchronized (user) {
            if (!user.getPassword().equals(oldPw)) return false;
            user.setPassword(newPw);
            saveToFile();
            return true;
        }
    }

    public synchronized boolean removeUser(User user) {
        if (user == null) return false;
        if (!users.containsKey(user.getUsername())) return false;
        users.remove(user.getUsername());
        saveToFile();
        return true;
    }

    public synchronized List<User> getAllUsers() {
        return new ArrayList<>(users.values());
    }

    public boolean addPlaylist(User user, Playlist playlist) {
    synchronized (user) {
        for (Playlist p : user.getPlaylists()) {
            if (p.getName().equalsIgnoreCase(playlist.getName())) {
                return false;
            }
        }

        playlist.setId(playlistIdGenerator.getAndIncrement());

        boolean isOwner = Objects.equals(playlist.getOwnerUsername(), user.getEmail());
        if (playlist.isShared() && !isOwner) {
            playlist.setReadOnly(true);
        } else if (isOwner) {
            playlist.setReadOnly(false);
        }

        user.getPlaylists().add(playlist);
        saveToFile();
        return true;
    }
}


    public boolean deletePlaylist(User user, int playlistId) {
        synchronized (user) {
            Iterator<Playlist> it = user.getPlaylists().iterator();
            while (it.hasNext()) {
                Playlist p = it.next();
                if (p.getId() == playlistId) {
                    it.remove();
                    saveToFile();
                    return true;
                }
            }
            return false;
        }
    }

    public Playlist findPlaylistById(User user, int playlistId) {
        synchronized (user) {
            for (Playlist p : user.getPlaylists()) {
                if (p.getId() == playlistId) return p;
            }
            return null;
        }
    }

    public Playlist findPlaylistByName(User user, String name) {
        synchronized (user) {
            for (Playlist p : user.getPlaylists()) {
                if (p.getName().equals(name)) return p;
            }
            return null;
        }
    }

    public boolean addSongToPlaylist(User user, int playlistId, Song song) {
    synchronized (user) {
        Playlist p = findPlaylistById(user, playlistId);
        if (p == null) return false;

        if (p.isReadOnly() || !Objects.equals(p.getOwnerUsername(), user.getEmail())) return false;

        song.setId(songIdGenerator.getAndIncrement());
        p.addSong(song);
        saveToFile();
        return true;
    }
}

    public boolean removeSongFromPlaylist(User user, int playlistId, int songId) {
    synchronized (user) {
        Playlist p = findPlaylistById(user, playlistId);
        if (p == null) return false;

        if (p.isReadOnly() || !Objects.equals(p.getOwnerUsername(), user.getEmail())) return false;

        Song toRemove = p.getSongs().stream()
                .filter(s -> s.getId() == songId)
                .findFirst()
                .orElse(null);
        if (toRemove == null) return false;

        p.removeSong(toRemove);
        saveToFile();
        return true;
    }
}

    public synchronized boolean removePlaylist(User user, Playlist playlist) {
        if (user == null || playlist == null) return false;
        boolean removed = user.getPlaylists().removeIf(p -> p.getId() == playlist.getId());
        if (removed) saveToFile();
        return removed;
    }

    public boolean addSong(User user, Song song) {
        synchronized (user) {
            for (Song s : user.getSongs()) {
                if (s.getName().equals(song.getName())) {
                    return false;
                }
            }
            song.setId(songIdGenerator.getAndIncrement());
            user.getSongs().add(song);
            saveToFile();
            return true;
        }
    }

    public boolean deleteSong(User user, int songId) {
        synchronized (user) {
            boolean removed = user.getSongs().removeIf(s -> s.getId() == songId);
            if (removed) saveToFile();
            return removed;
        }
    }

    public Song findSongById(User user, int songId) {
        synchronized (user) {
            for (Song s : user.getSongs()) {
                if (s.getId() == songId) return s;
            }
            return null;
        }
    }

    public Song findSongByName(User user, String name) {
        synchronized (user) {
            for (Song s : user.getSongs()) {
                if (s.getName().equals(name)) return s;
            }
            return null;
        }
    }

    public List<Song> getSongs(User user) {
        synchronized (user) {
            return new ArrayList<>(user.getSongs());
        }
    }

    public synchronized boolean removeSong(User user, Song song) {
        if (user == null || song == null) return false;
        boolean removed = user.getSongs().removeIf(s -> s.getId() == song.getId());
        if (removed) saveToFile();
        return removed;
    }


    public synchronized List<Song> adminListSongs() {
        List<Song> all = new ArrayList<>();
        for (User u : users.values()) {
            all.addAll(u.getSongs());
        }
        return all;
    }

public User findUserByEmail(String email) {
    synchronized (users) {
        return users.values().stream()
                .filter(u -> u.getEmail().equals(email))
                .findFirst()
                .orElse(null);
    }
}

public boolean updateUser(User user) {
    if (user == null) return false;
    synchronized (users) {
        if (!users.containsKey(user.getUsername())) return false;
        users.put(user.getUsername(), user);
        saveToFile();
        return true;
    }
}

public boolean logoutUser(User user) {
    return user != null;
}

public boolean renamePlaylist(User user, int playlistId, String newName) {
    synchronized (user) {
        Playlist pl = findPlaylistById(user, playlistId);
        if (pl == null) return false;

        for (Playlist p : user.getPlaylists()) {
            if (p.getName().equals(newName)) return false;
        }
        pl.setName(newName);
        saveToFile();
        return true;
    }
}

public List<Playlist> getPlaylists(User user) {
    synchronized (user) {
        return new ArrayList<>(user.getPlaylists());
    }
}

public List<Song> getAllSongs() {
    List<Song> all = new ArrayList<>();
    synchronized (users) {
        for (User u : users.values()) {
            all.addAll(u.getSongs());
        }
    }
    return all;
}

public List<Song> getAllSongsSortedByLikes() {
    List<Song> all = getAllSongs();
    all.sort(Comparator.comparingInt(Song::getLikeCount).reversed());
    return all;
}

public boolean adminDeleteSong(int songId) {
    synchronized (users) {
        boolean removed = false;
        for (User u : users.values()) {
            removed |= u.getSongs().removeIf(s -> s.getId() == songId);
        }
        if (removed) saveToFile();
        return removed;
    }
}

}

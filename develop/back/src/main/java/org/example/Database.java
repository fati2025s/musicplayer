package org.example;

import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;

public class Database {
    private final Map<String, User> users = new ConcurrentHashMap<>();
     private static final String DB_FILE = "database.json";
     public static final String UPLOADS_ROOT = "uploads";
    private final Gson gson = new GsonBuilder().setPrettyPrinting().create();

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

   public boolean addPlaylist(User user, Playlist playlist) {
    synchronized (user) {
        List<Playlist> playlists = user.getPlaylists();
        for (Playlist p : playlists) {
            if (p.getName().equals(playlist.getName()) &&
                Objects.equals(p.getOwner(), user)) {
                return false;
            }
        }

        playlist.setReadOnly(!Objects.equals(playlist.getOwner(), user));

        playlists.add(playlist);

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

        if (!p.canUserEdit(user)) {
            return false;
        }

        p.addSong(song);
        saveToFile();
        return true;
    }
}

public boolean removeSongFromPlaylist(User user, int playlistId, int songId) {
    synchronized (user) {
        Playlist p = findPlaylistById(user, playlistId);
        if (p == null) return false;

        if (!p.canUserEdit(user)) {
            return false;
        }

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


   public boolean addSong(User user, Song song) {
    synchronized (user) {
        for (Song s : user.getSongs()) {
            if (s.getName().equals(song.getName())) {
                return false;
            }
        }
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

public synchronized boolean removePlaylist(User user, Playlist playlist) {
    if (user == null || playlist == null) return false;
    boolean removed = user.getPlaylists().removeIf(p -> p.getId() == playlist.getId());
    if (removed) saveToFile();
    return removed;
}

public synchronized boolean removeSong(User user, Song song) {
    if (user == null || song == null) return false;
    boolean removed = user.getSongs().removeIf(s -> s.getId() == song.getId());
    if (removed) saveToFile();
    return removed;
}

}

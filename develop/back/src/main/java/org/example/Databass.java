package org.example;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.io.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class Databass {
    List<User> users;
    Gson gson = new Gson();

    public Databass() {
        try {
            File file = new File("user.json");

            if (!file.exists()) {
                file.createNewFile();
                FileWriter fw = new FileWriter(file);
                BufferedWriter bw = new BufferedWriter(fw);
                bw.write("[]");
                bw.close();
                fw.close();
            }
            FileReader fileReader = new FileReader(file);
            BufferedReader reader = new BufferedReader(fileReader);
            User[] userArray = gson.fromJson(reader, User[].class);
            if (userArray == null) {
                users = new ArrayList<>();
            } else {
                users = new ArrayList<>(Arrays.asList(userArray));
            }
            reader.close();
            fileReader.close();
        } catch (IOException e) {
            e.printStackTrace();
            users = new ArrayList<>();
        }
    }

    public int count() {
        return users.size();
    }

    public void write(List<User> users) {
        try {
            FileWriter fileWriter = new FileWriter("user.json", false);
            BufferedWriter bufferedWriter = new BufferedWriter(fileWriter);
            Gson gsonPretty = new GsonBuilder().setPrettyPrinting().create();
            gsonPretty.toJson(users, bufferedWriter);

            bufferedWriter.close();
            fileWriter.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public boolean exitingUser(User username) {
        for (User user : users) {
            if (user.getUsername().equals(username.getUsername())) {
                return true;
            }
        }
        return false;
    }

    public boolean empty() {
        return users.isEmpty();
    }

    public void addUser(User user) {
        users.add(user);
        write(users);
        System.out.println(users.size());
    }

    public void changePassword(User user, User password) {
        user.setPassword(password.getPassword());
        write(users);
    }

    public boolean exitingUserL(String username, String password) {
        for (User user : users) {
            if (user.getUsername().equals(username)) {
                if (user.getPassword().equals(password))
                    return true;
            }
        }
        return false;
    }

    public boolean vojodmusic(Song song, User user) {
        for (User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                if (user1.getSongs() == null) {
                    user1.setSongs(new ArrayList<>());
                }
                if (user1.getSongs().isEmpty()) {
                    return false;
                }
                return user1.getSongs().contains(song);
            }
        }
        return false;
    }

    public void addmusic(Song song, User user) {
        for (User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                user1.getSongs().add(song);
                break;
            }
        }
        write(users);
    }

    public void removemusic(Song song, User user) {
        for (User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                user1.getSongs().remove(song);
                write(users);
                break;
            }
        }
    }

    public boolean vojodplay(PlayList play, User user) {
        for (User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                if (user1.getPlaylists() == null) {
                    user1.setPlaylists(new ArrayList<>());
                }
                if (user1.getPlaylists().isEmpty()) {
                    return false;
                }
                return user1.getPlaylists().contains(play);
            }
        }
        return false;
    }

    public void addplaylist(PlayList playlist, User user) {
        for (User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                user1.getPlaylists().add(playlist);
                write(users);
                break;
            }
        }
    }

    public void removplaylist(PlayList playlist, User user) {
        for (User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                user1.getPlaylists().remove(playlist);
                write(users);
                break;
            }
        }
    }

    public void addprofile(String filePath, User user) {
        user.getProfilePicturePaths().add(filePath);
        write(users);
    }

    public void removeprofile(String filePath, User user) {
        user.getProfilePicturePaths().remove(filePath);
        write(users);
    }
    public User findUserById(String id) {
    for (User user : users) {
        if (user.getId().equals(id)) {
            return user;
        }
    }
    return null;
}

}


package org.example;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonObject;
import com.google.gson.internal.bind.util.ISO8601Utils;
import com.sun.xml.internal.ws.policy.privateutil.PolicyUtils;
import sun.java2d.cmm.Profile;

import java.io.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class Databass {
    List<User> users;
    Gson gson = new Gson();

    public Databass() {
        try{
            File file = new File("data.json");

            if(!file.exists()){
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
            users = new ArrayList<>( Arrays.asList(userArray));
            reader.close();
            fileReader.close();
        }
        catch (IOException e){
            e.printStackTrace();
        }
    }

    public int count(){
        return users.size();
    }

    public void write(List<User> users) {
        try {
            FileWriter fileWriter = new FileWriter("data.json",false);
            BufferedWriter bufferedWriter = new BufferedWriter(fileWriter);
            Gson gsonPretty = new GsonBuilder().setPrettyPrinting().create();
            gsonPretty.toJson(users, bufferedWriter);

            bufferedWriter.close();
            fileWriter.close();
        }
        catch (IOException e){
            e.printStackTrace();
        }
    }

    //public void addwrite()

    public boolean exitingUser(User username) {
        for (User user : users) {
            if (user.getUsername().equals(username.getUsername())) {
                return true;
            }
        }
        return false;
    }

    public boolean empty(){
        if(users.isEmpty()){
            return true;
        }
        return false;
    }

    public void deletuser(User user) {
        for (User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                users.remove(user1);
                write(users);
                break;
            }
        }
    }

    public User findUserByUsername(String username) {
        for (User user : users) {
            if (user.getUsername().equals(username)) {
                return user;
            }
        }
        return null;
    }

    public List<User> getusers() {
        return users;
    }

    public void addUser(User user) {
        users.add(user);
        System.out.println(users.size());
        write(users);
    }

    public void changePassword(User user, User password) {
        user.setPassword(password.getPassword());
        write(users);
    }

    public void changeUsername(User user, User username) {
        user.setUsername(username.getUsername());
        write(users);
    }

    public boolean exitingUserL(String username,String password) {
        for (User user : users) {
            if (user.getUsername().equals(username)) {
                if (user.getPassword().equals(password))
                    return true;
            }
        }
        return false;
    }

    public boolean vojodmusic(Song song,User user) {
        for (User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                if(user1.getSongs() == null) {
                    user1.setSongs(new ArrayList<>());
                }
                if(user1.getSongs().isEmpty()){
                    return false;
                }
                if(user1.getSongs().contains(song)) {
                    return true;
                }
                return false;
            }
        }
        return false;
    }

    public void addmusic(Song song,User user) {
        for(User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                user1.getSongs().add(song);
                write(users);
                break;
            }
        }
    }

    public Song fingmusicid(User user,int id) {
        for (User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                for(Song song : user1.getSongs()) {
                    if(song.getId() == id) {
                        return song;
                    }
                }
            }
        }
        return null;
    }

    public boolean toggleLike(User user, int musicId) {
        Song song = fingmusicid(user,musicId);
        for (User u : users) {
            if (u.getUsername().equals(user.getUsername())) {
                if (u.getLikedSongs() == null) {
                    u.setLikedSongs(new ArrayList<>());
                }
                if (song != null) {
                    u.getLikedSongs().remove(song); // unlike
                } else {
                    u.getLikedSongs().add(song); // like
                }

                write(users);
                return true;
            }
        }
        return false;
    }


    public void removemusic(Song song,User user) {
        for(User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                user1.getSongs().remove(song);
                write(users);
                break;
            }
        }
    }

    public boolean vojodplay(PlayList play,User user) {
        for(User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                if(user1.getPlaylists() == null) {
                    user1.setPlaylists(new ArrayList<>());
                }
                if(user1.getPlaylists().isEmpty()){
                    return false;
                }
                if(user1.getPlaylists().contains(play)) {
                    return true;
                }
            }
        }
        return false;
    }

    public void addplaylist(PlayList playlist,User user) {
        for(User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                user1.getPlaylists().add(playlist);
                user1.setPlaylists(user1.getPlaylists());
                write(users);
                break;
            }
        }
    }

    public void removplaylist(PlayList playlist,User user) {
        for(User user1 : users) {
            if (user1.getUsername().equals(user.getUsername())) {
                user1.getPlaylists().remove(playlist);
                write(users);
                break;
            }
        }
    }

    public synchronized boolean addProfilePath(String filePath, User user) {
        for (User u : users) {
            if (u.getUsername().equals(user.getUsername())) {
                if (u.getProfilePicturePath() == null) u.setProfilePicturePath(new ArrayList<>());
                if (!u.getProfilePicturePath().contains(filePath)) {
                    u.getProfilePicturePath().add(filePath);
                    if (u.getCurrentProfileIndex() == null || u.getCurrentProfileIndex() < 0) {
                        u.setCurrentProfileIndex(u.getProfilePicturePath().size() - 1);
                    }
                    write(users);
                }
                return true;
            }
        }
        return false;
    }

    public synchronized boolean removeProfilePath(String filePath, User user) {
        for (User u : users) {
            if (u.getUsername().equals(user.getUsername())) {
                if (u.getProfilePicturePath() == null) u.setProfilePicturePath(new ArrayList<>());
                boolean removed = u.getProfilePicturePath().remove(filePath);
                if (removed) {
                    if (u.getCurrentProfileIndex() != null) {
                        if (u.getProfilePicturePath().isEmpty()) {
                            u.setCurrentProfileIndex(-1);
                        } else if (u.getCurrentProfileIndex() >= u.getProfilePicturePath().size()) {
                            u.setCurrentProfileIndex(u.getProfilePicturePath().size() - 1);
                        }
                    }
                    write(users);
                }
                return removed;
            }
        }
        return false;
    }

    public synchronized boolean setCurrentProfileIndex(User user, int index) {
        for (User u : users) {
            if (u.getUsername().equals(user.getUsername())) {
                if (u.getProfilePicturePath() == null || u.getProfilePicturePath().isEmpty())
                    return false;
                if (index < 0 || index >= u.getProfilePicturePath().size())
                    return false;
                u.setCurrentProfileIndex(index);
                write(users);
                return true;
            }
        }
        return false;
    }
}
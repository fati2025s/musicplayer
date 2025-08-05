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
            File file = new File("user.json");

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
            FileWriter fileWriter = new FileWriter("user.json",false);
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

    public void addUser(User user) {
        users.add(user);
        write(users);
        System.out.println(users.size());
    }

    public void changePassword(User user, User password) {
        user.setPassword(password.getPassword());
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
        //System.out.println(users.size());
        //System.out.println(user.getSongs().size());
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
                break;
            }
        }
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

    public void addprofile(File file, User user) {
        user.getProfilePicturePath().add(file);
        write(users);
    }

    public void removeprofile(File file, User user) {
        user.getProfilePicturePath().remove(file);
        write(users);
    }
}

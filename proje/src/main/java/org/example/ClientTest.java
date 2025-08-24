/*package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.io.*;
import java.net.Socket;

public class ClientTest {
    public static void main(String[] args) {
        try (
                Socket socket = new Socket("localhost", 8080);
                BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()))
        ){
            Gson gson = new Gson();
            User user=new User("1","Ali","lkjdf@gmail.com","qwert");
            User user2=new User("2","Alia","lkdf@gmail.com","1wert");
            User user3=new User("3","Alix","lkj25f@gmail.com","qw5rt");
            //User user1 = new User("2","Amin","salammmm@gmail.com","123456");
            //Song song = new Song(1,"sarasara",new Artist("aidin"),"turkmusic");
            PlayList playList = new PlayList(1,"aval",user);
            PlayList playList1 = new PlayList(2,"saaval",user2);

            JsonElement jsonElement = gson.toJsonTree(user);
            JsonObject jsonObject = jsonElement.getAsJsonObject();

            JsonElement jsonElement1 = gson.toJsonTree(user2);
            JsonObject jsonObject1 = jsonElement1.getAsJsonObject();

            JsonElement jsonElement2 = gson.toJsonTree(user3);
            JsonObject jsonObject2 = jsonElement2.getAsJsonObject();

            JsonElement jsonElement3 = gson.toJsonTree(playList);
            JsonObject jsonObject3 = jsonElement3.getAsJsonObject();

            JsonElement jsonElement4 = gson.toJsonTree(playList1);
            JsonObject jsonObject4 = jsonElement4.getAsJsonObject();

            Request message = new Request("register", jsonObject);
            Request message2 = new Request("register", jsonObject1);
            Request message3 = new Request("register", jsonObject2);
            //Request message4 = new Request("login", jsonObject1);
            //Request message1 = new Request("addsong", jsonObject2);
            //Request message2 = new Request("deletesong", jsonObject2);
            Request message5 = new Request("addPlaylist", jsonObject3);
            Request message6 = new Request("addPlaylist", jsonObject4);

            String json = gson.toJson(message);
            writer.write(json);
            writer.newLine();
            writer.flush();

            String jsonMessage = gson.toJson(message2);
            writer.write(jsonMessage);
            writer.newLine();
            writer.flush();

            String jsonMessage2 = gson.toJson(message3);
            writer.write(jsonMessage2);
            writer.newLine();
            writer.flush();

            String jsonMessage3 = gson.toJson(message4);
            writer.write(jsonMessage3);
            writer.newLine();
            writer.flush();

            String jsonMessage4 = gson.toJson(message5);
            writer.write(jsonMessage4);
            writer.newLine();
            writer.flush();

            String jsonMessage5 = gson.toJson(message6);
            writer.write(jsonMessage5);
            writer.newLine();
            writer.flush();

            String response1 = reader.readLine();
            System.out.println(response1);

            String response2 = reader.readLine();
            System.out.println(response2);

            String response = reader.readLine();
            System.out.println(response);

            String response3 = reader.readLine();
            System.out.println(response3);

            String response4 = reader.readLine();
            System.out.println(response4);

            String response5 = reader.readLine();
            System.out.println(response5);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}*/
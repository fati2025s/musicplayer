package org.example;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.io.*;
import java.net.Socket;

/*public class ClientTest {
    public static void main(String[] args) {
        try (
                Socket socket = new Socket("localhost", 8080);
                BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()))
        ){
            Gson gson = new Gson();
            User user=new User("1","Ali","lkjdf@gmail.com","qwert");
            User user1 = new User("2","Amin","salammmm@gmail.com","123456");
            Song song = new Song(1,"sarasara",new Artist("aidin"),"turkmusic");

            JsonElement jsonElement = gson.toJsonTree(user);
            JsonObject jsonObject = jsonElement.getAsJsonObject();

            JsonElement jsonElement1 = gson.toJsonTree(user1);
            JsonObject jsonObject1 = jsonElement1.getAsJsonObject();

            JsonElement jsonElement2 = gson.toJsonTree(song);
            JsonObject jsonObject2 = jsonElement2.getAsJsonObject();

            //Request message = new Request("register", jsonObject);
            Request message3 = new Request("login", jsonObject);
            Request message1 = new Request("addsong", jsonObject2);
            Request message2 = new Request("deletesong", jsonObject2);

            String json = gson.toJson(message3);
            writer.write(json);
            writer.newLine();
            writer.flush();

            String jsonMessage = gson.toJson(message1);
            writer.write(jsonMessage);
            writer.newLine();
            writer.flush();

            String jsonMessage2 = gson.toJson(message2);
            writer.write(jsonMessage2);
            writer.newLine();
            writer.flush();

            String response1 = reader.readLine();
            System.out.println(response1);

            String response2 = reader.readLine();
            System.out.println(response2);

            String response = reader.readLine();
            System.out.println(response);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
*/
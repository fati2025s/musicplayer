package org.example;

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
            JsonElement jsonElement = gson.toJsonTree(user);
            JsonObject jsonObject = jsonElement.getAsJsonObject();

            Request message = new Request("register", jsonObject);

            String jsonMessage = gson.toJson(message);
            writer.write(jsonMessage);
            writer.newLine();
            writer.flush();

            String response = reader.readLine();
            System.out.println(response);


        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

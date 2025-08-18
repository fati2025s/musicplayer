package org.example;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

public class Server {
    public void start() {
        try (ServerSocket serverSocket = new ServerSocket(8080)) {
            System.out.println(" Server started on port 8080");
            while (true) {
                Socket socket = serverSocket.accept();
                System.out.println("📡 Client connected");
                new ClientHandler(socket).start();
            }
        } catch (IOException e) {
            System.out.println(" Server error");
            e.printStackTrace();
        }
    }
}

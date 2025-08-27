package org.example;

public class Main {
    public static void main(String[] args) {
         Database db = new Database();
 Admin admin = new Admin(db);
 AdminPanel panel = new AdminPanel(admin);
 panel.start();
    }
}



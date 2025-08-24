package org.example;

public class RunAdmin {
    public static void main(String[] args) {
        Admin admin = new Admin("1", "admin", "admin@example.com", "1234");
        AdminPanel panel = new AdminPanel(admin);
    }
}

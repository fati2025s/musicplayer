package org.example;

import java.util.Scanner;

public class AdminPanel {

    private Admin admin;

    public AdminPanel(Admin admin) {
        this.admin = admin;
    }

    public void start() {
        try (Scanner sc = new Scanner(System.in)) {
            while (true) {
                System.out.println("\n--- @Admin Panel@ ---");
                System.out.println("1. Show all users");
                System.out.println("2. Search user by username");
                System.out.println("3. Delete user");
                System.out.println("4. Show all songs");
                System.out.println("5. Delete song");
                System.out.println("6. Show top 20 most liked songs");
                System.out.println("7. Exit");
                System.out.print("Choose an option (CAREFULLY!): ");

                int choice = sc.nextInt();
                sc.nextLine();

                switch (choice) {
                    case 1:
                        admin.getAllUsers().forEach(u ->
                            System.out.println(u.getId() + " | " + u.getUsername())
                        );
                        break;

                    case 2:
                        System.out.print("Enter username: ");
                        String uname = sc.nextLine();
                        System.out.println(admin.getUserInfo(uname));
                        break;

                    case 3:
                        System.out.print("Enter username to delete: ");
                        String unameToDelete = sc.nextLine();
                        boolean userRemoved = admin.deleteUser(unameToDelete);
                        System.out.println(userRemoved ? "User deleted successfully." : "User not found!");
                        break;

                    case 4:
                        admin.getAllSongs().forEach(song ->
                            System.out.println(song.getId() + " | " + song.getName())
                        );
                        break;

                    case 5:
                        System.out.print("Enter song ID to delete: ");
                        int songId = sc.nextInt();
                        boolean songRemoved = admin.deleteSong(songId);
                        System.out.println(songRemoved ? "Song deleted successfully." : "Song not found!");
                        break;

                    case 6:
                        admin.getTop20MostLikedSongs().forEach(song ->
                            System.out.println(song.getId() + " | " + song.getName() +
                                               " (Likes: " + song.getLikeCount() + ")")
                        );
                        break;

                    case 7:
                        System.out.println("Exiting admin panel...");
                        return;

                    default:
                        System.out.println("Invalid option! Please try again.");
                }
            }
        }
    }
}

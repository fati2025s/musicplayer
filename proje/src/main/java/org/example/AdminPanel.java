package org.example;

import java.util.Scanner;

public class AdminPanel {

    private Admin admin;

    public AdminPanel(Admin admin) {
        this.admin = admin;
    }

    public void start() {
        Scanner sc = new Scanner(System.in);
        while (true) {
            System.out.println("\n--- پنل مدیریت ---");
            System.out.println("1. نمایش همه کاربران");
            System.out.println("2. جستجوی کاربر با نام");
            System.out.println("3. نمایش همه پلی‌لیست‌ها");
            System.out.println("4. نمایش همه آهنگ‌ها");
            System.out.println("5. نمایش محبوب‌ترین آهنگ‌ها");
            System.out.println("6. خروج");
            System.out.print("انتخاب کنید: ");

            int choice = sc.nextInt();
            sc.nextLine();

            switch (choice) {
                case 1:
                    admin.getusers().forEach(u -> System.out.println(u.getUsername()));
                    break;
                case 2:
                    System.out.print("نام کاربر: ");
                    String uname = sc.nextLine();
                    User u = admin.findUserByUsername(uname);
                    System.out.println(u != null ? u : "کاربر پیدا نشد");
                    break;
                case 3:
                    admin.getAllPlaylists().forEach(System.out::println);
                    break;
                case 4:
                    admin.getAllSongs().forEach(System.out::println);
                    break;
                case 5:
                    admin.getMostLikedSongs().forEach(System.out::println);
                    break;
                case 6:
                    return;
                default:
                    System.out.println("گزینه نامعتبر!");
            }

        }
    }
}
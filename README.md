
# LocalLink

**Privacy-First Android Device Management Suite**

LocalLink is a powerful, cross-platform ecosystem that bridges the gap between your Android device and your PC without relying on the internet or third-party cloud servers. By embedding a high-performance HTTP server directly within the Android application, LocalLink allows you to browse files, stream media, and manage contacts directly from any web browser on the same Wi-Fi network.

## 🚀 Key Features

* **Zero Internet Required:** Works entirely over your local Wi-Fi network (LAN). No data leaves your room.
* **Universal Web Client:** Access your phone from Chrome, Firefox, Safari, or Edge on any OS (Windows, MacOS, Linux).
* **High-Speed File Transfer:** Upload and download files at local network speeds (often 10x faster than cloud).
* **Media Streaming:** Stream HD videos and music stored on your phone directly to your PC browser without downloading them first.
* **Contact Management:** View, search, and export your Android contacts list to JSON.
* **Hybrid Architecture:**
    * **Integrated Mode:** The web client is embedded in the Android app for instant "plug-and-play" access.
    * **Split Mode:** Run the web client separately on your PC for faster development or poor network conditions.

## 🛠️ Technology Stack

LocalLink is built using a modern, reactive architecture:

* **Mobile (Host):** Flutter (Android)
* **Web (Client):** Flutter Web
* **Backend:** Dart `shelf` (Embedded HTTP Server)
* **State Management:** Riverpod
* **Protocol:** REST API over HTTP/1.1

## 📦 Architecture Overview

LocalLink uses a unique **Embedded Server Pattern**. The Android app does not just communicate with a server; it *is* the server.

1.  **The Host:** The Android app spins up a Dart `HttpServer` on port `8080`.
2.  **The Asset Pipeline:** The Flutter Web client is compiled and bundled directly into the Android APK's assets.
3.  **The Bridge:** When you type the phone's IP into a browser, the Android app serves the web interface and handles API requests for files and data.

## 📸 Screenshots


| Connection Screen |
|:---------:|
| <img width="1920" height="990" alt="welcome_screen" src="https://github.com/user-attachments/assets/39f7f5df-5b2e-49c7-a23d-d0e79392c455" /> |


| Dashboard |
|:---------:|
| <img width="1916" height="1080" alt="dashborad" src="https://github.com/user-attachments/assets/e48b8632-232d-4c49-a317-67ebfaa42937" /> |

| Device Info |
|:---------:|
| <img width="1896" height="1080" alt="device info" src="https://github.com/user-attachments/assets/98ae523b-5dd4-41a8-9a41-8a0830dd1106" /> |

| Files |
|:---------:|
| <img width="1919" height="1078" alt="filemanager" src="https://github.com/user-attachments/assets/568ac2f4-426a-497f-8a8d-04672b8f8664" /> | 

| Images and Videos |
|:---------:|
| <img width="1920" height="973" alt="media" src="https://github.com/user-attachments/assets/5e5063c9-1c2f-4ab5-b4db-fdd0d9ea17d9" /> |

| Audio and Contacts |
|:---------:|
| <img width="1917" height="1070" alt="contacts" src="https://github.com/user-attachments/assets/0515adc9-cee1-4b12-a07c-494e9c992b2c" /> |


## Note

LocalLink follows a dual architecture it has a web app inside the web_client directory which is integrated into mobile app in mobile_app directory.
Both are build separately and than intergrated into the mobile app apk.


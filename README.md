# 🕵️‍♂️ ReClaim - Lost & Found Mobile Application  

**Khuje Pai** (meaning "Found" in Bangla) is a community-driven mobile application designed to simplify the process of reporting and finding lost or found items. Built with **Flutter** and **Firebase**, this app empowers users to connect, collaborate, and contribute to their community by sharing and recovering lost belongings.

## 🚀 Features  

### 🏠 **Home Page**  
- Displays a consolidated feed of the latest lost and found posts.  
- Navigate seamlessly between **Home**,  **My Posts**, **Create Post**, and **Profile** tabs.  

### 🔍 **Lost & Found Sections**   
- Basically the **Home** Page is the main newsfeed of the app where all the Lost/Found posts are shown.
- There is option for **Searching** in the **Home** Page.

### ✍️ **Post Creation and Management**  
- Add new posts with the following details:  
  - 📷 **Image**: Upload from the gallery, take a photo, or use an image URL.  
  - 📝 **Caption**: Provide a description of the item.  
  - 📍 **Location**: Specify where the item was lost/found.  
- View, edit, or delete your posts.  

### 👤 **User Profile**  
- Displays user information: Name, Email, Phone Number, and Profile Picture.  
- Update your profile details through simple dialogs.  

### 🔐 **Authentication**  
- Secure registration and login powered by Firebase Authentication.  
- Logout functionality to switch accounts.  

### 🌐 **Real-Time Updates**  
- Real-time data fetching and synchronization with Firebase Firestore.  

---

## 📱 App Workflow  

Here’s a high-level diagram of the app’s workflow:  

## 🛠️ Tech Stack  

| Technology      | Description                              |  
|------------------|------------------------------------------|  
| **Flutter**     | Frontend framework for building UIs.     |  
| **Firebase**    | Backend services for authentication and data storage. |  
| **Firestore**   | Database for storing posts and user data. |  
| **Cloudinary**  | For storing profile pics and Post photos  |

---

## 🧑‍💻 Getting Started  

Follow these steps to get a local copy of the project up and running:  

### 1️⃣ Clone the Repository  
```bash
git clone https://github.com/Hasib-39/khuje_pai.git
cd khuje_pai
```  

### 2️⃣ Install Dependencies  
Ensure Flutter is installed and configured. Run:  
```bash
flutter pub get
```  

### 3️⃣ Firebase Setup  
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).  
2. Add an Android/iOS app and download the configuration files:  
   - `google-services.json` (for Android).  
   - `GoogleService-Info.plist` (for iOS).  
3. Place these files in the respective directories:  
   - `android/app/` (for `google-services.json`).  
   - `ios/Runner/` (for `GoogleService-Info.plist`).  
4. Enable Firestore and Firebase Authentication.  

### 4️⃣ Run the Application  
Launch the app on an emulator or connected device:  
```bash
flutter run
```  

---

## 📂 Directory Structure  

```plaintext
khuje_pai/
├── android/               # Android-specific configurations  
├── ios/                   # iOS-specific configurations  
├── lib/                   # Main Flutter codebase  
│   ├── models/            # Data models  
│   ├── screens/           # UI screens  
│   ├── controllers/       # State management and controllers  
│   ├── widgets/           # Reusable UI components  
├── assets/                # Static assets like images and icons  
└── pubspec.yaml           # Project dependencies and metadata  
```  

---

## 👥 Contribution Guidelines  

We welcome contributions! Here's how you can contribute:  
1. Fork the repository.  
2. Create a new branch for your feature/bugfix:  
   ```bash
   git checkout -b feature-name
   ```  
3. Commit your changes:  
   ```bash
   git commit -m "Add detailed feature"
   ```  
4. Push the branch:  
   ```bash
   git push origin feature-name
   ```  
5. Open a Pull Request.  

---

## 📝 License  

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.  

---

## 🙌 Acknowledgements  

Thanks to everyone contributing to and using **Khuje Pai**. Together, let’s make finding lost items more efficient and community-driven!  

---

## 📧 Contact  

For any queries or collaboration opportunities, feel free to reach out:  

**Hasib Altaf**  
📧 Email: [hasibaltaf2839@gmail.com](mailto:hasibaltaf2839@gmail.com)  
```  

This version is more professional, with added diagrams and clear sections, making it easier for users and contributors to understand and navigate the project. Let me know if you’d like to tweak or add more details!

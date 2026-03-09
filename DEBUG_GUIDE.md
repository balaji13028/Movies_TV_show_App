# Debugging Guide for Media9 App

We have configured separate flavors for Mobile and TV so that you can easily debug the app without manually passing terminal arguments each time.

## Visual Studio Code / Cursor Debugging

We've added a `launch.json` configuration file inside the `.vscode` directory. This allows you to launch the respective flavors directly from the Run/Debug panel in your IDE.

### How to use:
1. Open the **Run and Debug** view in VS Code/Cursor (`Ctrl+Shift+D` on Windows or `Cmd+Shift+D` on Mac).
2. At the top of the panel, you will see a dropdown menu. You can select one of the following profiles:
   - **`media9 (Mobile)`**: Runs the app using `lib/main_mobile.dart`. This ensures the app always behaves as a mobile application.
   - **`media9 (TV)`**: Runs the app using `lib/main_tv.dart`. This forces the app to behave as an Android TV application.
   - **`media9 (Default)`**: Runs the default `lib/main.dart` with runtime device checking.
3. Select your preferred physical device or emulator from the device selector at the bottom-right corner of the window.
4. Click the green "Play" button (or press `F5`) next to the dropdown to start debugging.

## Android Studio Debugging

If you prefer using Android Studio, you can set up Run Configurations through its UI:
1. At the top toolbar (near the green play button), click on the current run configuration dropdown (it usually says `main.dart`).
2. Select **Edit Configurations...**
3. Click the `+` button in the top left corner to add a new **Flutter** configuration.
4. Set the **Name** to `media9 (Mobile)`, set the **Dart entrypoint** to your absolute path ending in `lib/main_mobile.dart`, and importantly, set the **Build flavor** to `mobile`.
5. Repeat steps 3 and 4 to create another configuration for `media9 (TV)` pointing to `lib/main_tv.dart` with the **Build flavor** set to `tv`.
6. Click **Apply** and **OK**. Now you can select these configurations from the dropdown and hit Run/Debug directly.


# Brave Browser

## Profiles: create a profile from another

Duplicating a Brave browser profile on Linux involves copying specific profile data from your existing profile to a new one. This allows you to have a new profile that mirrors your current settings and extensions. Below is a step-by-step guide to achieve this safely.

---

**Important Note:**

- **Backup Your Data:**  Before proceeding, it's highly recommended to back up your Brave browser data to prevent any potential loss.

- **Proceed with Caution:**  Manipulating browser profile files can lead to data corruption if not done carefully.

---

**Step-by-Step Guide** **1. Close Brave Browser Completely**
Ensure that all instances of Brave Browser are closed to prevent any file conflicts.
**2. Open Terminal** Press `Ctrl + Alt + T` to open the terminal.**3. Navigate to Brave's User Data Directory** Brave stores user data in `~/.config/BraveSoftware/Brave-Browser/`. Navigate to this directory by running:

```Copy code
cd ~/.config/BraveSoftware/Brave-Browser/
```
**4. Backup the Brave-Browser Directory (Highly Recommended)**
Create a backup of your current profiles:

```Copy code
cp -r Brave-Browser Brave-Browser-backup
```
**5. Identify Your Current Profile Directory**
List the contents to see existing profiles:


```Copy code
ls
```

You should see directories like:

- `Default` (main profile)
- `Profile 1`
- `Profile 2`
- ...

**6. Create a New Profile via Brave Interface**

- Reopen Brave Browser.
- Click on the **profile icon**  (usually at the top-right corner).
- Select **"Add Profile"** .
- Name the new profile (e.g., **"Duplicated Profile"** ).

This step ensures that Brave recognizes the new profile and assigns it properly.

**7. Close Brave Browser Again**

After creating the new profile, close Brave to ensure all files are saved.

**8. Locate the New Profile Directory**

Back in the terminal, list the directories again:

```Copy code
ls
```

You should now see a new directory, such as `Profile 1` or `Profile 2`.

**9. Copy Specific Data from Old Profile to New Profile**

Copy essential files and folders from your current profile (`Default`) to the new profile directory.

```Copy code
# Replace 'Profile 1' with your new profile directory name if different
cp -r Default/Extensions 'Profile 1'/
cp Default/Preferences 'Profile 1'/
cp Default/Bookmarks 'Profile 1'/
cp Default/Favicons 'Profile 1'/
cp Default/Top\ Sites 'Profile 1'/
```

**Note:**  Avoid copying files like `Cookies`, `History`, `Login Data`, and `Cache` to prevent conflicts and potential corruption.

**10. Adjust File Permissions (If Necessary)**

Ensure that the new profile directory has the correct permissions:

```Copy code
chmod -R 700 'Profile 1'
```
**11. Edit the Preferences File**

Modify the `Preferences` file in the new profile to avoid any internal conflicts.

```Copy code
nano 'Profile 1'/Preferences
```

- Look for the `"profile"` section.
- Change the `"name"` field to match your new profile name (e.g., `"Duplicated Profile"`).
- Save and exit (`Ctrl + O`, `Enter`, `Ctrl + X`).

**12. Start Brave Browser**

- Open Brave Browser and switch to the new profile:
- Click on the **profile icon** .
- Select **"Duplicated Profile"** .

**13. Verify Extensions and Settings**

- Navigate to `brave://extensions/` to ensure all extensions are present.
- Check your settings to confirm they match the original profile.

**14. Reinstall Extensions (If Necessary)**

If some extensions aren't functioning correctly, reinstall them:

- Go to `brave://extensions/`.
- Remove the problematic extension.
- Reinstall it from the Brave Web Store.

**15. Sync Additional Data (Optional)**

If you use Brave Sync:
- Go to `brave://settings/braveSync/setup`.
- Set up sync to synchronize bookmarks, passwords, and more.

---

**Additional Tips**

- **Avoid Copying Encrypted Data:**  Certain data like saved passwords are encrypted and tied to the original profile, so copying them won't work.
- **Regular Backups:**  Keep regular backups of your browser data to prevent loss in case of corruption.
- **Profile Management:**  Use Brave's built-in profile management for easier handling of multiple profiles.

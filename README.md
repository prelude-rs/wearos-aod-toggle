# AOD

A Wear OS complication that shows and toggles the watch's Always-On Display (AOD) setting, plus a launcher app ("AOD") you can map to a hardware button to toggle it with one press. Built for a OnePlus Watch 3 (Wear OS 5, API 34) and sideloaded with adb; there is no Play Store listing, no settings screen and no phone app.

The AOD switch is `Settings.Global` `ambient_enabled` (1 = on, 0 = off). Writing it requires `android.permission.WRITE_SECURE_SETTINGS`, which Android only lets you grant over adb, hence the `pm grant` step below.

The commands below build and install the release variant, application id `cc.floresta.aodtoggle`, label "AOD".

## Prerequisites

- JDK 17. Point Gradle at it for the shell session:
  ```sh
  export JAVA_HOME=/path/to/jdk-17
  ```
- Android SDK with platform 36 and build-tools (for example via Android Studio's SDK Manager). Set `ANDROID_HOME`, or put `sdk.dir=/path/to/Android/Sdk` in `local.properties` at the repo root.
- `adb` (Android platform-tools) on your `PATH`.

## One-time: release keystore

Create a keystore (anywhere outside the repo) and answer the prompts:

```sh
keytool -genkeypair -v -keystore ~/aodtoggle-release.jks -alias aodtoggle \
  -keyalg RSA -keysize 2048 -validity 10000
```

Then add all four entries to `~/.gradle/gradle.properties` (never to the repo):

```properties
aodtoggle.keystore.file=/home/you/aodtoggle-release.jks
aodtoggle.keystore.password=<keystore password>
aodtoggle.keystore.alias=aodtoggle
aodtoggle.keystore.keyPassword=<key password>
```

All four are required. If any is missing or blank the release is built unsigned (`app-release-unsigned.apk`) and the watch will refuse to install it. Use an absolute path for `file`: a relative path is resolved against the `app/` module directory, not your shell's directory.

Keep the same keystore for every release build: reinstalling with a different signature requires an uninstall, which loses the permission grant.

## Build

```sh
./gradlew assembleRelease
```

Output: `app/build/outputs/apk/release/app-release.apk`.

## Connect adb over Wi-Fi

On the watch: Settings > Developer options > turn on ADB debugging and Wireless debugging (the watch and your computer must be on the same Wi-Fi network).

1. In Wireless debugging, tap "Pair new device". The watch shows an IP, a pairing port and a pairing code. On the computer:
   ```sh
   adb pair <ip>:<pair-port> <code>
   ```
2. Back on the main Wireless debugging screen, note the IP and the (different) connection port:
   ```sh
   adb connect <ip>:<port>
   ```
   Often mDNS connects automatically, so check first:
   ```sh
   adb devices
   ```

Keep the Wireless debugging screen open while you work. The watch drops Wi-Fi when its screen sleeps, and the connection port changes when it reconnects, so run `adb connect <ip>:<new-port>` again with the port shown on that screen.

## Install and grant the permission

```sh
adb install -r app/build/outputs/apk/release/app-release.apk
adb shell pm grant cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS
```

The grant survives reinstalling with the same signature. It is lost if you uninstall the app, so run it again after an uninstall.

## Use it

**Complication.** On the watch, edit the watch face, pick an image slot and choose "AOD Toggle" (listed under the "AOD" header; the debug build is "AOD Toggle (debug)"). The app itself stays "AOD". The image is the text "AOD" with the O drawn as a clock: white when the AOD is off, amber when it is on, and grey when unavailable (permission not granted, or the setting does not exist). Tapping it toggles the AOD. Tapping it while grey re-checks the permission and redraws, without toggling. The system refreshes it every 5 minutes while the watch face is active, so a change made in Settings shows up within about 5 minutes with the screen on.

**Battery warning.** When you add the complication, OnePlus shows a generic "High battery usage ... 1 to 1.5 days" warning. It is a system-wide notice that appears for any complication (Maps shows it too), not a measurement of this app. The real cost is checked in item N6 of `docs/manual-checklist.md` (`dumpsys batterystats`: at most about 12 service triggers per hour and negligible CPU).

**Button.** The "AOD" app appears in the watch's app list. Each time it opens it toggles the AOD and shows the image for the new state with a switch labelled "AOD" in the new position. The screen stays open until you leave with the button or a swipe; tapping the switch toggles again, and pressing the button again while the screen is open also toggles again. If the watch turns the screen off or returns to the face on its own, the screen closes and the next opening toggles again. When toggling is unavailable it shows the grey image, "AOD unavailable" and a disabled switch that does not respond. To use it from a hardware button, pick the "AOD" app in the watch's button customisation setting. The exact menu path varies by watch and software version.

## Troubleshooting

- Grey complication or "AOD unavailable": usually the permission is missing, but it can also mean the setting key does not exist or the read was denied. Run `adb logcat -s AodToggle` to see which. If it is the permission, run the `pm grant` command above, then tap the complication.
- Install is rejected: the APK is probably unsigned. Check the four `aodtoggle.keystore.*` entries and rebuild.
- Look at the logs:
  ```sh
  adb logcat -s AodToggle
  ```
- `adb devices` shows nothing or `offline`: wake the watch, open Wireless debugging and `adb connect` again with the port currently shown.

## Development

The debug variant is a separate app: `cc.floresta.aodtoggle.debug`, label "AOD (debug)".

```sh
./gradlew installDebug
adb shell pm grant cc.floresta.aodtoggle.debug android.permission.WRITE_SECURE_SETTINGS
./gradlew connectedDebugAndroidTest   # instrumented tests on the connected watch
./gradlew ktlintCheck detekt lintDebug testDebugUnitTest   # L1 checks
```

Uninstall the debug app before checking the release app by hand, so only one "AOD" complication provider exists:

```sh
adb uninstall cc.floresta.aodtoggle.debug
```

# ZEGOCLOUD easy example

ZEGOCLOUD's easy example is a simple wrapper around our RTC product. You can refer to the sample code for quick integration.

## Getting started

### Prerequisites

#### Basic requirements

* [Android Studio 2020.3.1 or later](https://developer.android.com/studio)
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* Create a project in [ZEGOCLOUD Admin Console](https://zegocloud.com/). For details, see [Admin Console - Project management](https://docs.zegocloud.com/article/1271).

The platform-specific requirements are as follows:

#### To build an Android app:

* Android SDK packages: Android SDK 30, Android SDK Platform-Tools 30.x.x or later.
* An Android device or Simulator that is running on Android 4.1 or later and supports audio and video. We recommend you use a real device (Remember to enable **USB debugging** for the device).

#### To build an iOS app:

* [Xcode 7.0 or later](https://developer.apple.com/xcode/download)
* [CocoaPods](https://guides.cocoapods.org/using/getting-started.html#installation)
* An iOS device or Simulator that is running on iOS 13.0 or later and supports audio and video. We recommend you use a real device.

#### Check the development environment

After all the requirements required in the previous step are met, run the following command to check whether your development environment is ready:

```
$ flutter doctor
```

![image](docs/images/flutter_doctor.png)

* If the Android development environment is ready, the **Android toolchain** item shows a ready state.
* If the iOS development environment is ready, the **Xcode**  item shows a ready state.

#### Check firebase development environment

Install firebase and flutterfire command line tools according to [this document](https://firebase.google.com/docs/flutter/setup)

So that you can execute the following command in the next step

```
firebase login
flutterfire configure
```

#### Modify the project configurations

* You need to set `appID` to your own account, which can be obtained in the [ZEGO Admin Console](https://console.zegocloud.com/).
* You need to set `serverUrl` to a valid URL that can be obtained for Zego auth token and post FCM notification request.

> We use Heroku for test backen service, you can deploy the token generation service with one simple click.
>
> [![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/ZEGOCLOUD/easy_example_call_server_nodejs)
>
> Once deployed completed, you will get an url for your instance, try accessing `https://<heroku url>/access_token?uid=1234` to check if it works.
>
> Check [easy_example_call_server_nodejs](https://github.com/ZEGOCLOUD/easy_example_call_server_nodejs) for more details.
>
> Note⚠️⚠️⚠️: There are some limitations for Heroku free account, please check this [Free Dyno Hours](https://devcenter.heroku.com/articles/free-dyno-hours) if you want to use Heroku for your production service.

![1653297768165.png](docs/images/appid.png)

### Run the sample code

1. Open Terminal, navigate to the `easy_example_flutter` folder.
2. Run the `flutter pub get` command to fetch all dependencies that are needed.
3. Run the `firebase login` to connect your firebase account
4. Run the `flutterfire configure` Select your firebase project and configure android and ios project.
5. The ios project needs to configure your development team in xcode and upload the apns certificate to the fcm console of firebase, refer to [this document](https://firebase.flutter.dev/docs/messaging/apple-integration)
6. Run the `flutter run`, sample code will run on your device.

>  tips: Android devices need to ensure that the user agrees to the appropriate notification permissions.

> Warning: If you are using flutter 3.0+, please switch to 3.0/call_invite branch for testing

### demo introduction

1. After the demo starts, it will automatically request zego token from your server and report your fcm token to your server
—— You can follow here when you test to know if the process goes well

![picture](./docs/images/demo-status.jpg#pic_center%20=100x)

2. Every time the APP starts, a userid will be randomly obtained and displayed here
![picture](./docs/images/random-userid.jpg#pic_center%20=100x)

3. You can enter the userid of the other device here, and click the call button on the right to make a call invitation
![picture](./docs/images/call-user.jpg#pic_center%20=100x)

4. You can also enter the IDs of multiple users in the call input box to invite a group call. The call started in this way will enter the group call interface.

5. When the demo receives a call invitation in the foreground, the flutter widget component will pop up at the top, you can click to accept or reject (you can customize this component)

![picture](./docs/images/in-app-invite.jpg#pic_center%20=100x)

6. When the demo receives a call invitation in the background, the system fcm notification will pop up, click the notification to enter the app and display the call invitation
![picture](./docs/images/fcm-notification.jpg#pic_center%20=100x)


7. The Android platform additionally implements custom notifications, you can directly click to accept/reject, or click the notification panel to enter the app to view the call invitation
![picture](./docs/images/background-invite.jpg#pic_center%20=100x)


## Integrate the SDK into your project

[![Integrate](docs/images/integration_video.jpg)](https://www.youtube.com/watch?v=AzdivRas-uc)

### Add zego_express_engine into your project

`$ flutter pub add zego_express_engine`

`$ flutter pub get`

### Turn off some classes's confusion

To prevent the ZEGO SDK public class names from being obfuscated, please complete the following steps:

1. Create `proguard-rules.pro` file under [your_project > android > app] with content as show below:

```
-keep class **.zego.**  { *; }
```

![image](docs/images/proguard_rules_file.jpg)

2. Add config code to `android/app/build.gradle` for release build:

```
proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
```

![image](docs/images/proguard_rules_config.jpg)

### Grant permission

You need to grant the network access, camera, and microphone permission to make your SDK work as except.

#### For Android

Open [your_project > android > app > src > main > AndroidManifest.xml] file and add the lines below out side the "application" tag:
![image](docs/images/android_add_permission.gif)

```xml
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <application
   ...
```

#### For iOS

Open [your_project > ios > Runner > Info.plist] and add the lines below inside the "dict" tag:
![image](docs/images/ios_add_permission.gif)

```xml
...
<dict>
	<key>NSCameraUsageDescription</key>
	<string>We need to use your camera to help you join the voice interaction.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>We need to use your mic to help you join the voice interaction.</string>

   ...
```

### Copy `ZegoExpressManager` source code to your project

Copy `zego_express_manager.dart` file to [your_project > lib] folder.

### Method call

The calling sequence of the SDK interface is as follows:
createEngine --> joinRoom --> getLocalVideoView/getRemoteVideoView --> leaveRoom

#### Create engine

Before using the SDK function, you need to create the SDK instance first. We recommend creating it when the application starts. The sample code is as follows:

```js
class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    ZegoExpressManager.shared.createEngine(widget.appID);
    ...
    super.initState();
  }
```

#### Join room

When you want to communicate with audio and video, you need to call the join room interface first. According to your business scenario, you can set different audio and video controls through options, such as:

1. Call scene：[ZegoMediaOption.autoPlayVideo, ZegoMediaOption.autoPlayAudio, ZegoMediaOption.publishLocalAudio, ZegoMediaOption.publishLocalVideo]
2. Live scene - host: [ZegoMediaOption.autoPlayVideo, ZegoMediaOption.autoPlayAudio, ZegoMediaOption.publishLocalAudio, ZegoMediaOption.publishLocalVideo]
3. Live scene - audience:[ZegoMediaOption.autoPlayVideo, ZegoMediaOption.autoPlayAudio]
4. Chat room - host:[ZegoMediaOption.autoPlayAudio, ZegoMediaOption.publishLocalAudio]
5. Chat room - audience:[ZegoMediaOption.autoPlayAudio]

Take Call scene as an example:

```js
...

requestMicrophonePermission();
requestCameraPermission();
ZegoExpressManager.shared.joinRoom(
    widget.roomID,
    ZegoUser(widget.user1ID, widget.user1ID),
    widget.tokenForUser1JoinRoom, [
  ZegoMediaOption.publishLocalAudio,
  ZegoMediaOption.publishLocalVideo,
  ZegoMediaOption.autoPlayAudio,
  ZegoMediaOption.autoPlayVideo
]);
setState(() {
  _bigView = ZegoExpressManager.shared
      .getLocalVideoView()!;
  _user1Pressed = true;
});
...
```

#### Get video view

If your project needs to use the video communication functionality, you need to get the View for displaying the video, call `getLocalVideoView` for the local video, and call `getRemoteVideoView` for the remote video.

**getLocalVideoView**

Call this method after join room

```js
...

setState(() {
  _bigView = ZegoExpressManager.shared
      .getLocalVideoView()!;
  _user1Pressed = true;
});
...
```

**getRemoteVideoView**

Call this method after you received the `onRoomUserUpdate` callback:

```js
@override
void initState() {
  ZegoExpressManager.shared.createEngine(widget.appID);
  ZegoExpressManager.shared.onRoomUserUpdate =
      (ZegoUpdateType updateType, List<String> userIDList, String roomID) {
    if (updateType == ZegoUpdateType.Add) {
      for (final userID in userIDList) {
        if (!ZegoExpressManager.shared.isLocalUser(userID)) {
          setState(() {
             // Get remote vide view here
            _smallView =
                ZegoExpressManager.shared.getRemoteVideoView(userID)!;
          });
        }
      }
    }
  };
```

#### Leave room

When you want to leave the room, you can call the leaveroom interface.

```js
onPressed: () {
  if (_user1Pressed) {
    ZegoExpressManager.shared.leaveRoom();
```

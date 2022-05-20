import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationUtils {
  static Future<bool> requestFullIntentPermission(BuildContext context) async {
    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.CriticalAlert
    ];

    List<NotificationPermission> permissionsAllowed =
        await requestUserPermissions(context,
            channelKey: null, permissionList: requestedPermissions);

    return permissionsAllowed.isNotEmpty;
  }

  static Future<bool> requestBasicPermissionToSendNotifications(
      BuildContext context) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                backgroundColor: const Color(0xfffbfbfb),
                title: const Text('Get Notified!',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/animated-bell.gif',
                      height: MediaQuery.of(context).size.height * 0.3,
                      fit: BoxFit.fitWidth,
                    ),
                    const Text(
                      'Allow Awesome Notifications to send you beautiful notifications!',
                      maxLines: 4,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Later',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      )),
                  TextButton(
                    onPressed: () async {
                      isAllowed = await AwesomeNotifications()
                          .requestPermissionToSendNotifications();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Allow',
                      style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ));
    }
    return isAllowed;
  }

  static Future<List<NotificationPermission>> requestUserPermissions(
      BuildContext context,
      {
      // if you only intends to request the permissions until app level, set the channelKey value to null
      required String? channelKey,
      required List<NotificationPermission> permissionList}) async {
    // Check if the basic permission was conceived by the user
    if (!await requestBasicPermissionToSendNotifications(context)) return [];

    // Check which of the permissions you need are allowed at this time
    List<NotificationPermission> permissionsAllowed =
        await AwesomeNotifications().checkPermissionList(
            channelKey: channelKey, permissions: permissionList);

    // If all permissions are allowed, there is nothing to do
    if (permissionsAllowed.length == permissionList.length) {
      return permissionsAllowed;
    }

    // Refresh the permission list with only the disallowed permissions
    List<NotificationPermission> permissionsNeeded =
        permissionList.toSet().difference(permissionsAllowed.toSet()).toList();

    // Check if some of the permissions needed request user's intervention to be enabled
    List<NotificationPermission> lockedPermissions =
        await AwesomeNotifications().shouldShowRationaleToRequest(
            channelKey: channelKey, permissions: permissionsNeeded);

    // If there is no permitions depending of user's intervention, so request it directly
    if (lockedPermissions.isEmpty) {
      // Request the permission through native resources.
      await AwesomeNotifications().requestPermissionToSendNotifications(
          channelKey: channelKey, permissions: permissionsNeeded);

      // After the user come back, check if the permissions has successfully enabled
      permissionsAllowed = await AwesomeNotifications().checkPermissionList(
          channelKey: channelKey, permissions: permissionsNeeded);
    } else {
      // If you need to show a rationale to educate the user to conceed the permission, show it
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                backgroundColor: const Color(0xfffbfbfb),
                title: const Text(
                  'Awesome Notificaitons needs your permission',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/animated-clock.gif',
                      height: MediaQuery.of(context).size.height * 0.3,
                      fit: BoxFit.fitWidth,
                    ),
                    Text(
                      'To proceede, you need to enable the permissions above${channelKey?.isEmpty ?? true ? '' : ' on channel $channelKey'}:',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lockedPermissions
                          .join(', ')
                          .replaceAll('NotificationPermission.', ''),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Deny',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      )),
                  TextButton(
                    onPressed: () async {
                      // Request the permission through native resources. Only one page redirection is done at this point.
                      await AwesomeNotifications()
                          .requestPermissionToSendNotifications(
                              channelKey: channelKey,
                              permissions: lockedPermissions);

                      // After the user come back, check if the permissions has successfully enabled
                      permissionsAllowed = await AwesomeNotifications()
                          .checkPermissionList(
                              channelKey: channelKey,
                              permissions: lockedPermissions);

                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Allow',
                      style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ));
    }

    // Return the updated list of allowed permissions
    return permissionsAllowed;
  }

  static Future<bool> requestPreciseAlarmPermission(
      BuildContext context) async {
    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.PreciseAlarms
    ];

    List<NotificationPermission> permissionsAllowed =
        await requestUserPermissions(context,
            channelKey: null, permissionList: requestedPermissions);

    return permissionsAllowed.isNotEmpty;
  }

  static Future<bool> requestOverrideDndPermission(BuildContext context) async {
    List<NotificationPermission> requestedPermissions = [
      NotificationPermission.OverrideDnD
    ];

    List<NotificationPermission> permissionsAllowed =
        await requestUserPermissions(context,
            channelKey: null, permissionList: requestedPermissions);

    return permissionsAllowed.isNotEmpty;
  }
}

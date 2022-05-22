import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotifycationWidget extends StatelessWidget {
  const NotifycationWidget({
    Key? key,
    required this.callerUserID,
    required this.callerUserName,
    required this.callerIconUrl,
    required this.onDecline,
    required this.onAccept,
  }) : super(key: key);

  final String callerUserID;
  final String callerUserName;
  final String callerIconUrl;
  final void Function() onDecline;
  final void Function() onAccept;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 10),
        CircleAvatar(
          child: CachedNetworkImage(
            imageUrl: callerIconUrl,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.people),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              callerUserID,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              callerUserName,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        const SizedBox(width: 50),
        ElevatedButton(
          onPressed: onDecline,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.square(50),
            primary: Colors.red,
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.close),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.square(50),
            primary: Colors.green,
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.call),
        ),
        const SizedBox(width: 30),
      ],
    );
  }
}

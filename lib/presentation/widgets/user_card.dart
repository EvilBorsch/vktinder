import 'package:flutter/material.dart';
import 'package:vktinder/data/models/vk_group_user.dart';

class UserCard extends StatelessWidget {
  final VKGroupUser user;

  const UserCard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero, // No margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: cardContent(context),
    );
  }

  Container cardContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          userAvatar(context),
          const SizedBox(height: 24),
          userName(),
          const SizedBox(height: 8),
          userSurname(),
          const SizedBox(height: 32),
          swipeHelpInstruction(),
        ],
      ),
    );
  }

  Text userSurname() {
    return Text(
      user.surname,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }

  Text userName() {
    return Text(
      user.name,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Row swipeHelpInstruction() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.swipe, color: Colors.grey),
        SizedBox(width: 8),
        Text(
          "Свайпните влево или вправо",
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  CircleAvatar userAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.blue.withOpacity(0.2),
      child: Icon(
        Icons.person,
        size: 80,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

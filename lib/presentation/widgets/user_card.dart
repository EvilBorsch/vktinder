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
    // Use the full width available
    return SizedBox(
      width: double.infinity, // Ensure full width
      child: Card(
        margin: EdgeInsets.zero, // No margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: cardContent(context),
      ),
    );
  }

  Widget cardContent(BuildContext context) {
    return Container(
      width: double.infinity, // Ensure container takes full width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            userAvatar(context),
            const SizedBox(height: 24),
            userName(),
            userSurname(),
            const SizedBox(height: 16),

            // City and country
            if (user.city != null || user.country != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      [
                        if (user.city != null) user.city,
                        if (user.country != null) user.country,
                      ].join(', '),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

            // Online status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: user.online == true ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  user.online == true ? 'В сети' : 'Не в сети',
                  style: TextStyle(
                    color: user.online == true ? Colors.green : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            swipeInstructions(context),
          ],
        ),
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
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget swipeInstructions(BuildContext context) {
    return Container(
      width: double.infinity, // Make instructions take full width
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the row contents
        children: [
          Icon(Icons.swipe, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "Свайпните влево или вправо\nКликните чтобы узнать больше",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget userAvatar(BuildContext context) {
    return Hero(
      tag: 'user_avatar_${user.userID}',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 80,
          backgroundImage: NetworkImage(user.avatar!),
          backgroundColor: Colors.grey[200],
        ),
      ),
    );
  }
}

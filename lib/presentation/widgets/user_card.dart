import 'package:flutter/material.dart';
import 'package:vktinder/core/utils/ui_constants.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/widgets/common/animated_swipe_card.dart';

class UserCard extends StatelessWidget {
  final VKGroupUser user;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onTap;

  const UserCard({
    Key? key,
    required this.user,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the full width available
    return SizedBox(
      width: double.infinity, // Ensure full width
      child: AnimatedSwipeCard(
        onSwipeLeft: onSwipeLeft,
        onSwipeRight: onSwipeRight,
        onTap: onTap,
        swipeThreshold: 0.3,
        leftSwipeBackground: _buildSwipeBackground(
          alignment: Alignment.centerRight,
          color: Colors.red,
          icon: Icons.close_rounded,
        ),
        rightSwipeBackground: _buildSwipeBackground(
          alignment: Alignment.centerLeft,
          color: Colors.green,
          icon: Icons.message_rounded,
        ),
        child: Card(
          margin: EdgeInsets.zero, // No margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusXL),
          ),
          elevation: UIConstants.elevationL,
          child: cardContent(context),
        ),
      ),
    );
  }

  /// Builds the background for swipe actions
  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusXL),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingXL),
      child: Icon(
        icon,
        color: Colors.white,
        size: UIConstants.iconSizeXL,
      ),
    );
  }

  Widget cardContent(BuildContext context) {
    return Container(
      width: double.infinity, // Ensure container takes full width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusXL),
        color: Theme.of(context).cardColor,
        boxShadow: UIConstants.shadowHeavy,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: UIConstants.paddingXL, 
          horizontal: UIConstants.paddingM),
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
      padding: const EdgeInsets.symmetric(
        vertical: UIConstants.paddingM, 
        horizontal: UIConstants.paddingL
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(UIConstants.opacityLight),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the row contents
        children: [
          Icon(
            Icons.swipe, 
            color: Theme.of(context).colorScheme.primary,
            size: UIConstants.iconSizeM,
          ),
          const SizedBox(width: UIConstants.paddingS),
          Flexible(
            child: Text(
              "Свайпните влево или вправо\nКликните чтобы узнать больше",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: UIConstants.textSizeM,
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
              color: Theme.of(context).primaryColor.withOpacity(UIConstants.opacityMedium),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: UIConstants.avatarSizeL,
          backgroundImage: NetworkImage(user.avatar!),
          backgroundColor: Colors.grey[200],
        ),
      ),
    );
  }
}

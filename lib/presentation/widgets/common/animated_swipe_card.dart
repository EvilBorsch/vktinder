import 'package:flutter/material.dart';
import 'package:vktinder/core/utils/ui_constants.dart';

/// A card that can be swiped left or right with enhanced animations
class AnimatedSwipeCard extends StatefulWidget {
  /// The child widget to display in the card
  final Widget child;
  
  /// Callback when the card is swiped left
  final VoidCallback? onSwipeLeft;
  
  /// Callback when the card is swiped right
  final VoidCallback? onSwipeRight;
  
  /// Callback when the card is tapped
  final VoidCallback? onTap;
  
  /// The threshold for considering a swipe complete (0.0 to 1.0)
  final double swipeThreshold;
  
  /// The background widget to show when swiping left
  final Widget? leftSwipeBackground;
  
  /// The background widget to show when swiping right
  final Widget? rightSwipeBackground;
  
  /// Creates an animated swipe card
  const AnimatedSwipeCard({
    Key? key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTap,
    this.swipeThreshold = 0.3,
    this.leftSwipeBackground,
    this.rightSwipeBackground,
  }) : super(key: key);

  @override
  State<AnimatedSwipeCard> createState() => _AnimatedSwipeCardState();
}

class _AnimatedSwipeCardState extends State<AnimatedSwipeCard> with SingleTickerProviderStateMixin {
  /// The position of the card
  Offset _position = Offset.zero;
  
  /// The angle of the card rotation
  double _angle = 0.0;
  
  /// The animation controller for the card
  late AnimationController _animationController;
  
  /// The target position for the animation
  late Offset _targetPosition;
  
  /// The target angle for the animation
  late double _targetAngle;
  
  /// Whether the card is being dragged
  bool _isDragging = false;
  
  /// The direction of the swipe (positive for right, negative for left)
  double _swipeDirection = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: UIConstants.animationMedium,
    );
    
    _animationController.addListener(() {
      setState(() {
        // Interpolate between current position/angle and target position/angle
        _position = Offset.lerp(
          _position,
          _targetPosition,
          _animationController.value,
        )!;
        
        _angle = lerpDouble(
          _angle,
          _targetAngle,
          _animationController.value,
        )!;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// Resets the card position and angle
  void _resetPosition() {
    _targetPosition = Offset.zero;
    _targetAngle = 0.0;
    _animationController.forward(from: 0.0);
  }
  
  /// Completes the swipe animation in the given direction
  void _completeSwipe(DismissDirection direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSwipeRight = direction == DismissDirection.startToEnd;
    
    _targetPosition = Offset(
      isSwipeRight ? screenWidth * 1.5 : -screenWidth * 1.5,
      0.0,
    );
    
    _targetAngle = (isSwipeRight ? 1 : -1) * 0.5;
    
    _animationController.forward(from: 0.0).then((_) {
      if (isSwipeRight && widget.onSwipeRight != null) {
        widget.onSwipeRight!();
      } else if (!isSwipeRight && widget.onSwipeLeft != null) {
        widget.onSwipeLeft!();
      }
    });
  }
  
  /// Handles the start of a drag
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _swipeDirection = 0.0;
    });
  }
  
  /// Handles drag updates
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      
      // Calculate the angle based on the horizontal position
      // The further the card is dragged, the more it rotates
      final screenWidth = MediaQuery.of(context).size.width;
      _angle = (_position.dx / screenWidth) * 0.4;
      
      // Update swipe direction for visual feedback
      if (details.delta.dx > 0) {
        _swipeDirection = 1.0; // Right
      } else if (details.delta.dx < 0) {
        _swipeDirection = -1.0; // Left
      }
    });
  }
  
  /// Handles the end of a drag
  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final swipeThreshold = screenWidth * widget.swipeThreshold;
    
    setState(() {
      _isDragging = false;
      
      // If the card was dragged beyond the threshold, complete the swipe
      if (_position.dx.abs() > swipeThreshold) {
        _completeSwipe(_position.dx > 0 
            ? DismissDirection.startToEnd 
            : DismissDirection.endToStart);
      } else {
        // Otherwise, reset the position
        _resetPosition();
      }
    });
  }
  
  /// Builds the background for the swipe
  Widget _buildSwipeBackground() {
    if (_swipeDirection > 0 && widget.rightSwipeBackground != null) {
      // Right swipe
      return Opacity(
        opacity: (_position.dx / (MediaQuery.of(context).size.width * widget.swipeThreshold))
            .clamp(0.0, 1.0),
        child: widget.rightSwipeBackground,
      );
    } else if (_swipeDirection < 0 && widget.leftSwipeBackground != null) {
      // Left swipe
      return Opacity(
        opacity: (-_position.dx / (MediaQuery.of(context).size.width * widget.swipeThreshold))
            .clamp(0.0, 1.0),
        child: widget.leftSwipeBackground,
      );
    }
    
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        if (_isDragging) _buildSwipeBackground(),
        
        // Card
        GestureDetector(
          onTap: widget.onTap,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform.translate(
            offset: _position,
            child: Transform.rotate(
              angle: _angle,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper function to linearly interpolate between two doubles
double? lerpDouble(double? a, double? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}
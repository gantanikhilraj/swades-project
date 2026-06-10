import 'dart:async';
import 'package:flutter/material.dart';

class FactLoader extends StatefulWidget {
  final String title;
  const FactLoader({
    super.key,
    this.title = 'Waking up Server... ⚡',
  });

  @override
  State<FactLoader> createState() => _FactLoaderState();
}

class _FactLoaderState extends State<FactLoader> {
  late final Timer _timer;
  int _factIndex = 0;

  static const List<String> _sportsFacts = [
    "The fastest badminton smash ever recorded was clocked at 565 km/h (351 mph) by Satwiksairaj Rankireddy!",
    "Tennis was originally played with the palm of the hand instead of rackets. It was called 'Jeu de paume' (game of the palm) in France.",
    "Basketball was originally played with a soccer ball and peach baskets instead of nets, requiring a ladder to retrieve the ball after points.",
    "Table tennis balls can reach speeds of over 100 km/h (60 mph) in professional play, demanding lightning-fast reflexes.",
    "The longest professional tennis match in history lasted 11 hours and 5 minutes, played over three days at Wimbledon in 2010.",
    "Badminton is widely considered the second most popular participatory sport in the world, right behind soccer.",
    "The game of tennis originally comes from 12th century France, where players shouted 'Tenez!' (Hold/Receive) before serving.",
    "The first basketball game in 1891 was played with nine players on each side instead of today's five.",
    "An average badminton match involves significantly more running and high-intensity sprints than a tennis match of similar duration!"
  ];

  @override
  void initState() {
    super.initState();
    // Rotate facts every 5.5 seconds for a dynamic feel
    _timer = Timer.periodic(const Duration(milliseconds: 5500), (timer) {
      if (mounted) {
        setState(() {
          _factIndex = (_factIndex + 1) % _sportsFacts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Curated color scheme
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMutedColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinning logo or custom progress indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      backgroundColor: primaryColor.withOpacity(0.15),
                    ),
                  ),
                  Icon(
                    Icons.sports,
                    size: 32,
                    color: primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Waking up Server title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              
              // Render Free tier explanatory note
              Text(
                "Our API is hosted on Render's free tier. If it has been inactive, it will take about 40–50 seconds to wake up the server. Thank you for waiting!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textMutedColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Divider
              Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(height: 40),

              // Animated Facts Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Dynamic bulb icon with primary color glow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          color: isDark ? const Color(0xFF00FF87) : primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "DID YOU KNOW?",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: isDark ? const Color(0xFF00FF87) : primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Fact Text with animated transition
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 80),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.15),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _sportsFacts[_factIndex],
                          key: ValueKey<int>(_factIndex),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.85),
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

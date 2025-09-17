import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperInfoScreen extends StatefulWidget {
  const DeveloperInfoScreen({super.key});

  @override
  State<DeveloperInfoScreen> createState() => _DeveloperInfoScreenState();
}

class _DeveloperInfoScreenState extends State<DeveloperInfoScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _textController;
  late Animation<Offset> _textSlideAnimation;
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    
    // Text slide animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
    
    // Icon animation
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _iconAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations with delays
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logoController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        _textController.forward();
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        _iconController.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Info'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Developer image with animated entrance
            ScaleTransition(
              scale: _logoAnimation,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.deepPurple,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'devoloper.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Name with slide animation
            SlideTransition(
              position: _textSlideAnimation,
              child: const Text(
                'Zahid Hasan Tonmoy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Title with slide animation
            SlideTransition(
              position: _textSlideAnimation,
              child: const Text(
                'Senior Flutter Developer & UI/UX Master',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Social links with animated icons
            FadeTransition(
              opacity: _iconAnimation,
              child: Column(
                children: [
                  _SocialLinkButton(
                    icon: Icons.web,
                    label: 'Portfolio',
                    url: 'https://zahidhasantonmoy.vercel.app',
                  ),
                  const SizedBox(height: 15),
                  _SocialLinkButton(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    url: 'https://www.facebook.com/zahidhasantonmoybd',
                  ),
                  const SizedBox(height: 15),
                  _SocialLinkButton(
                    icon: Icons.linked_camera,
                    label: 'LinkedIn',
                    url: 'https://www.linkedin.com/in/zahidhasantonmoy/',
                  ),
                  const SizedBox(height: 15),
                  _SocialLinkButton(
                    icon: Icons.code,
                    label: 'GitHub',
                    url: 'https://github.com/zahidhasantonmoy',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Animated skills section
            FadeTransition(
              opacity: _iconAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Skills & Expertise',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _SkillChip(label: 'Flutter'),
                        _SkillChip(label: 'Dart'),
                        _SkillChip(label: 'UI/UX Design'),
                        _SkillChip(label: 'Firebase'),
                        _SkillChip(label: 'REST APIs'),
                        _SkillChip(label: 'State Management'),
                        _SkillChip(label: 'Animation'),
                        _SkillChip(label: 'Testing'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _SocialLinkButton({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.deepPurple.withOpacity(0.2),
      labelStyle: const TextStyle(
        color: Colors.deepPurple,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mpl_lab/Pages/class_detail.dart';

class MyClass extends StatefulWidget {
  final String classId;
  final String className;
  final String room;

  const MyClass({
    super.key,
    required this.classId,
    required this.className,
    required this.room,
  });

  @override
  _MyClassState createState() => _MyClassState();
}

class _MyClassState extends State<MyClass> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _generatePrimaryColor() {
    int charCode = widget.className.isNotEmpty ? widget.className.codeUnitAt(0) : 65;
    return HSLColor.fromAHSL(
      1.0,
      (charCode % 360).toDouble(),
      0.7,
      0.8,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _generatePrimaryColor();
    final secondaryColor = HSLColor.fromColor(primaryColor).withLightness(0.6).toColor();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isHovered ? 1.05 : _pulseAnimation.value,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassDetail(classId: widget.classId),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(minHeight: 180, maxHeight: 250), // Prevent overflow
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered ? primaryColor.withOpacity(0.6) : Colors.black26,
                      blurRadius: _isHovered ? 15 : 8,
                      offset: _isHovered ? const Offset(0, 8) : const Offset(2, 4),
                      spreadRadius: _isHovered ? 1 : 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(Icons.school, size: 100, color: Colors.white),
                      ),
                    ),

                    // Scrollable Content
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.book, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Class",
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Text(
                            widget.className,
                            style: GoogleFonts.montserrat(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.room, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  widget.room,
                                  style: GoogleFonts.openSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _isHovered ? 1.0 : 0.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "View Details",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 16, color: primaryColor),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';

class CaptchaWidget extends StatefulWidget {
  final Function(bool) onValidationChanged;

  const CaptchaWidget({Key? key, required this.onValidationChanged})
      : super(key: key);

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> {
  late String _captchaText;
  final TextEditingController _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    _captchaText =
        List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    setState(() {});
  }

  void _validateCaptcha(String value) {
    setState(() {
      _isValid = value.toUpperCase() == _captchaText;
      widget.onValidationChanged(_isValid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 60),
                painter: CaptchaPainter(_captchaText),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generateCaptcha,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Enter CAPTCHA',
            prefixIcon: const Icon(Icons.security),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            suffixIcon: _isValid
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.error, color: Colors.red),
          ),
          onChanged: _validateCaptcha,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the CAPTCHA';
            }
            if (!_isValid) {
              return 'CAPTCHA does not match';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class CaptchaPainter extends CustomPainter {
  final String text;

  CaptchaPainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw noise lines
    final Random random = Random();
    paint.color = Colors.blue[200]!;
    for (int i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        paint..strokeWidth = 2,
      );
    }

    // Draw text
    final textStyle = TextStyle(
      color: Colors.blue[800],
      fontSize: 32,
      fontWeight: FontWeight.bold,
      fontFamily: 'Roboto',
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

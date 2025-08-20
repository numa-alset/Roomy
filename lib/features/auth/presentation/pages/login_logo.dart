import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoginLogo extends StatelessWidget {
  const LoginLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:MediaQuery.of(context).size.height * 0.45,
      child: Lottie.asset(
        'assets/images/login_animation.json',
        repeat: true,
      ),
    );
  }
}

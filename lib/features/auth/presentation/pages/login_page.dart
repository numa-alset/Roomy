import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/features/auth/domain/usecases/mock_login_uc.dart';
import 'package:frontend/features/auth/presentation/pages/login_logo.dart';
import '../../../../core/providers/global_providers.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final uc = ref.read(mockLoginUcProvider);
    return Scaffold(
      body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LoginLogo(),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: Text("Login",
                            style: Theme.of(context).textTheme.headlineLarge),
                      ),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1300),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: TextFormField(
                                  onTapOutside: (_) => _nameFocus.unfocus(),
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(12)),
                                    hintText: "Username",
                                    hintStyle: TextStyle(
                                        color: Colors.grey.shade700),
                                    errorStyle: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: Colors.red),
                                  ),
                                  validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please enter your username'
                                      : null,
                                  onChanged: (_) =>
                                      _formKey.currentState!.validate(),
                                  onFieldSubmitted: (_) =>
                                      FocusScope.of(context)
                                          .requestFocus(_passwordFocus),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: TextFormField(
                                  onTapOutside: (_) =>
                                      _passwordFocus.unfocus(),
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(12)),
                                    hintText: "Password",
                                    hintStyle: TextStyle(
                                        color: Colors.grey.shade700),
                                    errorStyle: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: Colors.red),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    } else if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    } else if (
                                    !RegExp(r'^.{6,1000}$',).hasMatch(value)
                                    ) {
                                      return 'Weak Password';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) =>
                                      _formKey.currentState!.validate(),
                                  onFieldSubmitted: (_) => _submit(uc),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1900),
                        child:_isLoading?const CircularProgressIndicator() : ElevatedButton(
                          onPressed:() =>  _submit(uc),
                          style: ButtonStyle(
                            backgroundColor:
                            WidgetStatePropertyAll(Colors.blue),
                          ),
                          child:const Text("Login"),
                        ),
                      ),
                      SizedBox(height: 40,)
                    ],
                  ),
                ),
              ),
            );
          },
        ),
    );
  }

  void _submit(MockLoginUc uc) async{
    setState(() => _isLoading = true);
    final res = await uc(_nameController.text.trim());
    res.fold((e) {
      Fluttertoast.showToast(
          msg: e.message,
          backgroundColor: Colors.grey,
          textColor: Colors.white);
      ref.read(authTokenProvider.notifier).state = _nameController.text;
      ref.read(userIdProvider.notifier).state = _nameController.text;
    }, (pair) {
      final (token, user) = pair;
      ref.read(authTokenProvider.notifier).state = token;
      ref.read(userIdProvider.notifier).state = user.id;
    });
    if (mounted) setState(() => _isLoading = false);
  }
}

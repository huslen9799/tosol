import 'package:flutter/material.dart';

import '../services/app_store.dart';
import '../widgets/property_card.dart';
import '../widgets/brand.dart';
import 'register_page.dart';
import 'password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false, hidden = true;
  Future<void> login() async {
    if (!_form.currentState!.validate()) return;
    final store = AppScope.read(context);
    setState(() => loading = true);
    try {
      await store.login(identifierController.text, passwordController.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Нэвтрэх')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 36),
              Center(child: BrandMark(size: 66)),
              SizedBox(height: 16),
              Text(
                'Өргөө',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text('Таны мөрөөдлийн байр', textAlign: TextAlign.center),
              SizedBox(height: 40),
              TextFormField(
                controller: identifierController,
                keyboardType: TextInputType.text,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: [AutofillHints.username],
                decoration: InputDecoration(
                  labelText: 'Хэрэглэгчийн нэр эсвэл и-мэйл',
                  hintText: 'Нэр эсвэл example@gmail.com',
                  helperText: 'Хэрэглэгчийн нэрийн том, жижиг үсгийг ялгана.',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Хэрэглэгчийн нэр эсвэл и-мэйл оруулна уу.'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: hidden,
                autofillHints: [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Нууц үг',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: hidden ? 'Нууц үг харах' : 'Нууц үг нуух',
                    onPressed: () => setState(() => hidden = !hidden),
                    icon: Icon(
                      hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Нууц үгээ оруулна уу.' : null,
                onFieldSubmitted: (_) {
                  if (!loading) login();
                },
              ),
              SizedBox(height: 24),
              FilledButton(
                onPressed: loading ? null : login,
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Нэвтрэх'),
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: loading
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PasswordPage(forgot: true),
                        ),
                      ),
                child: Text('Нууц үгээ мартсан уу?'),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterPage()),
                      ),
                child: Text('Бүртгэлгүй юу? Бүртгүүлэх'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

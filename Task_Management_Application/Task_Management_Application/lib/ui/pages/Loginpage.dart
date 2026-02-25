import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:task_management/ui/pages/RegistraionPage.dart';
import 'package:task_management/db/db_helper.dart';

import 'home_page.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();



  void _loginUser(BuildContext context) async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    DBHelper databaseHelper = DBHelper();
    User? user = await DBHelper.loginUser(username, password);

    if (user?.password != null || user?.username != null) {
      // Benutzer erfolgreich angemeldet, führe gewünschte Aktionen aus
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Successful'),
          content: Text('Welcome, ${user?.username}!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Anmeldefehler, zeige Fehlermeldung
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Failed'),
          content: Text('Invalid username or password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () => _loginUser(context),
              child: const Text('Login'),
            ),
            const SizedBox(height: 10.0),
            TextButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationPage()),
                );
              },
              child: const Text("Don't have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}
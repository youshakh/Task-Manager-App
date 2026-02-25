import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:task_management/ui/pages/Loginpage.dart';

import 'package:task_management/db/db_helper.dart';
class RegistrationPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  void _registerUser(BuildContext context) async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text('Registration Failed'),
              content: const Text('Username and password are required.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    DBHelper databaseHelper = DBHelper();
    User? user = await DBHelper.loginUser(username, password);

    if (user?.password != null || user?.username != null) {
      // Benutzer erfolgreich angemeldet, führe gewünschte Aktionen aus
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text('You have already an account '),
              content: Text('login'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text('OK'),
                ),
              ],
            ),
      );
    }
    else {
      User newUser = User(username: username, password: password);
      int? result = await DBHelper.saveUser(newUser);

      if (result != 0) {
        // Benutzer erfolgreich registriert
        showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: Text('Registration Successful'),
                content: Text('User registered successfully.'),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        ),


                    child: Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        // Registrierungsfehler
        showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: Text('Registration Failed'),
                content: Text('Failed to register user.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registration')),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () => _registerUser(context),
              child: const Text('Register'),
            ),
            const SizedBox(height: 10.0),
            TextButton(
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: const Text("you have already an account ? log in"),
            ),
          ],
        ),
      ),
    );
  }
}
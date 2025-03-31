import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Page/playerPage/UserPlayerPage.dart';
import 'Page/playerPage/AdminPlayerPage.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 이 줄이 중요!
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isAdmin = false; // 기본은 사용자 모드
  int selectedIndex = 0; // 현재 바텀탭 인덱스

  void _showAdminDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("운영자 모드 진입"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "비밀번호 입력"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 닫기
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () {
                if (passwordController.text == "1234") {
                  setState(() => isAdmin = true);
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("비밀번호가 틀렸습니다")),
                  );
                }
              },
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage = isAdmin ? const AdminPlayerPage() : UserPlayerPage(onAdminRequest: _showAdminDialog);

    return Scaffold(
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '참가자'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '참가자2'),
          // 향후 추가 가능: 팀, 경기 등
        ],
      ),
    );
  }
}

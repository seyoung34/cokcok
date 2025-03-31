import 'package:cokcok/Page/matchStatusPage/AdminMatchStatusPage.dart';
import 'package:cokcok/Page/matchStatusPage/UserMatchStatusPage.dart';
import 'package:cokcok/Page/matchTablePage/AdminMatchTablePage.dart';
import 'package:cokcok/Page/matchTablePage/UserMatchTablePage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Page/playerPage/UserPlayerPage.dart';
import 'Page/playerPage/AdminPlayerPage.dart';
import 'Page/teamPage/UserTeamPage.dart';
import 'Page/teamPage/AdminTeamPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
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
  bool isAdmin = false;
  int selectedIndex = 0;

  void _showAdminDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("운영자 모드 진입"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "비밀번호 입력"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 페이지 리스트 구성
    final pages = isAdmin
        ? [const AdminPlayerPage(), const AdminTeamPage(), const AdminMatchTablePage(tournamentId: "콕콕 리그전"), const AdminMatchStatusPage()]
        : [UserPlayerPage(onAdminRequest: _showAdminDialog), const UserTeamPage(), const UserMatchTablePage(tournamentId: "콕콕 리그전"), const UserMatchStatusPage()];

    return Scaffold(
      // AppBar는 각 페이지 내부에서 처리
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.yellow.shade100,
        fixedColor: Colors.green.shade500,
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '참가자'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: '팀 구성'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: '점수표'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: '진행 상황'),
        ],
      ),

    );
  }
}

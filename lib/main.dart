import 'package:cokcok/Page/MatchTournament/UserTournamentPage.dart';
import 'package:cokcok/Page/matchStatusPage/AdminMatchStatusPage.dart';
import 'package:cokcok/Page/matchStatusPage/UserMatchStatusPage.dart';
import 'package:cokcok/Page/matchTablePage/AdminMatchTablePage.dart';
import 'package:cokcok/Page/matchTablePage/UserMatchTablePage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Page/MatchTournament/AdminTournamentPage.dart';
import 'firebase_options.dart';
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
      theme: ThemeData(
          scaffoldBackgroundColor: Colors.grey.shade200, fontFamily: 'BMJUA'),
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
  bool isAdmin = true;
  int selectedIndex = 1;

  void _showAdminDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("운영자 모드 진입"),
        content: TextField(
          controller: passwordController,
          obscureText: false,
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

  void _showUserDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("사용자 모드 진입"),
        content: TextField(
          controller: passwordController,
          obscureText: false,
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
                setState(() => isAdmin = false);
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

        ///Admin
        ? [
            const AdminPlayerPage(),  //참가자
            AdminTeamPage(onUserRequest: _showUserDialog), //팀 구성
            const AdminMatchTablePage(tournamentId: "콕콕 리그전"), //예선 점수표 테이블
            // const AdminMatchTournamentPage(tournamentId: "콕콕 리그전"),
            // const MixedLeaguePage(),
            const AdminTournamentPage(),  //토너먼트
            const AdminMatchStatusPage(), //상태
          ]

        /// User
        : [
            // UserPlayerPage(onAdminRequest: _showAdminDialog),
            UserTeamPage(onAdminRequest: _showAdminDialog), //팀 구성
            const UserMatchTablePage(tournamentId: "콕콕 리그전"), //예선 점수표 테이블
            // const UserMatchTournamentPage(tournamentId: "콕콕 리그전"),
            const UserTournamentPage(), //토너먼트
            const UserMatchStatusPage(), //상태
          ];

    return Scaffold(
        // AppBar는 각 페이지 내부에서 처리
        body: pages[selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1)),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.yellow.shade100,
              fixedColor: Colors.green.shade500,
              currentIndex: selectedIndex,
              onTap: (index) => setState(() => selectedIndex = index),
              items: isAdmin
                  ? const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.people), label: '참가자'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.groups), label: '팀 구성'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.sports_tennis), label: '예선 점수표'),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.emoji_events), label: '본선 토너먼트',),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.personal_video), label: '상황판'),
                    ]
                  : const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.groups), label: '팀 구성'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.sports_tennis), label: '예선 점수표'),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.emoji_events), label: '본선 토너먼트',),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.personal_video), label: '상황판'),
                    ],
            ),
          ),
        ));
  }
}

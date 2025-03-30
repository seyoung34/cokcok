import 'package:cokcok/CSVPage.dart';
import 'package:cokcok/MatchStatuspage.dart';
import 'TeamManagementPage.dart';
import 'MatchTablePage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // title: 'Flutter Demo',
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   useMaterial3: true,
      // ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // 현재 선택된 탭 인덱스

  // 📌 각 탭에 연결될 페이지 리스트
  final List<Widget> _pages = [
    CSVPage(), // 참가인원 관리 페이지
    TeamManagementPage(), // 팀 구성 페이지
    MatchTablePage(tournamentId: "콕콕 리그전",), // 경기 진행 페이지
    MatchStatusPage()
  ];

  // 📌 탭 변경 시 실행되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // 선택된 페이지 표시

      // 📌 BottomNavigationBar 추가
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // 현재 선택된 탭
        onTap: _onItemTapped, // 탭 클릭 시 호출
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.emoji_people), label: "참가인원관리"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "팀 구성"),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: "점수 표"),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: "경기 상황"),
        ],
        selectedItemColor: Colors.blue, // 선택된 아이템 색상
        unselectedItemColor: Colors.grey, // 선택되지 않은 아이템 색상
      ),
    );
  }
}


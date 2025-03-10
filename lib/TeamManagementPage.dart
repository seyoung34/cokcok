import 'package:flutter/material.dart';

class TeamManagementPage extends StatefulWidget {
  @override
  _TeamManagementPageState createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {

  //note A~E 에 해당하는 정수로 바꾸는게 나을 듯

  List<Map<String, String>> participants = [
    {"name": "김재민", "gender": "남", "rank": "A"},
    {"name": "이세영", "gender": "남", "rank": "C"},
    {"name": "정영훈", "gender": "남", "rank": "B"},
    {"name": "박민규", "gender": "남", "rank": "C"},
    {"name": "정이지", "gender": "여", "rank": "C"},
    {"name": "김하은", "gender": "여", "rank": "B"},
    {"name": "이혜인", "gender": "여", "rank": "B"},
    {"name": "김지우", "gender": "여", "rank": "C"},
    {"name": "김재진", "gender": "남", "rank": "B"},
    {"name": "홍윤기", "gender": "남", "rank": "A"},
  ]; // 예제 데이터 (실제 데이터는 CSV에서 불러올 예정)

  //todo 수정하기
  // List<List<dynamic>> participants2 =

  List<List<Map<String, String>>> maleTeams = []; // 남성 복식 팀
  List<List<Map<String, String>>> femaleTeams = []; // 여성 복식 팀
  List<List<Map<String, String>>> mixedTeams = []; // 혼성 복식 팀

  // 📌 실력 균형 기반 팀 구성
  void _generateTeams() {
    List<Map<String, String>> males = participants.where((p) => p["gender"] == "남").toList();
    List<Map<String, String>> females = participants.where((p) => p["gender"] == "여").toList();

    // 랭크를 기준으로 정렬 (실력 균형 고려)
    males.sort((a, b) => a["rank"]!.compareTo(b["rank"]!));
    females.sort((a, b) => a["rank"]!.compareTo(b["rank"]!));

    List<List<Map<String, String>>> newMaleTeams = [];
    List<List<Map<String, String>>> newFemaleTeams = [];
    List<List<Map<String, String>>> newMixedTeams = [];

    // 📌 1️⃣ 여성 복식 팀 구성 (실력 균형)
    for (int i = 0; i < females.length - 1; i += 2) {
      newFemaleTeams.add([females[i], females[i + 1]]);
    }

    // 📌 2️⃣ 혼성 복식 팀 구성 (여성 먼저 배치 후 실력 균형 고려)
    int maleIndex = 0;
    for (var female in females) {
      if (maleIndex < males.length) {
        newMixedTeams.add([female, males[maleIndex]]);
        maleIndex++;
      }
    }

    // 📌 3️⃣ 남성 복식 팀 구성 (남은 남성 참가자끼리 실력 균형 맞춤)
    for (int i = 0; i < males.length/2; i ++) {
      newMaleTeams.add([males[i], males[males.length-i-1]]);
    }

    setState(() {
      femaleTeams = newFemaleTeams;
      mixedTeams = newMixedTeams;
      maleTeams = newMaleTeams;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("팀 구성")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _generateTeams,
              child: Text("팀 자동 구성"),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTeamSection("여성 복식", femaleTeams),
                  _buildTeamSection("혼성 복식", mixedTeams),
                  _buildTeamSection("남성 복식", maleTeams),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📌 팀 목록을 표시하는 위젯
  Widget _buildTeamSection(String title, List<List<Map<String, String>>> teams) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          teams.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("팀이 구성되지 않았습니다."),
          )
              : Column(
            children: teams.map((team) {
              return ListTile(
                title: Text("${team[0]["name"]} & ${team[1]["name"]}"),
                subtitle: Text("랭크: ${team[0]["rank"]} - ${team[1]["rank"]}"),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

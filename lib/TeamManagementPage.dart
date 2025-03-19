import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'model/Player.dart';
import 'model/Team.dart';

class TeamManagementPage extends StatefulWidget {
  @override
  _TeamManagementPageState createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  List<Team> maleTeams = [];
  List<Team> femaleTeams = [];
  List<Team> mixedTeams = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  // 📌 SharedPreferences에서 팀 데이터 불러오기
  Future<void> _loadTeams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      maleTeams = _loadTeamList(prefs, "남성 복식 팀");
      femaleTeams = _loadTeamList(prefs, "여성 복식 팀");
      mixedTeams = _loadTeamList(prefs, "혼성 복식 팀");
    });
  }

  // 📌 SharedPreferences에서 리스트 변환
  List<Team> _loadTeamList(SharedPreferences prefs, String key) {
    String? jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((team) => Team.fromJson(team)).toList();
  }

  // 📌 팀 데이터 저장
  Future<void> _saveTeams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("남성 복식 팀", jsonEncode(maleTeams.map((t) => t.toJson()).toList()));
    await prefs.setString("여성 복식 팀", jsonEncode(femaleTeams.map((t) => t.toJson()).toList()));
    await prefs.setString("혼성 복식 팀", jsonEncode(mixedTeams.map((t) => t.toJson()).toList()));
  }

  // 📌 다이얼로그를 띄워 division을 입력받음
  Future<void> _showDivisionDialog(String title, int playerCount, Function(int) onConfirmed) async {
    TextEditingController divisionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$title 참가자 수: $playerCount명"),
          content: TextField(
            controller: divisionController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "몇 부로 나누시겠습니까?"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                int divisionCount = int.tryParse(divisionController.text) ?? 1;
                Navigator.pop(context);
                onConfirmed(divisionCount);
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  // 📌 실력 균형 기반 팀 자동 구성
  Future<void> _generateTeams() async {
    List<Player> males = await _loadPlayers("남성 참가자");
    List<Player> females = await _loadPlayers("여성 참가자");

    // ✅ 사용자 입력을 받아 몇 부로 나눌지 결정
    await _showDivisionDialog("남성 복식", males.length, (int maleDivisions) async {
      await _showDivisionDialog("여성 복식", females.length, (int femaleDivisions) async {

        // ✅ 실력 순으로 정렬
        males.sort((a, b) => a.rank.compareTo(b.rank));
        females.sort((a, b) => a.rank.compareTo(b.rank));

        // ✅ 부별로 참가자 자동 배정
        Map<int, List<Player>> maleDivided = _dividePlayersIntoDivisions(males, maleDivisions);
        Map<int, List<Player>> femaleDivided = _dividePlayersIntoDivisions(females, femaleDivisions);

        List<Team> newMaleTeams = _createTeams(maleDivided);
        List<Team> newFemaleTeams = _createTeams(femaleDivided);
        List<Team> newMixedTeams = _createMixedTeams(maleDivided, femaleDivided);

        setState(() {
          maleTeams = newMaleTeams;
          femaleTeams = newFemaleTeams;
          mixedTeams = newMixedTeams;
        });

        _saveTeams(); // ✅ 자동 저장
      });
    });
  }

  // 📌 참가자 리스트를 입력받아 n개의 부로 나누는 함수
  Map<int, List<Player>> _dividePlayersIntoDivisions(List<Player> players, int divisionCount) {
    Map<int, List<Player>> divisions = {};
    int playersPerDivision = (players.length / divisionCount).ceil();

    for (int i = 0; i < divisionCount; i++) {
      divisions[i + 1] = players.sublist(
          i * playersPerDivision,
          (i + 1) * playersPerDivision > players.length ? players.length : (i + 1) * playersPerDivision
      );
    }

    return divisions;
  }

  // 📌 부별로 팀 생성
  List<Team> _createTeams(Map<int, List<Player>> divisions) {
    List<Team> teams = [];

    divisions.forEach((division, players) {
      for (int i = 0; i < players.length ~/ 2; i++) {
        teams.add(Team(
          id: "부$division-${i + 1}",
          players: [players[i], players[players.length - i - 1]],
          division: division,
        ));
      }
    });

    return teams;
  }

  // 📌 혼성 복식 팀 구성 (여성 먼저 배치 후 실력 균형 고려)
  List<Team> _createMixedTeams(Map<int, List<Player>> maleDivisions, Map<int, List<Player>> femaleDivisions) {
    List<Team> mixedTeams = [];

    maleDivisions.forEach((division, males) {
      if (femaleDivisions.containsKey(division)) {
        List<Player> females = femaleDivisions[division]!;
        int minLength = males.length < females.length ? males.length : females.length;

        for (int i = 0; i < minLength; i++) {
          mixedTeams.add(Team(
            id: "혼성$division-${i + 1}",
            players: [females[i], males[i]],
            division: division,
          ));
        }
      }
    });

    return mixedTeams;
  }

  // 📌 SharedPreferences에서 Player 데이터 불러오기
  Future<List<Player>> _loadPlayers(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? playersJson = prefs.getStringList(key);
    if (playersJson == null) return [];
    return playersJson.map((json) => Player.fromJson(jsonDecode(json))).toList();
  }

  // 📌 팀 목록을 표시하는 함수 (각 테이블 2열로 구성)
  Widget _buildTeamSection(String title, List<Team> teams, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          teams.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("팀이 없습니다."),
          )
              : _buildDraggableGridView(teams, color),
        ],
      ),
    );
  }

// 📌 Drag & Drop을 지원하는 팀 그리드 뷰 (2열 배치)
  Widget _buildDraggableGridView(List<Team> teams, Color color) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: teams.map((team) {
        return DragTarget<Player>(
          onWillAccept: (data) => true,
          onAccept: (player) {
            setState(() {
              _removePlayerFromTeams(player);
              team.players.add(player);
              _saveTeams();
            });
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              width: 200, // ✅ 2열 배치
              height: 150,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(team.id, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    children: team.players.map((player) {
                      return Draggable<Player>(
                        data: player,
                        feedback: Material(
                          child: Container(
                            padding: EdgeInsets.all(8),
                            color: Colors.teal,
                            child: Text(player.name, style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        onDragStarted: () => setState(() => _removePlayerFromTeams(player)),
                        onDraggableCanceled: (_, __) => setState(() => team.players.add(player)),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          color: Colors.white,
                          child: Text(player.name),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  void _removePlayerFromTeams(Player player) {
    setState(() {
      for (var team in [...maleTeams, ...femaleTeams, ...mixedTeams]) {
        team.players.removeWhere((p) => p.name == player.name);
      }
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTeamSection("남성 복식", maleTeams, Colors.blue.shade100),
                  _buildTeamSection("혼성 복식", mixedTeams, Colors.green.shade100),
                  _buildTeamSection("여성 복식", femaleTeams, Colors.pink.shade100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

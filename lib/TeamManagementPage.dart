import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? selectedCategory; // 🔹 선택된 팀 유형 (남성, 여성, 혼성)
  Map<String, int> divisionCounts = {}; // 🔹 각 팀 유형의 division 개수 저장

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _loadState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("팀 구성")),
      body: Column(
        children: [
          _buildCategorySelector(), // 🔹 카테고리 선택 버튼 추가
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _generateTeams,
              child: Text("팀 자동 구성"),
            ),
          ),
          Expanded(child: _buildSelectedCategoryView()), // 🔹 선택된 카테고리만 표시
        ],
      ),
    );
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

  Future<void> _saveState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ✅ 현재 division 설정 저장
    await prefs.setInt("남성_division", divisionCounts["남성"] ?? 1);
    await prefs.setInt("여성_division", divisionCounts["여성"] ?? 1);
    await prefs.setInt("혼성_division", divisionCounts["혼성"] ?? 1);

    // ✅ 현재 선택된 카테고리 저장
    await prefs.setString("selectedCategory", selectedCategory ?? "");
  }

  Future<void> _loadState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      divisionCounts["남성"] = prefs.getInt("남성_division") ?? 1;
      divisionCounts["여성"] = prefs.getInt("여성_division") ?? 1;
      divisionCounts["혼성"] = prefs.getInt("혼성_division") ?? 1;
      selectedCategory = prefs.getString("selectedCategory")?.isNotEmpty ?? false
          ? prefs.getString("selectedCategory")
          : null;
    });
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

        // ✅ 각 Player 객체의 division 설정
        _assignDivisions(males, maleDivisions);
        _assignDivisions(females, femaleDivisions);

        // ✅ 팀 생성
        List<Team> newMaleTeams = _createTeams(males);
        List<Team> newFemaleTeams = _createTeams(females);
        List<Team> newMixedTeams = _createMixedTeams(males, females);

        setState(() {
          maleTeams = newMaleTeams;
          femaleTeams = newFemaleTeams;
          mixedTeams = newMixedTeams;
          divisionCounts = {
            "남성": maleDivisions,
            "여성": femaleDivisions,
            "혼성": 1 // 혼성은 따로 division을 받지 않음
          };
        });

        _saveTeams(); // ✅ 자동 저장
        _saveState();
      });
    });
  }

  // 📌 Player 객체에 division을 설정하는 함수
  void _assignDivisions(List<Player> players, int divisionCount) {
    int playersPerDivision = (players.length / divisionCount).ceil();

    for (int i = 0; i < players.length; i++) {
      players[i].division = (i ~/ playersPerDivision) + 1;
    }
  }

  // 📌 SharedPreferences에서 Player 데이터 불러오기
  Future<List<Player>> _loadPlayers(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? playersJson = prefs.getStringList(key);
    if (playersJson == null) return [];
    return playersJson.map((json) => Player.fromJson(jsonDecode(json))).toList();
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



  // 📌 상단 카테고리 선택 라디오 버튼
  Widget _buildCategorySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ["남성", "여성", "혼성"].map((category) {
        return Row(
          children: [
            Radio<String?>(
              value: category,
              groupValue: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = (selectedCategory == value) ? null : value; // 선택 취소 가능
                  _saveState();
                });
              },
            ),
            Text(category),
          ],
        );
      }).toList(),
    );
  }

  // 📌 선택된 카테고리에 따라 팀 배치
  Widget _buildSelectedCategoryView() {
    if (selectedCategory == null) return Container(); // 아무것도 선택되지 않으면 빈 화면

    List<Team> selectedTeams;
    if (selectedCategory == "남성") {
      selectedTeams = maleTeams;
    } else if (selectedCategory == "여성") {
      selectedTeams = femaleTeams;
    } else {
      selectedTeams = mixedTeams;
    }

    int divisionCount = divisionCounts[selectedCategory] ?? 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: List.generate(divisionCount, (index) {
        List<Team> divisionTeams = selectedTeams.where((team) => team.division == index + 1).toList();
        return Expanded(
          child: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: _buildTeamSection("${selectedCategory!} ${index + 1}부",divisionTeams, Colors.blue.shade100)
            )
          )
        );
      }),
    );
  }

  // 📌 Player의 division 속성을 기반으로 부별로 팀 생성
  List<Team> _createTeams(List<Player> players) {
    List<Team> teams = [];

    // ✅ division 기준으로 그룹화
    Map<int, List<Player>> groupedPlayers = {};
    for (var player in players) {
      groupedPlayers.putIfAbsent(player.division, () => []).add(player);
    }

    // ✅ 각 division 내에서 2명씩 팀 구성
    groupedPlayers.forEach((division, playerList) {
      for (int i = 0; i < playerList.length ~/ 2; i++) {
        teams.add(Team(
          id: "부$division-${i + 1}",
          players: [playerList[i], playerList[playerList.length - i - 1]],
          division: division,
        ));
      }
    });

    return teams;
  }

  // 📌 혼성 복식 팀 구성 (division 기준으로 남녀 매칭)
  List<Team> _createMixedTeams(List<Player> males, List<Player> females) {
    List<Team> mixedTeams = [];

    // ✅ division 기준으로 그룹화
    Map<int, List<Player>> maleDivisions = {};
    Map<int, List<Player>> femaleDivisions = {};

    for (var male in males) {
      maleDivisions.putIfAbsent(male.division, () => []).add(male);
    }
    for (var female in females) {
      femaleDivisions.putIfAbsent(female.division, () => []).add(female);
    }

    // ✅ 같은 division끼리 혼성 팀 매칭
    maleDivisions.forEach((division, maleList) {
      if (femaleDivisions.containsKey(division)) {
        List<Player> femaleList = femaleDivisions[division]!;
        int minLength = maleList.length < femaleList.length ? maleList.length : femaleList.length;

        for (int i = 0; i < minLength; i++) {
          mixedTeams.add(Team(
            id: "혼성$division-${i + 1}",
            players: [femaleList[i], maleList[i]],
            division: division,
          ));
        }
      }
    });

    return mixedTeams;
  }

// 📌 GridView 형태의 팀 섹션을 생성
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

// 📌 Drag & Drop이 가능한 팀 목록 (GridView 형식)
  Widget _buildDraggableGridView(List<Team> teams, Color color) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // ✅ 2열 배치
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5, // ✅ 팀 박스의 가로/세로 비율 조정
      ),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        return DragTarget<Player>(
          onWillAccept: (data) => true,
          onAccept: (player) {
            setState(() {
              _removePlayerFromTeams(player);
              teams[index].players.add(player);
              _saveTeams();
            });
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    teams[index].id,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    children: teams[index].players.map((player) {
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
                        onDraggableCanceled: (_, __) => setState(() => teams[index].players.add(player)),
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
      },
    );
  }

  void _removePlayerFromTeams(Player player) {
    setState(() {
      for (var team in [...maleTeams, ...femaleTeams, ...mixedTeams]) {
        team.players.removeWhere((p) => p.name == player.name);
      }
    });
  }

}

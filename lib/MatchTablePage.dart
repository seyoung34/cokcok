import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'model/Match.dart';
import 'model/Team.dart';

class MatchTablePage extends StatefulWidget {
  @override
  _MatchTablePageState createState() => _MatchTablePageState();
}

class _MatchTablePageState extends State<MatchTablePage> {
  late Map<String, int> divisionCounts = {}; // ✅ divisionCounts 저장
  String selectedTable = ""; // ✅ 선택된 테이블
  List<Match> matches = [];
  late Map<String, List<Team>> teamsByDivision = {}; // ✅ 부별 팀 저장

  @override
  void initState() {
    super.initState();
    _loadTeamsAndMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("경기 리그전")),
      body: Column(
        children: [
          _buildTableSelector(), // ✅ 테이블 선택 버튼 추가
          // Expanded(child: _buildSelectedTableView()), // ✅ 선택된 테이블 표시
        ],
      ),
    );
  }

  // 📌 SharedPreferences에서 팀 및 경기 데이터 불러오기
  void _loadTeamsAndMatches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // ✅ divisionCounts 불러오기
    String? divisionData = prefs.getString("divisionCounts");
    if (divisionData != null) {
      print(divisionData);  // 남성 : 3, 여성 : 2, 혼성 : 1
      setState(() {
        divisionCounts = Map<String, int>.from(jsonDecode(divisionData));
      });
      print(divisionCounts.keys); //남성, 여성, 혼성
    }

    // ✅ 부별로 팀을 불러와 저장
    teamsByDivision.clear();
    for (String key in divisionCounts.keys) {
      for (int i = 1; i <= divisionCounts[key]!; i++) {
        String divisionKey = "${key}_$i부";
        String? teamData = prefs.getString(divisionKey);

        if (teamData != null) {
          teamsByDivision[divisionKey] = (jsonDecode(teamData) as List)
              .map((teamJson) => Team.fromJson(teamJson))
              .toList();
        }
      }
    }

    // ✅ 혼성 팀은 따로 처리 (1부 고정)
    String? mixedData = prefs.getString("혼성 1부");
    if (mixedData != null) {
      teamsByDivision["혼성 1부"] = (jsonDecode(mixedData) as List)
          .map((teamJson) => Team.fromJson(teamJson))
          .toList();
    }

    // ✅ 경기 데이터 불러오기
    String? savedMatches = prefs.getString("matches_${selectedTable}");
    if (savedMatches != null) {
      setState(() {
        matches = (jsonDecode(savedMatches) as List)
            .map((matchJson) => Match.fromJson(matchJson))
            .toList();
      });
    } else if (teamsByDivision[selectedTable] != null) {
      setState(() {
        matches = _generateMatches(teamsByDivision[selectedTable]!);
      });
    }
  }

  // 📌 팀 리스트를 받아서 경기 목록을 자동 생성하는 함수
  List<Match> _generateMatches(List<Team> teams) {
    List<Match> matchList = [];
    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        matchList.add(Match(
          id: "${teams[i].id}_vs_${teams[j].id}",
          team1: teams[i],
          team2: teams[j],
          division: 1,
        ));
      }
    }
    return matchList;
  }



  // 📌 가로 스크롤 가능한 경기 테이블 선택
  Widget _buildTableSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: teamsByDivision.keys.map((table) {
          return Row(
            children: [
              Radio<String>(
                value: table,
                groupValue: selectedTable,
                onChanged: (value) {
                  setState(() {
                    selectedTable = value!;
                    _loadTeamsAndMatches(); // ✅ 선택된 테이블의 경기 데이터 불러오기
                  });
                },
              ),
              Text(table),
            ],
          );
        }).toList(),
      ),
    );
  }

  // 📌 선택된 테이블의 경기 테이블 생성
  Widget _buildSelectedTableView() {
    if (selectedTable.isEmpty) return Container(); // ✅ 아무것도 선택하지 않으면 빈 화면

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: _buildTableHeaders(),
        rows: _buildTableRows(),
      ),
    );
  }

  // 📌 테이블 헤더 (팀명)
  List<DataColumn> _buildTableHeaders() {
    return [
      DataColumn(label: Text("팀명"))
    ]..addAll(teamsByDivision[selectedTable]!.map((team) => DataColumn(label: Text("${team.id}\n${team.players[0].name}, ${team.players[1].name}"))));
  }

  // 📌 경기 결과 테이블 생성
  List<DataRow> _buildTableRows() {
    return List.generate(teamsByDivision[selectedTable]!.length, (rowIndex) {
      return DataRow(cells: [
        DataCell(Text("${teamsByDivision[selectedTable]![rowIndex].id}\n${teamsByDivision[selectedTable]![rowIndex].players[0].name}, ${teamsByDivision[selectedTable]![rowIndex].players[1].name}")),

        ...List.generate(teamsByDivision[selectedTable]!.length, (colIndex) {
          if (rowIndex == colIndex) return DataCell(Text("-"));

          Match? match = _findMatch(teamsByDivision[selectedTable]![rowIndex], teamsByDivision[selectedTable]![colIndex]);
          return DataCell(
            GestureDetector(
              onTap: () {
                if (match != null) _showScoreDialog(match);
              },
              child: Text(match != null && match.isCompleted
                  ? "${match.team1Score} : ${match.team2Score}"
                  : "입력"),
            ),
          );
        }),
      ]);
    });
  }

  // 📌 특정 팀 간의 경기 찾기
  Match? _findMatch(Team teamA, Team teamB) {
    return matches.firstWhere(
          (match) =>
      (match.team1.id == teamA.id && match.team2.id == teamB.id) ||
          (match.team1.id == teamB.id && match.team2.id == teamA.id),
      orElse: () => Match(id: "", team1: teamA, team2: teamB, division: 1),
    );
  }

  // 📌 경기 결과 업데이트
  void _updateMatchResult(Match match, int score1, int score2) {
    setState(() {
      match.team1Score = score1;
      match.team2Score = score2;
      match.isCompleted = true;
    });

    _saveMatches();
  }

  // 📌 경기 결과를 SharedPreferences에 저장
  void _saveMatches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("matches_$selectedTable", jsonEncode(matches.map((m) => m.toJson()).toList()));
  }

  // 📌 점수 입력 다이얼로그
  void _showScoreDialog(Match match) {
    TextEditingController team1ScoreController =
    TextEditingController(text: match.team1Score.toString());
    TextEditingController team2ScoreController =
    TextEditingController(text: match.team2Score.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${match.team1.id} vs ${match.team2.id}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: team1ScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "${match.team1.id} 점수"),
              ),
              TextField(
                controller: team2ScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "${match.team2.id} 점수"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
            TextButton(
              onPressed: () {
                _updateMatchResult(match, int.parse(team1ScoreController.text), int.parse(team2ScoreController.text));
                Navigator.pop(context);
              },
              child: Text("경기 종료"),
            ),
          ],
        );
      },
    );
  }
}

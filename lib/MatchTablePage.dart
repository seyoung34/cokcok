import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../model/Match.dart';
import '../model/Team.dart';

class MatchTablePage extends StatefulWidget {
  final String tournamentId; // 대회 고유 ID

  const MatchTablePage({Key? key, required this.tournamentId}) : super(key: key);

  @override
  _MatchTablePageState createState() => _MatchTablePageState();
}

class _MatchTablePageState extends State<MatchTablePage> {
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, List<Match>> matchTable = {};
  Map<String, int> divisionInfo = {};

  String? selectedTableKey;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMatchData();
  }

  //todo 기존 정보를 불러오는 것을 기본으로 두되, 새 게임 만들기 버튼 만들가

  Future<void> _initializeMatchData() async {
    try {
      // 부 정보 로드
      divisionInfo = await _firestoreService.loadDivision("부");

      //note 최초 실행 시 진행할건지 다이얼로그 띄워야함

      // 팀 정보 로드 및 경기 생성
      // await _generateAllMatchesAndSave(); //save까지함


      // 경기 정보 로드
      matchTable = await _firestoreService.loadMatches(); //이미 matchTable에 정보 있으니깐 최초 실행 때 불러오기 안해도 될 듯?
        //근데 또 사용자 입장에서 보면 동기화해야하니깐 불러오는게 낫겠다..

      setState(() {
        isLoading = false;
        // 첫 번째 카테고리 자동 선택
        selectedTableKey = matchTable.keys.isNotEmpty ? matchTable.keys.first : null; //??왜 라디오 선택 값을 matchTable의 키값으로...
      });
    } catch (e) {
      print('데이터 초기화 중 오류 발생: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _generateAllMatchesAndSave() async {
    final maleTeams = await _firestoreService.loadTeams("남성 복식 팀");
    final femaleTeams = await _firestoreService.loadTeams("여성 복식 팀");
    final mixedTeams = await _firestoreService.loadTeams("혼성 복식 팀");

    matchTable.clear();

    void addMatches(String category, List<Team> teams, int maxDivision) {
      for (int division = 1; division <= maxDivision; division++) {
        var filteredTeams = teams.where((t) => t.division == division).toList();
        matchTable["${category}_$division"] = _createMatches(filteredTeams, category, division);
      }
    }

    addMatches("남성", maleTeams, divisionInfo["남성"] ?? 1);
    addMatches("여성", femaleTeams, divisionInfo["여성"] ?? 1);
    addMatches("혼성", mixedTeams, divisionInfo["혼성"] ?? 1);

    // 대회 ID와 함께 저장
    await _firestoreService.saveMatches(matchTable, widget.tournamentId);

  }

  List<Match> _createMatches(List<Team> teams, String category, int division) {
    List<Match> matches = [];
    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        matches.add(Match(
          id: "${teams[i].id} VS ${teams[j].id}",
          team1: teams[i],
          team2: teams[j],
          division: division,
        ));
      }
    }
    return matches;
  }

  void _updateMatchScore(Match match, int team1Score, int team2Score, String gender) async {
    try {
      setState(() {
        match.team1Score = team1Score;
        match.team2Score = team2Score;
        match.isCompleted = true;
      });

      // 대회 ID와 함께 경기 업데이트
      await _firestoreService.updateMatch(
          tournamentId: widget.tournamentId,
          match: match,
          gender : gender
      );
    } catch (e) {
      print('점수 업데이트 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('점수 저장에 실패했습니다. ${gender.toString()}')),
      );
    }
  }

  //점수 다이얼로그
  void _showScoreDialog(Match match, String gender) {
    final team1Controller = TextEditingController();
    final team2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${match.team1.id} vs ${match.team2.id}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: team1Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "${match.team1.id} 점수",
              ),
            ),
            TextField(
              controller: team2Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "${match.team2.id} 점수",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("취소"),
          ),
          TextButton(
            onPressed: () {
              final team1Score = int.tryParse(team1Controller.text);
              final team2Score = int.tryParse(team2Controller.text);

              if (team1Score != null && team2Score != null) {
                _updateMatchScore(match, team1Score, team2Score, gender);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('유효한 점수를 입력해주세요.')),
                );
              }
            },
            child: Text(match.isCompleted ? "수정" : "저장"),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTable(List<Match> matches) {
    final teams = _getUniqueTeams(matches);
    String gender = matches[0].team1.players[0].gender;  //남성,여성,혼성
    print("_buildMatchTable gender : ${gender.toString()}");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text("팀명")),
          ...teams.map((t) => DataColumn(label: Text(t.id))).toList(),
          DataColumn(label: Text("순위") )
        ],
        rows: teams.map((rowTeam) {
          return DataRow(
            cells: [
              DataCell(Text(rowTeam.id)),
              ...teams.map((colTeam) {

                if (rowTeam.id == colTeam.id) {
                  return DataCell(Container());
                }

                final match = matches.firstWhere(
                      (m) =>
                  (m.team1.id == rowTeam.id && m.team2.id == colTeam.id) ||
                      (m.team1.id == colTeam.id && m.team2.id == rowTeam.id),
                  orElse: () => Match(
                      id: '',
                      team1: rowTeam,
                      team2: colTeam,
                      division: rowTeam.division
                  ),
                );

                if (match.isCompleted) {
                  Text scoreString;
                  rowTeam.id == match.team2.id
                    ? scoreString = Text("${match.team2Score} - ${match.team1Score}")
                    : scoreString = Text("${match.team1Score} - ${match.team2Score}");

                  return DataCell(
                    Center(
                      child: scoreString
                    ),
                    onTap: () => _showScoreDialog(match, gender)
                  );
                }

                return DataCell(
                  InkWell(
                    onTap: () => _showScoreDialog(match, gender),
                    child: Icon(Icons.edit, size: 16),
                  ),
                );
              }).toList(),
              DataCell(Container(),)
            ],
          );
        }).toList(),
      ),
    );
  }

  List<Team> _getUniqueTeams(List<Match> matches) {
    final teams = <String, Team>{};
    for (var match in matches) {
      teams[match.team1.id] = match.team1;
      teams[match.team2.id] = match.team2;
    }
    return teams.values.toList();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("리그전 테이블")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: matchTable.keys.map((category) {
                    print("!@!@ $category");
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String?>(
                          value: category,
                          groupValue: selectedTableKey,
                          onChanged: (value) => setState(() => selectedTableKey = value),
                          toggleable: true,
                        ),
                        Text(category),
                      ],
                    );
                  }).toList(),
                ),
                if (selectedTableKey != null)
                  Expanded(
                    child: _buildMatchTable(matchTable[selectedTableKey!] ?? []),
                  ),
              ],
      ),
    );
  }
}
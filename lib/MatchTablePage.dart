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

  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _initializeMatchData();
  }

  //todo 기존 정보를 불러오는 것을 기본으로 두되, 새 게임 만들기 버튼 만들가

  Future<void> _initializeMatchData() async {
    try {
      print("init 시작 : ${_stopwatch.elapsedMilliseconds}");
      // 부 정보 로드
      divisionInfo = await _firestoreService.loadDivision("부");
      print("loadDivision 종료 ${_stopwatch.elapsedMilliseconds}");


      // 팀 정보 로드 및 경기 생성
      // await _generateAllMatchesAndSave(); //save까지함

      // 경기 정보 로드
      matchTable = await _firestoreService.loadMatches(); //이미 matchTable에 정보 있으니깐 최초 실행 때 불러오기 안해도 될 듯?
        //근데 또 사용자 입장에서 보면 동기화해야하니깐 불러오는게 낫겠다..
      print("loadMatches 종료 : ${_stopwatch.elapsedMilliseconds}");

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
    print("generateAllMatchesAndSave 시작 ${DateTime.now()}");
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

    // final rankings = _calculateRankings(matches); // ✅ 순위 정보 계산

    // 🧮 1. 팀별 통계 계산
    final teamStats = <String, Map<String, dynamic>>{};
    for (var team in teams) {
      teamStats[team.id] = {
        'wins': 0,
        'diff': 0,
        'team': team,
      };
    }

    for (var match in matches) {
      if (!match.isCompleted) continue;

      final team1 = match.team1.id;
      final team2 = match.team2.id;
      final t1Score = match.team1Score;
      final t2Score = match.team2Score;

      if (t1Score > t2Score) {
        teamStats[team1]!['wins'] += 1;
      } else {
        teamStats[team2]!['wins'] += 1;
      }

      teamStats[team1]!['diff'] += t1Score - t2Score;
      teamStats[team2]!['diff'] += t2Score - t1Score;
    }

    // 🏆 2. 순위 정렬
    final sortedTeams = [...teamStats.values];
    sortedTeams.sort((a, b) {
      int winCompare = (b['wins'] as int).compareTo(a['wins'] as int);
      if (winCompare != 0) return winCompare;
      return (b['diff'] as int).compareTo(a['diff'] as int);
    });

    // 순위 기록
    for (int i = 0; i < sortedTeams.length; i++) {
      String id = (sortedTeams[i]['team'] as Team).id;
      teamStats[id]!['rank'] = i + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text("팀명")),
          ...teams.map((t) => DataColumn(label: Text(t.id))).toList(),
          DataColumn(label: Text("순위") ),
          DataColumn(label: Text("승점") ),
          DataColumn(label: Text("득실") )
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
              DataCell(
                Text("${teamStats[rowTeam.id]!["rank"].toString()}",
                style: TextStyle(fontWeight: FontWeight.bold),
                )), // ✅ 순위 표시
              DataCell(Text("${teamStats[rowTeam.id]!['wins']}")),
              DataCell(Text("${teamStats[rowTeam.id]!['diff']}")),
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

  /// 팀별 승수, 득실차 계산 후 정렬하여 순위를 반환
  Map<String, int> _calculateRankings(List<Match> matches) {
    final Map<String, int> wins = {};      // 팀별 승수
    final Map<String, int> scoreDiff = {}; // 팀별 득실차

    for (var match in matches) {
      if (!match.isCompleted) continue;

      final team1Id = match.team1.id;
      final team2Id = match.team2.id;

      // 기본값 초기화
      wins.putIfAbsent(team1Id, () => 0);
      wins.putIfAbsent(team2Id, () => 0);
      scoreDiff.putIfAbsent(team1Id, () => 0);
      scoreDiff.putIfAbsent(team2Id, () => 0);

      // 승자 판별 및 승수 반영
      if (match.team1Score > match.team2Score) {
        wins[team1Id] = wins[team1Id]! + 1;
      } else {
        wins[team2Id] = wins[team2Id]! + 1;
      }

      // 득실차 계산
      scoreDiff[team1Id] = scoreDiff[team1Id]! + (match.team1Score - match.team2Score);
      scoreDiff[team2Id] = scoreDiff[team2Id]! + (match.team2Score - match.team1Score);
    }

    // 순위 계산용 리스트 (teamId, wins, diff)
    final List<Map<String, dynamic>> teamStats = wins.keys.map((id) {
      return {
        'id': id,
        'wins': wins[id]!,
        'diff': scoreDiff[id]!,
      };
    }).toList();

    // 정렬: 승수 → 득실차 순
    teamStats.sort((a, b) {
      int aWins = a['wins'] as int;
      int bWins = b['wins'] as int;
      int winCompare = bWins.compareTo(aWins);
      if (winCompare != 0) return winCompare;

      int aDiff = a['diff'] as int;
      int bDiff = b['diff'] as int;
      return bDiff.compareTo(aDiff);
    });


    // 순위 매핑
    final Map<String, int> ranks = {};
    for (int i = 0; i < teamStats.length; i++) {
      ranks[teamStats[i]['id'].toString()] = i + 1;
    }

    return ranks;
  }

  void debugPrint(){
    print("클릭 : ${_stopwatch.elapsedMilliseconds}");
  }

  void newGame()async{
    setState(() {
      isLoading = true;
    });
    await _generateAllMatchesAndSave();
    Map<String, List<Match>> newMatchTable = await _firestoreService.loadMatches();
    setState(() {
      matchTable = newMatchTable;
      isLoading = false;
      selectedTableKey = newMatchTable.keys.isNotEmpty ? newMatchTable.keys.first : null;
    });

  }


  //note build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("리그전 테이블")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    ElevatedButton(onPressed: debugPrint, child: Text("시간 출력")
                    ),
                    ElevatedButton(onPressed: newGame, child: Text("새로운 게임 생성"))
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: matchTable.keys.map((category) {
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
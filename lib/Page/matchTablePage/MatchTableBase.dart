import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';

abstract class MatchTableBase extends StatefulWidget {
  final String tournamentId;
  final bool isAdmin;

  const MatchTableBase({
    super.key,
    required this.tournamentId,
    required this.isAdmin,
  });
}

abstract class MatchTableBaseState<T extends MatchTableBase> extends State<T> {
  final FirestoreService _firestoreService = FirestoreService();

  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();
  String? selectedTableKey;

  Map<String, List<Match>> matchTable = {};




  @override
  void dispose() {
    verticalController.dispose();
    horizontalController.dispose();
    super.dispose();
  }

  //note build
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Match>>(
      stream: _firestoreService.watchAllMatches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final matches = snapshot.data!;
        final Map<String, List<Match>> matchTable = {};

        for (var match in matches) {
          final p1Gender = match.team1.players[0].gender;
          final p2Gender = match.team1.players[1].gender;

          // ⚡ 혼성인지 판단
          final isMixed = p1Gender != p2Gender;
          final category = isMixed ? "혼성" : p1Gender;


          // 그룹까지 포함한 key 구성
          final key = "${category}_${match.division}${match.group != null ? "_${match.group}" : ""}";
          matchTable.putIfAbsent(key, () => []).add(match);
        }

        final tableKeys = matchTable.keys.toList()..sort();
        selectedTableKey ??= tableKeys.isNotEmpty ? tableKeys.first : null;

        return Scaffold(
          body: matchTable.isEmpty
              ? widget.isAdmin
              ? Center(
            child: ElevatedButton(
              onPressed: _showStartDialog,
              child: const Text("리그전 시작"),
            ),
          )
              : const Center(child: Text("경기 데이터가 아직 생성되지 않았습니다."))
              : Center(
            child: Column(
              children: [
                SizedBox(height: 8,),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: tableKeys.map((key) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String?>(
                          value: key,
                          groupValue: selectedTableKey,
                          onChanged: (value) =>
                              setState(() => selectedTableKey = value),
                          toggleable: true,
                        ),
                        Text(key),
                      ],
                    );
                  }).toList(),
                ),
                SizedBox(height: 8,),
                if (selectedTableKey != null)
                  Expanded(
                      child: buildMatchTable(
                          matchTable[selectedTableKey!] ?? [])),
              ],
            ),
          ),

          floatingActionButton: matchTable.isNotEmpty && widget.isAdmin
              ? FutureBuilder<bool>(
            future: _shouldShowFinalButton(), // 🔽 비동기 체크 함수 추가
            builder: (context, snapshot) {
              if (!snapshot.hasData) return FloatingActionButton.extended(
                onPressed: _showStartDialog,
                icon: const Icon(Icons.replay),
                label: const Text("리그전 새로 시작"),
              );

              final canShowFinal = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.extended(
                    onPressed: _showStartDialog,
                    icon: const Icon(Icons.replay),
                    label: const Text("리그전 새로 시작"),
                    backgroundColor: Colors.white,
                  ),
                ],
              );
            },
          )
              : null,

        );
      },
    );
  }

  Future<bool> _shouldShowFinalButton() async {
    if (selectedTableKey == null) return false;

    final keyParts = selectedTableKey!.split("_");
    final gender = keyParts[0];
    final division = int.tryParse(keyParts[1]) ?? 1;

    // 그룹이 있으면 A/B 모두 확인
    final hasGroup = keyParts.length == 3;
    if (hasGroup) {
      return await isGroupStageCompleted(gender, division);
    }

    // 단일 조인 경우 현재 matchTable에서 해당 match들만 추출해서 확인
    final matches = matchTable[selectedTableKey!] ?? [];
    return _isAllMatchesCompleted(matches);
  }


  bool _isAllMatchesCompleted(List<Match> matches) {
    return matches.every((m) => m.isCompleted);
  }

  /// 선택된 division의 A, B 그룹 경기가 모두 완료되었는지 확인
  Future<bool> isGroupStageCompleted(String gender, int division) async {
    final matchMap = await _firestoreService.loadMatches(); // category_division[_group] 구조

    final groupAKey = "${gender}_${division}_A";
    final groupBKey = "${gender}_${division}_B";

    final aMatches = matchMap[groupAKey] ?? [];
    final bMatches = matchMap[groupBKey] ?? [];

    final allCompletedA = aMatches.isNotEmpty && aMatches.every((m) => m.isCompleted);
    final allCompletedB = bMatches.isNotEmpty && bMatches.every((m) => m.isCompleted);

    return allCompletedA && allCompletedB;
  }


  ///리그전 새로 시작
  Future<void> _showStartDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("리그전 시작"),
        content: const Text("현재 팀 구성으로 리그전을 생성하시겠습니까?\n기존 경기 기록은 덮어쓰기됩니다."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("취소")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("예")),
        ],
      ),
    );

    if (result == true) {
      await _generateAndSaveMatches();
    }
  }

  Future<void> _generateAndSaveMatches() async {
    // ✅ 기존 예선 match 삭제
    await _firestoreService.deletePreliminaryMatches(widget.tournamentId);

    final maleTeams = await _firestoreService.loadTeams("남성 복식 팀");
    final femaleTeams = await _firestoreService.loadTeams("여성 복식 팀");
    final mixedTeams = await _firestoreService.loadTeams("혼성 복식 팀");

    final divisionInfo = await _firestoreService.loadDivision("부");
    matchTable.clear(); // 기존 메모리 초기화

    await _processCategory("남성", maleTeams, divisionInfo["남성"] ?? 1);
    await _processCategory("여성", femaleTeams, divisionInfo["여성"] ?? 1);
    await _processCategory("혼성", mixedTeams, divisionInfo["혼성"] ?? 1);

    await _firestoreService.saveMatches(matchTable, widget.tournamentId);
  }


  Future<void> _processCategory(
      String category, List<Team> teams, int maxDivision) async {
    for (int division = 1; division <= maxDivision; division++) {
      final filtered = teams.where((t) => t.division == division).toList();

      if (filtered.length >= 6) {
        final shouldSplit =
        await _askGroupSplit(category, division, filtered.length);

        if (shouldSplit) {
          _splitTeamsIntoGroups(filtered); // A, B 조 나누기
          final aGroup = filtered.where((t) => t.group == "A").toList();
          final bGroup = filtered.where((t) => t.group == "B").toList();

          matchTable["${category}_${division}_A"] =
              _createMatches(aGroup, category, division);
          matchTable["${category}_${division}_B"] =
              _createMatches(bGroup, category, division);
          continue;
        }
      }

      matchTable["${category}_$division"] =
          _createMatches(filtered, category, division);
    }
  }

  Future<bool> _askGroupSplit(
      String category, int division, int teamCount) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$category $division부"),
        content: Text("팀 수가 $teamCount팀입니다.\nA/B조로 나누시겠습니까?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("단일 조")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("A/B 조 나누기")),
        ],
      ),
    ) ??
        false;
  }

  void _splitTeamsIntoGroups(List<Team> teams) {
    teams.shuffle(); // 랜덤 섞기
    for (int i = 0; i < teams.length; i++) {
      teams[i].group = (i % 2 == 0) ? "A" : "B";
    }
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
            group: teams[i].group));
      }
    }
    return matches;
  }

  ///점수 입력 다이얼로그
  void showScoreDialog(Match match, String gender) {
    final team1Controller = TextEditingController();
    final team2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${match.team1.id}  vs  ${match.team2.id}"),
        content: SizedBox(
          width: 300, // 다이얼로그 전체 너비 제한
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextField(
                    controller: team1Controller,
                    decoration: InputDecoration(
                      labelText: "${match.team1.id} 점수",
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: TextField(
                    controller: team2Controller,
                    decoration: InputDecoration(
                      labelText: "${match.team2.id} 점수",
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              final t1 = int.tryParse(team1Controller.text);
              final t2 = int.tryParse(team2Controller.text);
              if (t1 != null && t2 != null) {
                _updateMatchScore(match, t1, t2, gender);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("유효한 점수를 입력해주세요")),
                );
              }
            },
            child: Text(match.isCompleted ? "수정" : "저장"),
          ),
        ],
      ),
    );

  }

  Map<String, Map<String, dynamic>> calculateStats(
      List<Match> matches, List<Team> teams) {
    final stats = <String, Map<String, dynamic>>{};
    for (var team in teams) {
      stats[team.id] = {'wins': 0, 'diff': 0, 'team': team};
    }

    for (var match in matches) {
      if (!match.isCompleted) continue;
      final t1 = match.team1.id,
          t2 = match.team2.id,
          s1 = match.team1Score,
          s2 = match.team2Score;
      if (s1 > s2)
        stats[t1]!['wins'] += 1;
      else
        stats[t2]!['wins'] += 1;
      stats[t1]!['diff'] += s1 - s2;
      stats[t2]!['diff'] += s2 - s1;
    }

    final sorted = [...stats.values]..sort((a, b) {
      int w = (b['wins'] as int).compareTo(a['wins'] as int);
      return w != 0 ? w : (b['diff'] as int).compareTo(a['diff'] as int);
    });

    for (int i = 0; i < sorted.length; i++) {
      final id = (sorted[i]['team'] as Team).id;
      stats[id]!['rank'] = i + 1;
    }

    return stats;
  }

  void _updateMatchScore(Match match, int s1, int s2, String gender) async {
    match.team1Score = s1;
    match.team2Score = s2;
    match.isCompleted = true;
    await _firestoreService.updateMatch(
      tournamentId: widget.tournamentId,
      match: match,
      gender: gender,
    );
    // 경기 완료 상태 갱신
    await _firestoreService.updateGroupCompletionStatus(
      tournamentId: widget.tournamentId,
      gender: gender,
      division: match.division,
      group: match.group, // null일 수도 있음
    );
  }

  List<Team> getUniqueTeams(List<Match> matches) {
    final map = <String, Team>{};
    for (var m in matches) {
      map[m.team1.id] = m.team1;
      map[m.team2.id] = m.team2;
    }
    return map.values.toList();
  }

  /// 자식 클래스에서 override
  Widget buildMatchTable(List<Match> matches);
}

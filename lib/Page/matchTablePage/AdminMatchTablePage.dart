import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';
import 'MatchTableBase.dart';

class AdminMatchTablePage extends MatchTableBase {
  const AdminMatchTablePage({super.key, required String tournamentId})
      : super(tournamentId: tournamentId, isAdmin: true);

  @override
  _AdminMatchTablePageState createState() => _AdminMatchTablePageState();
}

class _AdminMatchTablePageState
    extends MatchTableBaseState<AdminMatchTablePage> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _generateAllMatchesAndSave() async {
    setState(() => isLoading = true);

    final maleTeams = await _firestoreService.loadTeams("남성 복식 팀");
    final femaleTeams = await _firestoreService.loadTeams("여성 복식 팀");
    final mixedTeams = await _firestoreService.loadTeams("혼성 복식 팀");

    matchTable.clear();

    void addMatches(String category, List<Team> teams, int maxDiv) {
      for (int division = 1; division <= maxDiv; division++) {
        final filtered = teams.where((t) => t.division == division).toList();
        matchTable["${category}_$division"] = _createMatches(filtered, category, division);
      }
    }

    addMatches("남성", maleTeams, divisionInfo["남성"] ?? 1);
    addMatches("여성", femaleTeams, divisionInfo["여성"] ?? 1);
    addMatches("혼성", mixedTeams, divisionInfo["혼성"] ?? 1);

    await _firestoreService.saveMatches(matchTable, widget.tournamentId);

    setState(() {
      isLoading = false;
      selectedTableKey = matchTable.keys.firstOrNull;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("운영자 - 점수 테이블")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _generateAllMatchesAndSave,
                child: const Text("새로운 게임 생성"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: matchTable.keys.map((key) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String?>(
                    value: key,
                    groupValue: selectedTableKey,
                    onChanged: (value) => setState(() => selectedTableKey = value),
                    toggleable: true,
                  ),
                  Text(key),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (selectedTableKey != null)
            Expanded(
              child: buildMatchTable(matchTable[selectedTableKey!] ?? []),
            )
          else
            const Text("표시할 경기가 없습니다."),
        ],
      ),
    );
  }
}

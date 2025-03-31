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

  Map<String, List<Match>> matchTable = {};
  Map<String, int> divisionInfo = {};
  String? selectedTableKey;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _loadMatchData() async {
    divisionInfo = await _firestoreService.loadDivision("부");
    matchTable = await _firestoreService.loadMatches();
    setState(() {
      isLoading = false;
      selectedTableKey = matchTable.keys.isNotEmpty ? matchTable.keys.first : null;
    });
  }

  void _updateMatchScore(Match match, int team1Score, int team2Score, String gender) async {
    setState(() {
      match.team1Score = team1Score;
      match.team2Score = team2Score;
      match.isCompleted = true;
    });

    await _firestoreService.updateMatch(
      tournamentId: widget.tournamentId,
      match: match,
      gender: gender,
    );
  }

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
              decoration: InputDecoration(labelText: "${match.team1.id} 점수"),
            ),
            TextField(
              controller: team2Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "${match.team2.id} 점수"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
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

  Widget buildMatchTable(List<Match> matches) {
    final teams = _getUniqueTeams(matches);
    final gender = matches[0].team1.players[0].gender;

    final teamStats = <String, Map<String, dynamic>>{};
    for (var team in teams) {
      teamStats[team.id] = {'wins': 0, 'diff': 0, 'team': team};
    }

    for (var match in matches) {
      if (!match.isCompleted) continue;
      final t1 = match.team1.id;
      final t2 = match.team2.id;
      final s1 = match.team1Score;
      final s2 = match.team2Score;

      if (s1 > s2) {
        teamStats[t1]!['wins'] += 1;
      } else {
        teamStats[t2]!['wins'] += 1;
      }
      teamStats[t1]!['diff'] += s1 - s2;
      teamStats[t2]!['diff'] += s2 - s1;
    }

    final sorted = [...teamStats.values]..sort((a, b) {
      int w = (b['wins'] as int).compareTo(a['wins'] as int);
      return w != 0 ? w : (b['diff'] as int).compareTo(a['diff'] as int);
    });

    for (int i = 0; i < sorted.length; i++) {
      final id = (sorted[i]['team'] as Team).id;
      teamStats[id]!['rank'] = i + 1;
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text("팀명")),
            ...teams.map((t) => DataColumn(label: Text(t.id))).toList(),
            const DataColumn(label: Text("순위")),
            const DataColumn(label: Text("승점")),
            const DataColumn(label: Text("득실"))
          ],
          rows: teams.map((rowTeam) {
            return DataRow(
              cells: [
                DataCell(Text(rowTeam.id)),
                ...teams.map((colTeam) {
                  if (rowTeam.id == colTeam.id) return const DataCell(SizedBox());

                  final match = matches.firstWhere(
                        (m) => (m.team1.id == rowTeam.id && m.team2.id == colTeam.id) ||
                        (m.team2.id == rowTeam.id && m.team1.id == colTeam.id),
                    orElse: () => Match(id: '', team1: rowTeam, team2: colTeam, division: rowTeam.division),
                  );

                  if (match.isCompleted) {
                    final score = rowTeam.id == match.team2.id
                        ? "${match.team2Score} - ${match.team1Score}"
                        : "${match.team1Score} - ${match.team2Score}";

                    return DataCell(Center(child: Text(score)));
                  }

                  // 🛑 사용자 버전이면 연필 아이콘도 안 보임
                  if (!widget.isAdmin) return const DataCell(SizedBox());

                  return DataCell(
                    InkWell(
                      onTap: () => _showScoreDialog(match, gender),
                      child: const Icon(Icons.edit, size: 16),
                    ),
                  );
                }).toList(),
                DataCell(Text("${teamStats[rowTeam.id]!["rank"]}")),
                DataCell(Text("${teamStats[rowTeam.id]!["wins"]}")),
                DataCell(Text("${teamStats[rowTeam.id]!["diff"]}")),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Team> _getUniqueTeams(List<Match> matches) {
    final teams = <String, Team>{};
    for (var m in matches) {
      teams[m.team1.id] = m.team1;
      teams[m.team2.id] = m.team2;
    }
    return teams.values.toList();
  }

  @override
  Widget build(BuildContext context);
}

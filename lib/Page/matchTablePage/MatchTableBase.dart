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

  @override
  void dispose() {
    verticalController.dispose();
    horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Match>>(
      stream: _firestoreService.watchAllMatches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final matches = snapshot.data!;
        final Map<String, List<Match>> matchTable = {};

        for (var match in matches) {
          final key = "${match.team1.players[0].gender}_${match.division}";
          matchTable.putIfAbsent(key, () => []).add(match);
        }

        final tableKeys = matchTable.keys.toList()..sort();
        selectedTableKey ??= tableKeys.isNotEmpty ? tableKeys.first : null;

        return Column(
          children: [
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
                      onChanged: (value) => setState(() => selectedTableKey = value),
                      toggleable: true,
                    ),
                    Text(key),
                  ],
                );
              }).toList(),
            ),
            if (selectedTableKey != null)
              Expanded(child: buildMatchTable(matchTable[selectedTableKey!] ?? [])),
          ],
        );
      },
    );
  }

  void showScoreDialog(Match match, String gender) {
    final team1Controller = TextEditingController();
    final team2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${match.team1.id} vs ${match.team2.id}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: team1Controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "${match.team1.id} 점수")),
            TextField(controller: team2Controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "${match.team2.id} 점수")),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("유효한 점수를 입력해주세요")));
              }
            },
            child: Text(match.isCompleted ? "수정" : "저장"),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, dynamic>> calculateStats(List<Match> matches, List<Team> teams) {
    final stats = <String, Map<String, dynamic>>{};
    for (var team in teams) {
      stats[team.id] = {'wins': 0, 'diff': 0, 'team': team};
    }

    for (var match in matches) {
      if (!match.isCompleted) continue;
      final t1 = match.team1.id, t2 = match.team2.id, s1 = match.team1Score, s2 = match.team2Score;
      if (s1 > s2) stats[t1]!['wins'] += 1; else stats[t2]!['wins'] += 1;
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

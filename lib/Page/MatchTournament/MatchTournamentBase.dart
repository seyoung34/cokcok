import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';

abstract class MatchTournamentBase extends StatefulWidget {
  final String tournamentId;
  final String gender;
  final bool isAdmin;

  const MatchTournamentBase({
    super.key,
    required this.tournamentId,
    required this.gender,
    required this.isAdmin,
  });
}

abstract class MatchTournamentBaseState<T extends MatchTournamentBase> extends State<T> {
  List<Match> semiFinals = [];
  Match? thirdPlaceMatch;
  Match? finalMatch;

  final FirestoreService _firestoreService = FirestoreService();
  String? selectedDivision;
  List<String> divisions = [];

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    final result = await _firestoreService.getFinalDivisions(widget.gender);
    setState(() {
      divisions = result;
      selectedDivision = result.isNotEmpty ? result.first : null;
    });
  }

  Future<void> generateFinalStageMatches(String tournamentId, String gender, int division) async {
    final matchMap = await _firestoreService.loadMatches();
    final key = "${gender}_${division}_본선_준결승";
    final semiFinalMatches = matchMap[key] ?? [];

    if (semiFinalMatches.length < 2 || !semiFinalMatches.every((m) => m.isCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("준결승 경기가 모두 완료되어야 생성할 수 있습니다.")),
      );
      return;
    }

    final semi1 = semiFinalMatches[0];
    final semi2 = semiFinalMatches[1];

    final semi1Winner = semi1.team1Score > semi1.team2Score ? semi1.team1 : semi1.team2;
    final semi1Loser = semi1.team1Score < semi1.team2Score ? semi1.team1 : semi1.team2;
    final semi2Winner = semi2.team1Score > semi2.team2Score ? semi2.team1 : semi2.team2;
    final semi2Loser = semi2.team1Score < semi2.team2Score ? semi2.team1 : semi2.team2;

    final finalMatch = Match(
      id: "결승",
      team1: semi1Winner,
      team2: semi2Winner,
      division: division,
      group: "본선_결승",
    );

    final thirdPlaceMatch = Match(
      id: "3·4위전",
      team1: semi1Loser,
      team2: semi2Loser,
      division: division,
      group: "본선_3·4위",
    );

    await _firestoreService.saveTournamentMatches(
      tournamentId: tournamentId,
      gender: gender,
      division: division,
      matches: [finalMatch, thirdPlaceMatch],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("결승 및 3·4위 경기가 생성되었습니다.")),
    );
  }

  Widget buildFinalizeButton() {
    if (!widget.isAdmin || selectedDivision == null) return const SizedBox();

    final division = int.tryParse(selectedDivision!) ?? 1;

    return ElevatedButton.icon(
      icon: const Icon(Icons.emoji_events),
      label: const Text("승리 확정 (결승/3·4위 생성)"),
      onPressed: () =>
          generateFinalStageMatches(widget.tournamentId, widget.gender, division),
    );
  }

  /// ✅ 자식 클래스에서 구현할 UI
  Widget buildTournamentUI(List<Match> matches);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.gender} 본선 토너먼트")),
      body: Column(
        children: [
          if (divisions.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: divisions.map((div) {
                return ChoiceChip(
                  label: Text("$div 부"),
                  selected: selectedDivision == div,
                  onSelected: (_) => setState(() => selectedDivision = div),
                );
              }).toList(),
            ),
          if (selectedDivision != null)
            Expanded(
              child: StreamBuilder<List<Match>>(
                stream: _firestoreService.watchTournamentMatches(
                    widget.tournamentId, widget.gender, int.parse(selectedDivision!)),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return buildTournamentUI(snapshot.data!);
                },
              ),
            ),
          const SizedBox(height: 12),
          buildFinalizeButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

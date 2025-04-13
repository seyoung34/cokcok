import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';
import 'MatchTournamentBase.dart';

class AdminMatchTournamentPage extends MatchTournamentBase {
  const AdminMatchTournamentPage({
    super.key,
    required super.tournamentId,
  }) : super(isAdmin: true);

  @override
  State<AdminMatchTournamentPage> createState() => _AdminMatchTournamentPageState();
}

class _AdminMatchTournamentPageState
    extends MatchTournamentBaseState<AdminMatchTournamentPage> {

  /// ✅ 점수 입력 다이얼로그
  void _showScoreDialog(Match match) {
    final team1Controller = TextEditingController(text: match.team1Score?.toString());
    final team2Controller = TextEditingController(text: match.team2Score?.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${match.team1.id} vs ${match.team2.id}"),
        content: SizedBox(
          width: 300,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextField(
                    controller: team1Controller,
                    decoration: InputDecoration(
                      labelText: match.team1.id,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: TextField(
                    controller: team2Controller,
                    decoration: InputDecoration(
                      labelText: match.team2.id,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
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
            onPressed: () async {
              final s1 = int.tryParse(team1Controller.text);
              final s2 = int.tryParse(team2Controller.text);

              if (s1 == null || s2 == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("숫자를 입력하세요")),
                );
                return;
              }

              match.team1Score = s1;
              match.team2Score = s2;
              match.isCompleted = true;

              await firestoreService.updateTournamentMatch(
                tournamentId: widget.tournamentId,
                gender: match.team1.players[0].gender,
                division: match.division,
                match: match,
              );

              Navigator.pop(context);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  /// 각 경기 박스를 표시하는 UI 구성 함수
  /*Widget buildMatchBox(Match? match, {Color? highlightColor}) {
    // null 또는 유효하지 않은 매치인 경우 기본 박스만 표시 (공간 유지)
    if (match == null || match.team1.id.isEmpty || match.team2.id.isEmpty) {
      return Container(
        width: 220,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Text("대기 중", style: TextStyle(color: Colors.grey)),
      );
    }

    final team1 = match.team1.id;
    final team2 = match.team2.id;
    final score1 = match.team1Score?.toString() ?? "";
    final score2 = match.team2Score?.toString() ?? "";

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlightColor ?? Colors.grey[200],
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text("$team1 ${score1.isNotEmpty ? "($score1)" : ""}"),
          const SizedBox(height: 8),
          Text("$team2 ${score2.isNotEmpty ? "($score2)" : ""}"),
        ],
      ),
    );
  }


  /// ✅ 실제 토너먼트 UI 구현
  @override
  /// 토너먼트 UI 배치 (준결승 2경기 → 결승/3·4위전)
  Widget buildTournamentLayout(List<Match> matches) {

    // return Container(
    //   width: 800,
    //   height: 500,
    //   decoration: BoxDecoration(
    //     borderRadius: BorderRadius.circular(8),
    //     border: Border.all(color: Colors.green)
    //   ),
    // );

    final semiFinals = matches.where((m) => m.group == "본선_준결승").toList();
    final finalMatch = matches.firstWhere(
          (m) => m.group == "본선_결승",
      orElse: () => Match.empty(),
    );
    final thirdMatch = matches.firstWhere(
          (m) => m.group == "본선_3·4위",
      orElse: () => Match.empty(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 500),
        child: Stack(
          children: [
            // 준결승 1
            Positioned(
              left: 0,
              top: 80,
              child: GestureDetector(
                onTap: semiFinals.length > 0 ? () => _showScoreDialog(semiFinals[0]) : null,
                child: buildMatchBox(semiFinals.length > 0 ? semiFinals[0] : null),
              ),
            ),

            // 준결승 2
            Positioned(
              left: 0,
              top: 220,
              child: GestureDetector(
                onTap: semiFinals.length > 1 ? () => _showScoreDialog(semiFinals[1]) : null,
                child: buildMatchBox(semiFinals.length > 1 ? semiFinals[1] : null),
              ),
            ),

            // 결승
            Positioned(
              left: 240,
              top: 150,
              child: buildMatchBox(
                finalMatch.id.isNotEmpty ? finalMatch : null,
                highlightColor: Colors.amber[100],
              ),
            ),

            // 3·4위전
            Positioned(
              left: 240,
              top: 290,
              child: buildMatchBox(
                thirdMatch.id.isNotEmpty ? thirdMatch : null,
                highlightColor: Colors.blue[50],
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  @override
  Widget buildTournamentLayout(List<Match> matches) {
    final semiFinals = matches.where((m) => m.group == "본선_준결승").toList();
    final finalMatch = matches.firstWhere(
          (m) => m.group == "본선_결승",
      orElse: () => Match.empty(),
    );
    final thirdMatch = matches.firstWhere(
          (m) => m.group == "본선_3·4위",
      orElse: () => Match.empty(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("✅ [테스트용 토너먼트 레이아웃]", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text("총 경기 수: ${matches.length}"),
          Text("준결승 수: ${semiFinals.length}"),
          Text("결승 존재: ${finalMatch.id.isNotEmpty}"),
          Text("3·4위전 존재: ${thirdMatch.id.isNotEmpty}"),
          const Divider(),

          const Text("▶ 준결승 1"),
          if (semiFinals.isNotEmpty) buildMatchBox(semiFinals[0]) else const Text("없음"),
          const SizedBox(height: 16),

          const Text("▶ 준결승 2"),
          if (semiFinals.length > 1) buildMatchBox(semiFinals[1]) else const Text("없음"),
          const SizedBox(height: 16),

          const Text("▶ 결승"),
          buildMatchBox(finalMatch.id.isNotEmpty ? finalMatch : null, highlightColor: Colors.amber[50]),
          const SizedBox(height: 16),

          const Text("▶ 3·4위전"),
          buildMatchBox(thirdMatch.id.isNotEmpty ? thirdMatch : null, highlightColor: Colors.blue[50]),
        ],
      ),
    );
  }


}

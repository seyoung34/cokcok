import 'package:flutter/material.dart';
import '../../model/Match.dart';
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

  bool _showLines = false; // 상태 변수 추가

  @override
  void paintLine() {
    setState(() {
      _showLines = true; // 선 보이도록 설정
    });
  }


  /// ✅ 점수 입력 다이얼로그 (운영자 전용)
  void _showScoreDialog(Match match) {
    final team1Controller = TextEditingController(text: match.team1Score?.toString() == "0" ? "" : match.team1Score?.toString());
    final team2Controller = TextEditingController(text: match.team2Score?.toString() == "0" ? "" : match.team2Score?.toString());
    print("Admin team1Controller : ${team1Controller}");


    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${match.team1.id} vs ${match.team2.id}"),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: team1Controller,
                decoration: InputDecoration(labelText: match.team1.id),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: team2Controller,
                decoration: InputDecoration(labelText: match.team2.id),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () async {
              final s1 = int.tryParse(team1Controller.text);
              final s2 = int.tryParse(team2Controller.text);
              if (s1 == null || s2 == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("점수를 숫자로 입력해주세요")),
                );
                return;
              }

              match.team1Score = s1;
              match.team2Score = s2;
              match.isCompleted = true;

              final gender = selectedDivision!.split("_")[0];
              final division = int.tryParse(selectedDivision!.split("_")[1]) ?? 1;

              await firestoreService.updateTournamentMatch(
                tournamentId: widget.tournamentId,
                gender: gender,
                division: division,
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

  /// ✅ 본선 레이아웃 UI 구성 (준결승 → 결승/3·4위)
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

    return SizedBox(
      width: 600,
      height: 500,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 준결승 1
          Positioned(
            left: 0,
            top: 80,
            child: buildMatchBox(
              semiFinals.length > 0 ? semiFinals[0] : null,
              "준결승 1"
            ),
          ),

          // 준결승 2
          Positioned(
            left: 0,
            top: 250,
            child: buildMatchBox(
              semiFinals.length > 1 ? semiFinals[1] : null,
              "준결승 2"
            ),
          ),

          // 결승
          Positioned(
            left: 350,
            top: 170,
            child: buildMatchBox(
              finalMatch.id.isNotEmpty ? finalMatch : null,
              "결승",
              highlightColor: Colors.amber[100],
            ),
          ),

          // 3·4위전
          Positioned(
            left: 300,
            top: 370,
            child: buildMatchBox(
              thirdMatch.id.isNotEmpty ? thirdMatch : null,
              "3·4위전",
              highlightColor: Colors.blue[50],
            ),
          ),

          if (_showLines && semiFinals.length == 2)
            IgnorePointer(
              child: Positioned.fill(
                child: CustomPaint(
                  painter: BracketLinePainter(
                    semi1: semiFinals[0],
                    semi2: semiFinals[1],
                  ),
                ),
              ),
            ),


        ],
      ),
    );
  }
}






import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import 'MatchTournamentBase.dart';

class UserMatchTournamentPage extends MatchTournamentBase {
  const UserMatchTournamentPage({
    super.key,
    required super.tournamentId,
  }) : super(isAdmin: false);

  @override
  State<UserMatchTournamentPage> createState() => _UserMatchTournamentPageState();
}

class _UserMatchTournamentPageState
    extends MatchTournamentBaseState<UserMatchTournamentPage> {

  bool _showLines = false; // 상태 변수 추가

  @override
  void paintLine() {
    setState(() {
      _showLines = true; // 선 보이도록 설정
    });
  }

  /// ✅ 사용자용 본선 UI (점수 입력/수정 불가)
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
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: SizedBox(
          height: 450,
          child: Stack(
            children: [
              const SizedBox(width: 500, height: 450),

              // 🏅 준결승 1
              Positioned(
                left: 0,
                top: 80,
                child: buildMatchBox(
                  semiFinals.length > 0 ? semiFinals[0] : null,
                  "준결승 1"
                ),
              ),

              // 🏅 준결승 2
              Positioned(
                left: 0,
                top: 220,
                child: buildMatchBox(
                  semiFinals.length > 1 ? semiFinals[1] : null,
                  "준결승 2"
                ),
              ),

              // 🥇 결승
              Positioned(
                left: 260,
                top: 150,
                child: buildMatchBox(
                  finalMatch.id.isNotEmpty ? finalMatch : null,
                  "결승",
                  highlightColor: Colors.amber[100],
                ),
              ),

              // 🥉 3·4위전
              Positioned(
                left: 260,
                top: 290,
                child: buildMatchBox(
                  thirdMatch.id.isNotEmpty ? thirdMatch : null,
                  "3·4위전",
                  highlightColor: Colors.blue[50],
                ),
              ),

              if (_showLines && semiFinals.length == 2)
                Positioned.fill(
                  child: CustomPaint(
                    painter: BracketLinePainter(
                      semi1: semiFinals[0],
                      semi2: semiFinals[1],
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }

}

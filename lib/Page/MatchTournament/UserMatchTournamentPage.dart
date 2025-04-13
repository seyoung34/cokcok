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
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: Stack(
        children: [
          // 준결승 1
          Positioned(
            left: 0,
            top: 80,
            child: buildMatchBox(semiFinals.isNotEmpty ? semiFinals[0] : null),
          ),
          // 준결승 2
          Positioned(
            left: 0,
            top: 220,
            child: buildMatchBox(semiFinals.length > 1 ? semiFinals[1] : null),
          ),
          // 결승
          Positioned(
            left: 240,
            top: 150,
            child: buildMatchBox(
              finalMatch.id == "" ? null : finalMatch,
              highlightColor: Colors.amber[100],
            ),
          ),
          // 3·4위전
          Positioned(
            left: 240,
            top: 290,
            child: buildMatchBox(
              thirdMatch.id == "" ? null : thirdMatch,
              highlightColor: Colors.blue[50],
            ),
          ),
        ],
      ),
    );
  }
}

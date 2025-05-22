import 'package:flutter/material.dart';
import 'package:flutter_tournament_bracket/flutter_tournament_bracket.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';
import 'UnifiedTournamentPage.dart';

class AdminTournamentPage extends TournamentUnifiedPage {
  const AdminTournamentPage({super.key}) : super(title: "운영자 토너먼트", isAdmin: true);

  @override
  AdminTournamentPageState createState() => AdminTournamentPageState();
}

class AdminTournamentPageState extends TournamentUnifiedPageState<AdminTournamentPage> {
  @override
  Widget buildMatchCard(TournamentMatch match) {
    return InkWell(
        onTap: () async {
          final matchId = match.id;
          final matches = await firestoreService.loadAllCurrentTournamentMatches(selectedCategory); // or 캐시된 전체 match 리스트
          final fullMatch = matches.firstWhere((m) => m.id == matchId);
          _showScoreDialog(fullMatch);
        },

        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: /*Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(match.teamA ?? "-", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(match.teamB ?? "-"),
            const SizedBox(height: 8),
            Text("Score: ${match.scoreTeamA ?? "-"} - ${match.scoreTeamB ?? "-"}"),
          ],
        ),*/
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            spacing: 12,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(match.teamA?.split("_").first == "빈 팀" ? "   " : match.teamA?.split("_").first ?? ""),
                  Text(match.teamA?.split("_").last == "빈 팀" ? "   " : match.teamA?.split("_").last ?? ""),
                  Text("${match.scoreTeamA}",style: TextStyle(fontSize: 18,color: Colors.red),)
                ],
              ),
              Container(
                height: 100,
                width: 1,
                color: Colors.black54,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(match.teamB?.split("_").first == "빈 팀" ? "   " : match.teamB?.split("_").first ?? ""),
                  Text(match.teamB?.split("_").last == "빈 팀" ? "   " : match.teamB?.split("_").last ?? ""),
                  Text("${match.scoreTeamB}",style: TextStyle(fontSize: 18,color: Colors.red),)
                ],
              )
            ],
          )
      ),
    );
  }

  void _showScoreDialog(Match match) {
    // final teamAController = TextEditingController(text: match.team1Score?.toString() ?? "");
    // final teamBController = TextEditingController(text: match.team2Score?.toString() ?? "");

    final teamAController = TextEditingController();
    final teamBController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${match.team1.id} vs ${match.team2.id}"),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: teamAController,
                decoration: InputDecoration(labelText: match.team1.id),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: teamBController,
                decoration: InputDecoration(labelText: match.team2.id),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              print("match : ${match.team1.id}-${match.team2.id}");
              final s1 = int.tryParse(teamAController.text);
              final s2 = int.tryParse(teamBController.text);

              if (s1 != null && s2 != null) {
                final winner = s1 > s2 ? match.team1.id : match.team2.id;

                final updated = match.copyWith(
                  team1Score: s1,
                  team2Score: s2,
                  isCompleted: true,
                  winnerTeamId: winner,
                );

                if(selectedCategory=="혼성 토너먼트"){
                  await firestoreService.updateTournamentScore(updated);
                }
                else if(selectedCategory == "남성 1부"){
                  await firestoreService.updateMaleTournamentScore(updated,1);
                }
                else if(selectedCategory == "남성 2부"){
                  await firestoreService.updateMaleTournamentScore(updated,2);
                }

                await tryRegisterWinnerToNextRound(
                  currentMatch: updated,
                  category: selectedCategory,
                );
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장되었습니다.")));
              }
              else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("유효한 점수를 입력해주세요.")));
              }
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  bool _isMaleFinalMatch(Match match) {
    return match.group == "round2" && match.id == "round2_0";
  }


  Future<void> tryRegisterWinnerToNextRound({
    required Match currentMatch,
    required String category,
  }) async {
    if (category.startsWith("남성")) {
      if (_isMaleFinalMatch(currentMatch)) {
        debugPrint("🏁 남성 결승전입니다. 다음 라운드 없음");
        return;
      }
    }

    final allMatches = await firestoreService.loadAllCurrentTournamentMatches(category);

    final matchInfo = _getNextMatchInfo(currentMatch);
    final nextGroup = matchInfo["nextGroup"];
    final nextMatchId = matchInfo["nextMatchId"];
    final isLeft = matchInfo["isLeft"];

    final winnerTeam = currentMatch.winnerTeamId == currentMatch.team1.id
        ? currentMatch.team1
        : currentMatch.team2;

    // 다음 라운드의 대상 경기 탐색
    final existingNextMatch = allMatches.firstWhere(
          (m) => m.group == nextGroup && m.id == nextMatchId,
      orElse: () => Match(
        id: nextMatchId,
        team1: Team.empty(),
        team2: Team.empty(),
        group: nextGroup,
        division: currentMatch.division,
        isCompleted: false
      ),
    );

    final updatedNextMatch = isLeft
        ? existingNextMatch.copyWith(team1: winnerTeam)
        : existingNextMatch.copyWith(team2: winnerTeam);

    final pathCategory = category == "혼성 토너먼트" ? "혼성 토너먼트" : "남성";

    await firestoreService.updateTournamentMatch(
      updatedNextMatch,
      pathCategory,
      currentMatch.division,
    );
  }


  /// 현재 match 기준으로 다음 라운드 group과 match id, isLeft 정보를 계산
  Map<String, dynamic> _getNextMatchInfo(Match currentMatch) {
    final regGroup = RegExp(r'round(\d+)');
    final regId = RegExp(r'round\d+_(\d+)');

    final groupMatch = regGroup.firstMatch(currentMatch.group ?? "");
    final idMatch = regId.firstMatch(currentMatch.id);

    if (groupMatch == null || idMatch == null) {
      throw Exception("Invalid group or match id format: ${currentMatch.group}, ${currentMatch.id}");
    }

    final currentRound = int.parse(groupMatch.group(1)!);
    final matchIndex = int.parse(idMatch.group(1)!);

    final nextGroup = "round${currentRound + 1}";
    final nextMatchIndex = matchIndex ~/ 2;
    final nextMatchId = "$nextGroup\_$nextMatchIndex";

    final isLeft = matchIndex % 2 == 0;

    return {
      "nextGroup": nextGroup,
      "nextMatchId": nextMatchId,
      "isLeft": isLeft,
    };
  }








}

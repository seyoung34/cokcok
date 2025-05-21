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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(match.teamA ?? "-", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(match.teamB ?? "-"),
            const SizedBox(height: 8),
            Text("Score: ${match.scoreTeamA ?? "-"} - ${match.scoreTeamB ?? "-"}"),
          ],
        ),
      ),
    );
  }

  void _showScoreDialog(Match match) {
    final teamAController = TextEditingController(text: match.team1Score?.toString() ?? "");
    final teamBController = TextEditingController(text: match.team2Score?.toString() ?? "");

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

                print("updated match : ${updated.team1}-${updated.team2}");

                await firestoreService.updateTournamentScore(updated);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장되었습니다.")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("유효한 점수를 입력해주세요.")));
              }
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

}

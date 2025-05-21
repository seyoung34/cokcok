// 혼성 리그전 및 본선 토너먼트 공통 화면 구성
// flutter_tournament_bracket 패키지를 사용한 토너먼트 UI

import 'package:flutter/material.dart';
import 'package:flutter_tournament_bracket/flutter_tournament_bracket.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';

abstract class TournamentLeaguePage extends StatefulWidget {
  final String title;
  final String teamCollectionName;
  final bool isAdmin;

  const TournamentLeaguePage({
    super.key,
    required this.title,
    required this.teamCollectionName,
    this.isAdmin = false,
  });

  @override
  TournamentLeaguePageState createState();
}

abstract class TournamentLeaguePageState<T extends TournamentLeaguePage> extends State<T> {
  final FirestoreService firestoreService = FirestoreService();
  List<Team> teams = [];
  List<Tournament> tournamentRounds = [];
  bool isLoading = true;

  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final result = await firestoreService.loadTeams("혼성 복식 팀");
    setState(() {
      teams = result;
      tournamentRounds = _generateTournamentRounds(teams);
      isLoading = false;
    });
  }

  List<Tournament> _generateTournamentRounds(List<Team> teams) {
    final List<Tournament> rounds = [];

    // Round 1: 14팀 → 7경기 + 1 BYE로 총 8명 생성
    List<TournamentMatch> round1 = [];
    for (int i = 0; i < teams.length; i += 2) {
      if (i + 1 < teams.length) {
        round1.add(TournamentMatch(
          id: "R1-${i ~/ 2 + 1}",
          teamA: teams[i].id,
          teamB: teams[i + 1].id,
        ));
      } else {
        round1.add(TournamentMatch(
          id: "R1-BYE",
          teamA: teams[i].id,
          teamB: "부전승",
          scoreTeamA: "1",
          scoreTeamB: "0",
        ));
      }
    }
    rounds.add(Tournament(matches: round1));

    // Round 2: 8팀 → 4경기
    rounds.add(Tournament(
      matches: List.generate(4, (i) => TournamentMatch(id: "R2-${i + 1}")),
    ));

    // Round 3: 4팀 → 2경기
    rounds.add(Tournament(
      matches: List.generate(2, (i) => TournamentMatch(id: "R3-${i + 1}")),
    ));

    // Round 4: 결승
    rounds.add(Tournament(
      matches: [TournamentMatch(id: "Final")],
    ));

    return rounds;
  }

  Widget _buildMatchCard(TournamentMatch match) {
    return Container(
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
    );
  }

  //note build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
        thumbVisibility: true,
        controller: verticalController,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: horizontalController,
          child: Container(
            height: 600,
            width: 1000,
            color: Colors.green.shade50,
            child: TournamentBracket(
              lineBorderRadius: 100,
              list: tournamentRounds,
              card: _buildMatchCard,
              cardWidth: 220,
              cardHeight: 100,
              itemsMarginVertical: 20,
              lineWidth: 80,
              lineThickness: 4,
              lineColor: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}

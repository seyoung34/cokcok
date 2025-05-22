import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tournament_bracket/flutter_tournament_bracket.dart';

import 'UnifiedTournamentPage.dart';

class UserTournamentPage extends TournamentUnifiedPage {
  const UserTournamentPage({super.key})
      : super(title: "토너먼트 보기", isAdmin: false);

  @override
  TournamentUnifiedPageState createState() => _UserTournamentPageState();
}

class _UserTournamentPageState
    extends TournamentUnifiedPageState<UserTournamentPage> {
  @override
  Widget buildMatchCard(TournamentMatch match) {
    return InkWell(
      child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            spacing: 12,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(match.teamA
                      ?.split("_")
                      .first == "빈 팀" ? "   " : match.teamA
                      ?.split("_")
                      .first ?? ""),
                  Text(match.teamA
                      ?.split("_")
                      .last == "빈 팀" ? "   " : match.teamA
                      ?.split("_")
                      .last ?? ""),
                  Text("${match.scoreTeamA}",
                    style: TextStyle(fontSize: 18, color: Colors.red),)
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
                  Text(match.teamB
                      ?.split("_")
                      .first == "빈 팀" ? "   " : match.teamB
                      ?.split("_")
                      .first ?? ""),
                  Text(match.teamB
                      ?.split("_")
                      .last == "빈 팀" ? "   " : match.teamB
                      ?.split("_")
                      .last ?? ""),
                  Text("${match.scoreTeamB}",
                    style: TextStyle(fontSize: 18, color: Colors.red),)
                ],
              )
            ],
          )
      ),
    );
  }
}
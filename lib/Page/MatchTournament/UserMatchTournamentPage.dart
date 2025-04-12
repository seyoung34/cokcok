import 'package:flutter/material.dart';
import '../../model/Match.dart';
import 'MatchTournamentBase.dart';

class UserMatchTournamentPage extends MatchTournamentBase {
  const UserMatchTournamentPage({
    super.key,
    required super.tournamentId,
    required super.gender,
  }) : super(isAdmin: false);

  @override
  State<UserMatchTournamentPage> createState() => _UserMatchTournamentPageState();
}

class _UserMatchTournamentPageState
    extends MatchTournamentBaseState<UserMatchTournamentPage> {
  @override
  Widget buildTournamentUI(List<Match> matches) {
    return Center(
      child: Text("👀 사용자용 토너먼트 UI 구현 예정 (matches: ${matches.length})"),
    );
  }
}

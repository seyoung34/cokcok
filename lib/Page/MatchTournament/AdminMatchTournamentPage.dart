import 'package:flutter/material.dart';
import '../../model/Match.dart';
import 'MatchTournamentBase.dart';

class AdminMatchTournamentPage extends MatchTournamentBase {
  const AdminMatchTournamentPage({
    super.key,
    required super.tournamentId,
    required super.gender,
  }) : super(isAdmin: true);

  @override
  State<AdminMatchTournamentPage> createState() => _AdminMatchTournamentPageState();
}

class _AdminMatchTournamentPageState
    extends MatchTournamentBaseState<AdminMatchTournamentPage> {
  @override
  Widget buildTournamentUI(List<Match> matches) {
    return Center(
      child: Text("✅ Admin용 토너먼트 UI 구현 예정 (matches: ${matches.length})"),
    );
  }
}

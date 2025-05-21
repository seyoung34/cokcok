import 'package:flutter/cupertino.dart';
import 'package:flutter_tournament_bracket/flutter_tournament_bracket.dart';

import 'UnifiedTournamentPage.dart';

class UserTournamentPage extends TournamentUnifiedPage {
  const UserTournamentPage({super.key})
      : super(title: "토너먼트 보기", isAdmin: false);

  @override
  TournamentUnifiedPageState createState() => _UserTournamentPageState();
}

class _UserTournamentPageState extends TournamentUnifiedPageState<UserTournamentPage> {
  @override
  Widget buildMatchCard(TournamentMatch match) {
    return super.buildMatchCard(match); // 클릭 불가
  }
}

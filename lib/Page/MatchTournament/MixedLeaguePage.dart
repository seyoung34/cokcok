import 'Tournament.dart';

class MixedLeaguePage extends TournamentLeaguePage {
  const MixedLeaguePage({super.key}) : super(title: "혼성 리그전", teamCollectionName: "혼성 복식 팀", isAdmin: true);

  @override
  TournamentLeaguePageState createState() => _MixedLeaguePageState();
}

class _MixedLeaguePageState extends TournamentLeaguePageState<MixedLeaguePage> {}

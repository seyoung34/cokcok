import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';
import 'MatchTableBase.dart';

class UserMatchTablePage extends MatchTableBase {
  const UserMatchTablePage({super.key, required String tournamentId})
      : super(tournamentId: tournamentId, isAdmin: false);

  @override
  _UserMatchTablePageState createState() => _UserMatchTablePageState();
}

class _UserMatchTablePageState extends MatchTableBaseState<UserMatchTablePage> {
  @override
  Widget buildMatchTable(List<Match> matches) {
    final teams = getUniqueTeams(matches);
    final teamStats = calculateStats(matches, teams);

    return _buildDataTable(teams, matches, teamStats);
  }


  Widget _buildDataTable(List<Team> teams, List<Match> matches, Map<String, Map<String, dynamic>> stats) {
    return Scrollbar(
      thumbVisibility: true,
      controller: verticalController,
      child: SingleChildScrollView(
        controller: verticalController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          thumbVisibility: true,
          controller: horizontalController,
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text("팀명")),
                ...teams.map((t) => DataColumn(label: Text(t.id))),
                const DataColumn(label: Text("순위")),
                const DataColumn(label: Text("승점")),
                const DataColumn(label: Text("득실")),
              ],
              rows: teams.map((rowTeam) {
                return DataRow(cells: [
                  DataCell(Text(rowTeam.id)),
                  ...teams.map((colTeam) {
                    if (rowTeam.id == colTeam.id) return const DataCell(SizedBox());

                    final match = matches.firstWhere(
                          (m) => (m.team1.id == rowTeam.id && m.team2.id == colTeam.id) ||
                          (m.team1.id == colTeam.id && m.team2.id == rowTeam.id),
                      orElse: () => Match(id: '', team1: rowTeam, team2: colTeam, division: rowTeam.division),
                    );

                    if (match.isCompleted) {
                      final score = rowTeam.id == match.team2.id
                          ? "${match.team2Score} - ${match.team1Score}"
                          : "${match.team1Score} - ${match.team2Score}";
                      return DataCell(Center(child: Text(score)));
                    }

                    return const DataCell(SizedBox()); // 연필 아이콘 없음
                  }),
                  DataCell(Text("${stats[rowTeam.id]!["rank"]}")),
                  DataCell(Text("${stats[rowTeam.id]!["wins"]}")),
                  DataCell(Text("${stats[rowTeam.id]!["diff"]}")),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

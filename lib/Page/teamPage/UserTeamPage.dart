import 'package:flutter/material.dart';
import 'TeamPageBase.dart';

class UserTeamPage extends TeamPageBase {
  const UserTeamPage({super.key}) : super(isAdmin: false);

  @override
  _UserTeamPageState createState() => _UserTeamPageState();
}

class _UserTeamPageState extends TeamPageBaseState<UserTeamPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("사용자 - 팀 확인")),
      body: Column(
        children: [
          buildCategorySelector(),
          const SizedBox(height: 8),
          Expanded(child: buildSelectedCategoryView()),
        ],
      ),
    );
  }
}

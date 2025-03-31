import 'package:flutter/material.dart';
import 'MatchStatusBase.dart';

class UserMatchStatusPage extends MatchStatusBase {
  const UserMatchStatusPage({super.key}) : super(isAdmin: false);

  @override
  _UserMatchStatusPageState createState() => _UserMatchStatusPageState();
}

class _UserMatchStatusPageState
    extends MatchStatusBaseState<UserMatchStatusPage> {}

import 'package:flutter/material.dart';
import 'MatchStatusBase.dart';

class AdminMatchStatusPage extends MatchStatusBase {
  const AdminMatchStatusPage({super.key}) : super(isAdmin: true);

  @override
  _AdminMatchStatusPageState createState() => _AdminMatchStatusPageState();
}

class _AdminMatchStatusPageState
    extends MatchStatusBaseState<AdminMatchStatusPage> {}

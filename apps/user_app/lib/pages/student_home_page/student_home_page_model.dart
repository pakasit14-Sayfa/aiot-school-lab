import '/components/button/button_widget.dart';
import '/components/sensor_item/sensor_item_widget.dart';
import '/components/shortcut_card/shortcut_card_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'student_home_page_widget.dart' show StudentHomePageWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class StudentHomePageModel extends FlutterFlowModel<StudentHomePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for SensorItem.
  late SensorItemModel sensorItemModel1;
  // Model for SensorItem.
  late SensorItemModel sensorItemModel2;
  // Model for SensorItem.
  late SensorItemModel sensorItemModel3;
  // Model for SensorItem.
  late SensorItemModel sensorItemModel4;
  // Model for ShortcutCard.
  late ShortcutCardModel shortcutCardModel1;
  // Model for ShortcutCard.
  late ShortcutCardModel shortcutCardModel2;
  // Model for ShortcutCard.
  late ShortcutCardModel shortcutCardModel3;
  // Model for ShortcutCard.
  late ShortcutCardModel shortcutCardModel4;
  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    sensorItemModel1 = createModel(context, () => SensorItemModel());
    sensorItemModel2 = createModel(context, () => SensorItemModel());
    sensorItemModel3 = createModel(context, () => SensorItemModel());
    sensorItemModel4 = createModel(context, () => SensorItemModel());
    shortcutCardModel1 = createModel(context, () => ShortcutCardModel());
    shortcutCardModel2 = createModel(context, () => ShortcutCardModel());
    shortcutCardModel3 = createModel(context, () => ShortcutCardModel());
    shortcutCardModel4 = createModel(context, () => ShortcutCardModel());
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    sensorItemModel1.dispose();
    sensorItemModel2.dispose();
    sensorItemModel3.dispose();
    sensorItemModel4.dispose();
    shortcutCardModel1.dispose();
    shortcutCardModel2.dispose();
    shortcutCardModel3.dispose();
    shortcutCardModel4.dispose();
    buttonModel.dispose();
  }
}

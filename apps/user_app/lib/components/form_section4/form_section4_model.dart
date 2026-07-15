import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'form_section4_widget.dart' show FormSection4Widget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FormSection4Model extends FlutterFlowModel<FormSection4Widget> {
  ///  Local state fields for this component.

  String? location = 'Science Lab A';

  ///  State fields for stateful widgets in this component.

  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}

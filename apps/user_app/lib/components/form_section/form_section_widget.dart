import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'form_section_model.dart';
export 'form_section_model.dart';

class FormSectionWidget extends StatefulWidget {
  const FormSectionWidget({
    super.key,
    this.title = 'ACTIVITY DETAILS',
    this.error,
  });

  final String title;
  final String? error;

  @override
  State<FormSectionWidget> createState() => _FormSectionWidgetState();
}

class _FormSectionWidgetState extends State<FormSectionWidget> {
  late FormSectionModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FormSectionModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          valueOrDefault<String>(widget!.title, 'ACTIVITY DETAILS'),
          style: FlutterFlowTheme.of(context).labelLarge.override(
            font: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
            ),
            color: FlutterFlowTheme.of(context).secondaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
            fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
            lineHeight: 1.4,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            wrapWithModel(
              model: _model.textFieldModel1,
              updateCallback: () => safeSetState(() {}),
              child: TextFieldWidget(
                label: 'Activity Name',
                labelPresent: true,
                helper: '',
                helperPresent: false,
                leadingIcon: Icon(
                  Icons.edit_note_rounded,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 24.0,
                ),
                leadingIconPresent: true,
                trailingIconPresent: false,
                hint: 'e.g., Physics Study Group',
                value: widget!.title,
                onChange: '',
                onSubmit: '',
                variant: 'outlined',
                error: false,
              ),
            ),
            wrapWithModel(
              model: _model.textFieldModel2,
              updateCallback: () => safeSetState(() {}),
              child: TextFieldWidget(
                label: 'Description',
                labelPresent: true,
                helper: widget!.error,
                helperPresent: true,
                leadingIcon: Icon(
                  Icons.description_rounded,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 24.0,
                ),
                leadingIconPresent: true,
                trailingIconPresent: false,
                hint: 'What are you planning to do?',
                value: '',
                onChange: '',
                onSubmit: '',
                variant: 'filled',
                error: _model.error != null && _model.error != '',
              ),
            ),
          ].divide(SizedBox(height: 16.0)),
        ),
      ].divide(SizedBox(height: 8.0)),
    );
  }
}

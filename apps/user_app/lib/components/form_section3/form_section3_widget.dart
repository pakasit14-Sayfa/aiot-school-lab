import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'form_section3_model.dart';
export 'form_section3_model.dart';

class FormSection3Widget extends StatefulWidget {
  const FormSection3Widget({
    super.key,
    String? title,
    this.time,
  }) : this.title = title ?? 'SCHEDULE';

  final String title;
  final String? time;

  @override
  State<FormSection3Widget> createState() => _FormSection3WidgetState();
}

class _FormSection3WidgetState extends State<FormSection3Widget> {
  late FormSection3Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FormSection3Model());
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
          valueOrDefault<String>(
            widget!.title,
            'SCHEDULE',
          ),
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
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: wrapWithModel(
                model: _model.textFieldModel1,
                updateCallback: () => safeSetState(() {}),
                child: TextFieldWidget(
                  label: 'Date',
                  labelPresent: true,
                  helper: '',
                  helperPresent: false,
                  leadingIcon: Icon(
                    Icons.calendar_today_rounded,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 24.0,
                  ),
                  leadingIconPresent: true,
                  trailingIconPresent: false,
                  hint: 'Type here...',
                  value: 'Oct 24, 2023',
                  onChange: '',
                  onSubmit: '',
                  variant: 'outlined',
                  error: false,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: wrapWithModel(
                model: _model.textFieldModel2,
                updateCallback: () => safeSetState(() {}),
                child: TextFieldWidget(
                  label: 'Time',
                  labelPresent: true,
                  helper: '',
                  helperPresent: false,
                  leadingIcon: Icon(
                    Icons.schedule_rounded,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 24.0,
                  ),
                  leadingIconPresent: true,
                  trailingIconPresent: false,
                  hint: 'Type here...',
                  value: widget!.time,
                  onChange: '',
                  onSubmit: '',
                  variant: 'outlined',
                  error: false,
                ),
              ),
            ),
          ].divide(SizedBox(width: 16.0)),
        ),
      ].divide(SizedBox(height: 8.0)),
    );
  }
}

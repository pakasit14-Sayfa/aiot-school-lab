import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'form_section4_model.dart';
export 'form_section4_model.dart';

class FormSection4Widget extends StatefulWidget {
  const FormSection4Widget({
    super.key,
    String? title,
  }) : this.title = title ?? 'LOCATION';

  final String title;

  @override
  State<FormSection4Widget> createState() => _FormSection4WidgetState();
}

class _FormSection4WidgetState extends State<FormSection4Widget> {
  late FormSection4Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FormSection4Model());
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
            'LOCATION',
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
        FlutterFlowDropDown<String>(
          controller: _model.dropdownValueController ??=
              FormFieldController<String>(
            _model.dropdownValue ??= _model.location,
          ),
          options: [
            'Science Lab A',
            'Main Hall 202',
            'Library Room 4',
            'Study Pod 1'
          ],
          onChanged: (val) => safeSetState(() => _model.dropdownValue = val),
          width: 200.0,
          height: 40.0,
          textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                lineHeight: 1.5,
              ),
          hintText: 'Science Lab A',
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: FlutterFlowTheme.of(context).secondaryText,
            size: 24.0,
          ),
          fillColor: FlutterFlowTheme.of(context).secondaryBackground,
          elevation: 2.0,
          borderColor: FlutterFlowTheme.of(context).alternate,
          borderWidth: 1.0,
          borderRadius: 12.0,
          margin: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
          hidesUnderline: true,
          isOverButton: false,
          isSearchable: false,
          isMultiSelect: false,
          labelText: 'Select Classroom',
          labelTextStyle: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                ),
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                lineHeight: 1.4,
              ),
        ),
      ].divide(SizedBox(height: 8.0)),
    );
  }
}

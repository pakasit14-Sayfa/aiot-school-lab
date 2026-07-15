import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'performance_stat_model.dart';
export 'performance_stat_model.dart';

class PerformanceStatWidget extends StatefulWidget {
  const PerformanceStatWidget({
    super.key,
    String? label,
    String? value,
    String? up,
    String? trend,
  })  : this.label = label ?? 'Credits',
        this.value = value ?? '124',
        this.up = up ?? 'true',
        this.trend = trend ?? '+12';

  final String label;
  final String value;
  final String up;
  final String trend;

  @override
  State<PerformanceStatWidget> createState() => _PerformanceStatWidgetState();
}

class _PerformanceStatWidgetState extends State<PerformanceStatWidget> {
  late PerformanceStatModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PerformanceStatModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valueOrDefault<String>(
                  widget!.label,
                  'Credits',
                ),
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).labelSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelSmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).labelSmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
              Text(
                valueOrDefault<String>(
                  widget!.value,
                  '124',
                ),
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      lineHeight: 1.4,
                    ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 14.0,
                    height: 14.0,
                    child: Stack(
                      alignment: AlignmentDirectional(0.0, 0.0),
                      children: [
                        if (valueOrDefault<bool>(
                          valueOrDefault<String>(
                                    widget!.up,
                                    'true',
                                  ) ==
                                  'false'
                              ? true
                              : false,
                          false,
                        ))
                          Icon(
                            Icons.trending_down_rounded,
                            color: valueOrDefault<Color>(
                              valueOrDefault<String>(
                                        widget!.up,
                                        'true',
                                      ) ==
                                      'false'
                                  ? FlutterFlowTheme.of(context).error
                                  : FlutterFlowTheme.of(context).success,
                              FlutterFlowTheme.of(context).success,
                            ),
                            size: 14.0,
                          ),
                        if (valueOrDefault<bool>(
                          valueOrDefault<String>(
                                    widget!.up,
                                    'true',
                                  ) ==
                                  'false'
                              ? false
                              : true,
                          true,
                        ))
                          Icon(
                            Icons.trending_up_rounded,
                            color: valueOrDefault<Color>(
                              valueOrDefault<String>(
                                        widget!.up,
                                        'true',
                                      ) ==
                                      'false'
                                  ? FlutterFlowTheme.of(context).error
                                  : FlutterFlowTheme.of(context).success,
                              FlutterFlowTheme.of(context).success,
                            ),
                            size: 14.0,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    valueOrDefault<String>(
                      widget!.trend,
                      '+12',
                    ),
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: valueOrDefault<Color>(
                            valueOrDefault<String>(
                                      widget!.up,
                                      'true',
                                    ) ==
                                    'false'
                                ? FlutterFlowTheme.of(context).error
                                : FlutterFlowTheme.of(context).success,
                            FlutterFlowTheme.of(context).success,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelSmall
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.4,
                        ),
                  ),
                ].divide(SizedBox(width: 4.0)),
              ),
            ].divide(SizedBox(height: 4.0)),
          ),
        ),
      ),
    );
  }
}

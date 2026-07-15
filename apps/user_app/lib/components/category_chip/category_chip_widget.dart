import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'category_chip_model.dart';
export 'category_chip_model.dart';

class CategoryChipWidget extends StatefulWidget {
  const CategoryChipWidget({
    super.key,
    bool? selected,
    String? tapAction,
    String? label,
  })  : this.selected = selected ?? false,
        this.tapAction = tapAction ?? '',
        this.label = label ?? 'All';

  final bool selected;
  final String tapAction;
  final String label;

  @override
  State<CategoryChipWidget> createState() => _CategoryChipWidgetState();
}

class _CategoryChipWidgetState extends State<CategoryChipWidget> {
  late CategoryChipModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoryChipModel());
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
        color: valueOrDefault<Color>(
          valueOrDefault<bool>(
            widget!.selected,
            false,
          )
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryBackground,
          Color(0x00000000),
        ),
        borderRadius: BorderRadius.circular(9999.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: valueOrDefault<Color>(
            valueOrDefault<bool>(
              widget!.selected,
              false,
            )
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).alternate,
            Color(0x00000000),
          ),
          width: valueOrDefault<double>(
            valueOrDefault<bool>(
              widget!.selected,
              false,
            )
                ? 1.0
                : 1.0,
            0.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(8.0, 16.0, 8.0, 16.0),
        child: Container(
          child: Text(
            valueOrDefault<String>(
              widget!.label,
              'All',
            ),
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  ),
                  color: valueOrDefault<Color>(
                    valueOrDefault<bool>(
                      widget!.selected,
                      false,
                    )
                        ? FlutterFlowTheme.of(context).onPrimary
                        : FlutterFlowTheme.of(context).secondaryText,
                    Color(0x00000000),
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  lineHeight: 1.4,
                ),
          ),
        ),
      ),
    );
  }
}

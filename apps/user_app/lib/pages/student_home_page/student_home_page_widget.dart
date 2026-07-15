import '/components/button/button_widget.dart';
import '/components/sensor_item/sensor_item_widget.dart';
import '/components/shortcut_card/shortcut_card_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import 'student_home_page_model.dart';
export 'student_home_page_model.dart';

class StudentHomePageWidget extends StatefulWidget {
  const StudentHomePageWidget({super.key});

  static String routeName = 'StudentHomePage';
  static String routePath = '/studentHomePage';

  @override
  State<StudentHomePageWidget> createState() => _StudentHomePageWidgetState();
}

class _StudentHomePageWidgetState extends State<StudentHomePageWidget> {
  late StudentHomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StudentHomePageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? 'นักเรียน';
    final schoolId = user?.schoolId ?? '';
    final building = user?.building ?? '';
    final room = user?.room ?? '';
    final hasLocation =
        schoolId.isNotEmpty && building.isNotEmpty && room.isNotEmpty;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 0.0,
                height: 0.0,
              ),
              Container(
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 280.0,
                        child: Stack(
                          alignment: AlignmentDirectional(-1.0, -1.0),
                          children: [
                            Container(
                              height: 240.0,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    FlutterFlowTheme.of(context).primary,
                                    FlutterFlowTheme.of(context).secondary
                                  ],
                                  stops: [0.0, 1.0],
                                  begin: AlignmentDirectional(0.0, -1.0),
                                  end: AlignmentDirectional(0, 1.0),
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(40.0),
                                  bottomRight: Radius.circular(40.0),
                                ),
                                shape: BoxShape.rectangle,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  24.0, 60.0, 24.0, 0.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 52.0,
                                            height: 52.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Text(
                                              'ST',
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .labelMedium
                                                  .override(
                                                    font: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    fontSize: 19.76,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelMedium
                                                            .fontStyle,
                                                    lineHeight: 1.4,
                                                  ),
                                              overflow: TextOverflow.clip,
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'สวัสดี, $name 👋',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleLarge
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .onBackground,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleLarge
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                              ),
                                              Text(
                                                hasLocation ? 'ห้อง $room • อาคาร $building' : 'ยังไม่กำหนดห้องเรียน',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .onBackground80,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                          lineHeight: 1.5,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ].divide(SizedBox(width: 16.0)),
                                      ),
                                      FlutterFlowIconButton(
                                        borderRadius: 9999.0,
                                        buttonSize: 40.0,
                                        fillColor: FlutterFlowTheme.of(context)
                                            .onPrimary10,
                                        icon: Icon(
                                          Icons.notifications_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .onPrimary,
                                          size: 24.0,
                                        ),
                                        onPressed: () {
                                          print('IconButton pressed ...');
                                        },
                                      ),
                                    ],
                                  ),
                                  !hasLocation
                                      ? Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(32.0),
                                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'ยังไม่ได้กำหนดห้องเรียนในระบบ\nกรุณาติดต่อครูหรือแอดมิน',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                            ),
                                          ),
                                        )
                                      : StreamBuilder<SensorModel?>(
                                          stream: RealtimeService.sensorStream(
                                            schoolId: schoolId,
                                            building: building,
                                            floor: '1',
                                            room: room,
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return Container(
                                                height: 180,
                                                alignment: Alignment.center,
                                                child: const CircularProgressIndicator(color: Colors.white),
                                              );
                                            }
                                            final sensor = snapshot.data ?? const SensorModel();
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(32.0),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                  sigmaX: 20.0,
                                                  sigmaY: 20.0,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(context)
                                                        .surface20,
                                                    borderRadius:
                                                        BorderRadius.circular(32.0),
                                                    shape: BoxShape.rectangle,
                                                    border: Border.all(
                                                      color: FlutterFlowTheme.of(context)
                                                          .surface30,
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(32.0),
                                                    child: Container(
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.center,
                                                        children: [
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize.max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.center,
                                                            children: [
                                                              Column(
                                                                mainAxisSize:
                                                                    MainAxisSize.min,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    'Classroom Status',
                                                                    style: FlutterFlowTheme
                                                                            .of(context)
                                                                        .labelLarge
                                                                        .override(
                                                                          font: GoogleFonts
                                                                              .plusJakartaSans(
                                                                            fontWeight:
                                                                                FontWeight
                                                                                    .w600,
                                                                            fontStyle: FlutterFlowTheme.of(
                                                                                    context)
                                                                                .labelLarge
                                                                                .fontStyle,
                                                                          ),
                                                                          color: FlutterFlowTheme.of(
                                                                                  context)
                                                                              .primaryText70,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight
                                                                                  .w600,
                                                                          fontStyle: FlutterFlowTheme.of(
                                                                                  context)
                                                                              .labelLarge
                                                                              .fontStyle,
                                                                          lineHeight: 1.4,
                                                                        ),
                                                                  ),
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize.max,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        sensor.overallLabel,
                                                                        style: FlutterFlowTheme
                                                                                .of(context)
                                                                            .headlineMedium
                                                                            .override(
                                                                              font: GoogleFonts
                                                                                  .plusJakartaSans(
                                                                                fontWeight:
                                                                                    FontWeight
                                                                                        .bold,
                                                                                fontStyle: FlutterFlowTheme.of(
                                                                                        context)
                                                                                    .headlineMedium
                                                                                    .fontStyle,
                                                                              ),
                                                                              color: sensor.overallColor,
                                                                              letterSpacing:
                                                                                  0.0,
                                                                              fontWeight:
                                                                                  FontWeight
                                                                                      .bold,
                                                                              fontStyle: FlutterFlowTheme.of(
                                                                                      context)
                                                                                  .headlineMedium
                                                                                  .fontStyle,
                                                                              lineHeight:
                                                                                  1.3,
                                                                            ),
                                                                      ),
                                                                    ].divide(SizedBox(
                                                                        width: 4.0)),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    height: 4.0)),
                                                              ),
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      sensor.overallColor,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              9999.0),
                                                                  shape:
                                                                      BoxShape.rectangle,
                                                                ),
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsetsDirectional
                                                                          .fromSTEB(
                                                                              12.0,
                                                                              6.0,
                                                                              12.0,
                                                                              6.0),
                                                                  child: Container(
                                                                    child: Text(
                                                                      'Live',
                                                                      style: FlutterFlowTheme
                                                                              .of(context)
                                                                          .labelSmall
                                                                          .override(
                                                                            font: GoogleFonts
                                                                                .plusJakartaSans(
                                                                              fontWeight:
                                                                                  FontWeight
                                                                                      .bold,
                                                                              fontStyle: FlutterFlowTheme.of(
                                                                                      context)
                                                                                  .labelSmall
                                                                                  .fontStyle,
                                                                            ),
                                                                            color: Colors.white,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            fontWeight:
                                                                                FontWeight
                                                                                    .bold,
                                                                            fontStyle: FlutterFlowTheme.of(
                                                                                    context)
                                                                                .labelSmall
                                                                                .fontStyle,
                                                                            lineHeight:
                                                                                1.4,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Divider(
                                                            height: 16.0,
                                                            thickness: 1.0,
                                                            indent: 0.0,
                                                            endIndent: 0.0,
                                                            color: FlutterFlowTheme.of(
                                                                    context)
                                                                .divider20,
                                                          ),
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize.max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.center,
                                                            children: [
                                                              wrapWithModel(
                                                                model: _model
                                                                    .sensorItemModel1,
                                                                updateCallback: () =>
                                                                    safeSetState(() {}),
                                                                child: SensorItemWidget(
                                                                  icon: Icon(
                                                                    Icons
                                                                        .thermostat_rounded,
                                                                    color: FlutterFlowTheme
                                                                            .of(context)
                                                                        .primaryText,
                                                                    size: 20.0,
                                                                  ),
                                                                  color:
                                                                      sensor.tempLevel.color,
                                                                  value: sensor.temperature.toStringAsFixed(1) + '°C',
                                                                  label: 'Temp',
                                                                ),
                                                              ),
                                                              wrapWithModel(
                                                                model: _model
                                                                    .sensorItemModel2,
                                                                updateCallback: () =>
                                                                    safeSetState(() {}),
                                                                child: SensorItemWidget(
                                                                  icon: Icon(
                                                                    Icons
                                                                        .water_drop_rounded,
                                                                    color: FlutterFlowTheme
                                                                            .of(context)
                                                                        .primaryText,
                                                                    size: 20.0,
                                                                  ),
                                                                  color:
                                                                      sensor.humidityLevel.color,
                                                                  value: sensor.humidity.toStringAsFixed(0) + '%',
                                                                  label: 'Humidity',
                                                                ),
                                                              ),
                                                              wrapWithModel(
                                                                model: _model
                                                                    .sensorItemModel3,
                                                                updateCallback: () =>
                                                                    safeSetState(() {}),
                                                                child: SensorItemWidget(
                                                                  icon: Icon(
                                                                    Icons.air_rounded,
                                                                    color: FlutterFlowTheme
                                                                            .of(context)
                                                                        .primaryText,
                                                                    size: 20.0,
                                                                  ),
                                                                  color:
                                                                      sensor.pm25Level.color,
                                                                  value: sensor.pm25.toStringAsFixed(1) + ' µg',
                                                                  label: 'PM2.5',
                                                                ),
                                                              ),
                                                              wrapWithModel(
                                                                model: _model
                                                                    .sensorItemModel4,
                                                                updateCallback: () =>
                                                                    safeSetState(() {}),
                                                                child: SensorItemWidget(
                                                                  icon: Icon(
                                                                    Icons.co2_rounded,
                                                                    color: FlutterFlowTheme
                                                                            .of(context)
                                                                        .primaryText,
                                                                    size: 20.0,
                                                                  ),
                                                                  color:
                                                                      sensor.co2Level.color,
                                                                  value: sensor.co2.toStringAsFixed(0) + ' ppm',
                                                                  label: 'CO2',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ].divide(SizedBox(height: 24.0)),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                ].divide(SizedBox(height: 24.0)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.0, 0.0, 24.0, 40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Quick Access',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                                Text(
                                  'View All',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: wrapWithModel(
                                        model: _model.shortcutCardModel1,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: ShortcutCardWidget(
                                          bgColor: FlutterFlowTheme.of(context)
                                              .primaryContainer,
                                          tapAction: 'navigate(my_courses)',
                                          icon: Icon(
                                            Icons.school_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            size: 24.0,
                                          ),
                                          iconColor:
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                          title: 'My Courses',
                                          subtitle: '8 Active',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: wrapWithModel(
                                        model: _model.shortcutCardModel2,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: ShortcutCardWidget(
                                          bgColor: FlutterFlowTheme.of(context)
                                              .accentContainer,
                                          tapAction:
                                              'navigate(grades_overview)',
                                          icon: Icon(
                                            Icons.assessment_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .onAccentContainer,
                                            size: 24.0,
                                          ),
                                          iconColor:
                                              FlutterFlowTheme.of(context)
                                                  .onAccentContainer,
                                          title: 'Grades',
                                          subtitle: 'Top 5%',
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 16.0)),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: wrapWithModel(
                                        model: _model.shortcutCardModel3,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: ShortcutCardWidget(
                                          bgColor: Color(0x00000000),
                                          tapAction:
                                              'navigate(class_activities)',
                                          icon: Icon(
                                            Icons.event_available_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .info,
                                            size: 24.0,
                                          ),
                                          iconColor:
                                              FlutterFlowTheme.of(context).info,
                                          title: 'Activities',
                                          subtitle: '3 Today',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: wrapWithModel(
                                        model: _model.shortcutCardModel4,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: ShortcutCardWidget(
                                          bgColor: FlutterFlowTheme.of(context)
                                              .secondaryContainer,
                                          tapAction:
                                              'navigate(student_profile)',
                                          icon: Icon(
                                            Icons.person_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .onSecondaryContainer,
                                            size: 24.0,
                                          ),
                                          iconColor:
                                              FlutterFlowTheme.of(context)
                                                  .onSecondaryContainer,
                                          title: 'Profile',
                                          subtitle: 'Settings',
                                        ),
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 16.0)),
                                ),
                              ].divide(SizedBox(height: 16.0)),
                            ),
                          ].divide(SizedBox(height: 24.0)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.0, 0.0, 24.0, 40.0),
                        child: Container(
                          child: Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(24.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 44.0,
                                      height: 44.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .warning10,
                                        borderRadius:
                                            BorderRadius.circular(9999.0),
                                        shape: BoxShape.rectangle,
                                      ),
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Icon(
                                        Icons.campaign_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .onSurface,
                                        size: 24.0,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Next Lecture',
                                            style: FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                          Text(
                                            'Advanced Thermodynamics',
                                            maxLines: 1,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                  lineHeight: 1.5,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ].divide(SizedBox(height: 4.0)),
                                      ),
                                    ),
                                    wrapWithModel(
                                      model: _model.buttonModel,
                                      updateCallback: () => safeSetState(() {}),
                                      child: ButtonWidget(
                                        iconPresent: false,
                                        iconEndPresent: false,
                                        content: 'Join',
                                        variant: 'primary',
                                        size: 'small',
                                        fullWidth: false,
                                        loading: false,
                                        disabled: false,
                                      ),
                                    ),
                                  ].divide(SizedBox(width: 16.0)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

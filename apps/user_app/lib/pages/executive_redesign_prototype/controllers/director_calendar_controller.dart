import 'package:shared_core/shared_core.dart';

class DirectorCalendarData {
  const DirectorCalendarData(this.events, this.schedules, this.meetings);
  final List<CalendarEventItem> events;
  final List<SchoolScheduleItem> schedules;
  final List<MeetingRecord> meetings;
}

/// Combines school dates with meetings visible to the current session.
/// Failure of any source must not masquerade as an empty calendar.
class DirectorCalendarController {
  DirectorCalendarController({
    this.loadEvents,
    this.loadSchedules,
    this.loadMeetings,
  });
  final Future<List<CalendarEventItem>> Function()? loadEvents;
  final Future<List<SchoolScheduleItem>> Function()? loadSchedules;
  final Future<List<MeetingRecord>> Function()? loadMeetings;

  Future<DirectorCalendarData> load() async {
    final result = await Future.wait<Object>([
      (loadEvents ?? CalendarService.listSchoolCalendarEvents)(),
      (loadSchedules ?? ExecutiveService.listAllSchoolSchedules)(),
      (loadMeetings ?? MeetingService().list)(),
    ]);
    return DirectorCalendarData(
      result[0] as List<CalendarEventItem>,
      result[1] as List<SchoolScheduleItem>,
      result[2] as List<MeetingRecord>,
    );
  }
}

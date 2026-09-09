import 'package:estudazz_main_code/components/cards/events/eventsCard.dart';
import 'package:estudazz_main_code/components/custom/customAppBar.dart';
import 'package:estudazz_main_code/components/dialog/calendar/addEventDialog.dart';
import 'package:estudazz_main_code/components/dialog/calendar/detailEventDialog.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/models/calendar/eventModel.dart';
import 'package:estudazz_main_code/services/db/calendar/eventsDB.dart';
import 'package:estudazz_main_code/utils/user/getUserData.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final EventsDB _eventsDB = EventsDB();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Future<String?> _userUidFuture;

  @override
  void initState() {
    super.initState();
    _userUidFuture = GetUserData.getUserUid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleAppBar: 'Calendário'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ConstColors.grey900Color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ConstColors.orangeColor.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: ConstColors.orangeColor),
                  ConstSizedBox.w8,
                  Expanded(
                    child: Text(
                      "Dica: Pressione e segure sobre um dia no calendário abaixo para criar um novo evento.",
                      style: TextStyle(color: ConstColors.whiteColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDayLongPressed: (selectedDay, focusedDay) async {
                final todayDate = DateTime.now();
                final isFuture = selectedDay.isAfter(
                  DateTime(todayDate.year, todayDate.month, todayDate.day),
                );

                if (isFuture) {
                  final uid = await GetUserData.getUserUid();

                  AddEventDialog().showAddEventDialog(
                    context: context,
                    eventId: uid!,
                    eventName: "",
                    eventDate: selectedDay,
                    getUserUid: GetUserData.getUserUid, 
                  );
                }
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: ConstColors.orangeColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: ConstColors.redColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: ConstColors.whiteColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              locale: 'pt_BR',
            ),
            ConstSizedBox.h16,
            Expanded(
              child: FutureBuilder<String?>(
                future: _userUidFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final uid = snapshot.data!;
                  return StreamBuilder<QuerySnapshot>(
                    stream: _eventsDB.getEventsByUser(uid),
                    builder: (context, eventSnapshot) {
                      if (eventSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (eventSnapshot.hasError) {
                        print('Erro: ${eventSnapshot.error}');
                        return const Center(
                          child: Text(
                            'Erro ao carregar eventos. \nContate o suporte.',
                          ),
                        );
                      }
                      if (!eventSnapshot.hasData ||
                          eventSnapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum evento cadastrado.',
                            style: TextStyle(color: ConstColors.white54Color),
                          ),
                        );
                      }

                      final events = eventSnapshot.data!.docs.map((doc) {
                        return EventModel.fromDocument(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                      }).toList();

                      return ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];

                          return EventsCard(
                            eventName: event.eventName,
                            eventDate: event.eventDate,
                            onTap: () {
                              DetailEventDialog().showDetailEventDialog(
                                eventId: event.id,
                                context: context,
                                eventName: event.eventName,
                                eventDate: event.eventDate,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

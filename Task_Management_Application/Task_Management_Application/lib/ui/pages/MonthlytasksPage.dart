import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_management/db/db_helper.dart';
import 'package:task_management/models/task.dart';

import 'WeeklyTasksPage.dart';

class MonthlytasksPage extends StatefulWidget {
  const MonthlytasksPage({Key? key}) : super(key: key);

  @override
  State<MonthlytasksPage> createState() => _MonthlytasksPage();
}

class _MonthlytasksPage extends State<MonthlytasksPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  List<Task> _tasks = [];
  Map<String, List<Task>> mySelectedEvents = {};
  List<Color?> colors = [
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.lime[600]
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _focusedDay;

    loadTasksFromCurrentMonth();
  }

  Future<void> loadTasksFromCurrentMonth() async {
    int? loggedInUserId = DBHelper.loggedInUserId;
    final tasks = await DBHelper.getTasksFromCurrentMonth(loggedInUserId!);

    setState(() {
      _tasks = tasks;
      mySelectedEvents = _groupTasksByDate(tasks);
    });
  }

  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks) {
    Map<String, List<Task>> events = {};

    for (var task in tasks) {
      String date = task.date!;

      if (events.containsKey(date)) {
        events[date]!.add(task);
      } else {
        events[date] = [task];
      }
    }

    return events;
  }
  List<Task> _listOfDayEvents(DateTime dateTime) {
    String date = DateFormat.yMd().format(dateTime);
    List<Task> events = [];

    if (mySelectedEvents[date] != null) {
      events.addAll(mySelectedEvents[date]!);
    }
    bool _isTaskAddedOnDate(Task task, DateTime dateTime) {
      String taskDate = DateFormat.yMd().format(dateTime);
      return events.any((event) => event.date == taskDate && event.id == task.id);
    }

    DateTime endDate = dateTime.add(const Duration(days: 365));
    _tasks.forEach((task) {
      if (task.date != null) {
        DateTime taskDateTime = DateFormat.yMd().parse(task.date!);
        if (taskDateTime.isBefore(dateTime) || _isSameDay(taskDateTime, dateTime)) {

          if (task.repeat == 'Daily') {
            DateTime nextDate = taskDateTime.add(const Duration(days: 1));
            while (nextDate.isBefore(endDate)) {
              if (_isSameDay(nextDate, dateTime)) {
                Task repeatedTask = _createRepeatedTask(task, nextDate);
                events.add(repeatedTask);
              }
              nextDate = nextDate.add(const Duration(days: 1));

              if (_isSameDay(nextDate, taskDateTime)) {

                nextDate = nextDate.add(const Duration(days: 1));
              }
            }
          } else if (task.repeat == 'Weekly') {
            DateTime nextDate = _getNextRepeatedWeekDate(taskDateTime, dateTime);
            while (nextDate.isBefore(endDate)) {
              if (_isSameDay(nextDate, dateTime)) {
                Task repeatedTask = _createRepeatedTask(task, nextDate);
                events.add(repeatedTask);
              }
              nextDate = nextDate.add(const Duration(days: 7));
            }
          } else if (task.repeat == 'Monthly') {
            DateTime? nextDate = _getNextRepeatedMonthDate(taskDateTime, dateTime);
            while (nextDate!.isBefore(endDate)) {
              if (_isSameDay(nextDate, dateTime)) {
                Task repeatedTask = _createRepeatedTask(task, nextDate);
                events.add(repeatedTask);
              }
              nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
            }
          } else if (_isSameDay(taskDateTime, dateTime) && !_isTaskAddedOnDate(task, dateTime)) {
            events.add(task);
          }
        }
      }
    });



    return events;
  }


  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  DateTime _getNextRepeatedWeekDate(DateTime currentDate, DateTime dateTime) {
    DateTime nextDate = currentDate.add(const Duration(days: 7));

    if (nextDate.isBefore(currentDate) || _isSameDay(nextDate, currentDate)) {
      int daysToAdd = nextDate.difference(currentDate).inDays;
      nextDate = currentDate.add(Duration(days: daysToAdd));
    }

    return nextDate;
  }

  DateTime? _getNextRepeatedMonthDate(DateTime currentDate, DateTime dateTime) {
    int nextMonth = currentDate.month + 1;
    int nextYear = currentDate.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    DateTime nextDate = DateTime(nextYear, nextMonth, currentDate.day);
    return nextDate.isBefore(currentDate) ? currentDate : nextDate;
  }

  Task _createRepeatedTask(Task task, DateTime date) {
    return Task(
      title: task.title,
      note: task.note,
      date: DateFormat.yMd().format(date),
      repeat: task.repeat,
      startTime: task.startTime,
      endTime: task.endTime,
      id: task.id,
      color: task.color,
      userId: task.userId,
      isCompleted: task.isCompleted,
      remind: task.remind,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Monthly Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WeeklyTasksPage(title: 'Weekly Tasks')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(DateTime.now().year - 1),
            lastDay: DateTime(DateTime.now().year + 1),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDate, selectedDay)) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDate, day);
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _listOfDayEvents,
          ),
          SizedBox(
            width: 25,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ListView.builder(
                itemCount: _listOfDayEvents(_selectedDate!).length,
                itemBuilder: (context, index) {
                  Task task = _listOfDayEvents(_selectedDate!)[index];
                  Color? taskColor = colors[index % colors.length];
                  return Container(
                    decoration: BoxDecoration(
                      color: taskColor,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.done,
                        color: Colors.teal,
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text('Task Title: ${task.title}',  style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),),
                      ),
                      subtitle: Text('Note: ${task.note} ,  ${task.startTime} - ${task.endTime} ',style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                      ),),
                    ),
                  );
                },
              ),
            ),
          ),

        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:task_management/controllers/task_controller.dart';
import 'package:intl/intl.dart';
import 'package:time_planner/time_planner.dart';
import '../../models/task.dart';
import '../size_config.dart';
import '../theme.dart';


class WeeklyTasksPage extends StatefulWidget {
  const WeeklyTasksPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _WeeklyTasksPageState createState() => _WeeklyTasksPageState();
}

class _WeeklyTasksPageState extends State<WeeklyTasksPage> {
  final _taskController = Get.put(TaskController());
  List<TimePlannerTask> tasks = [];
  List<Color?> colors = [
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.lime[600]
  ];

  void initState() {
    initializeTasks();
    super.initState();
  }
  Future<void> initializeTasks() async {
    await loadWeeklyTasks(context);
  }

  Future<List<TimePlannerTask>>  loadWeeklyTasks(BuildContext context) async {

    List<Task> weeklyTasks = await _taskController.getWeeklyTasks();
    DateTime currentDate = DateTime.now();
    DateTime startDate = currentDate.subtract(Duration(days: currentDate.weekday - 1));
    DateTime endDate = startDate.add(Duration(days: 6));

    for (Task task in weeklyTasks) {
      DateTime taskDate = DateFormat.yMd().parse(task.date!);

      bool isSameDay = startDate.year == taskDate.year &&
          startDate.month == taskDate.month &&
          startDate.day == taskDate.day;
      bool isSameDay1 = endDate.year == taskDate.year &&
          endDate.month == taskDate.month &&
          endDate.day == taskDate.day;
      if ((taskDate.isAfter(startDate) && taskDate.isBefore(endDate)) || isSameDay || isSameDay1 == true )  {
        String startTime = task.startTime!;
        bool containsPm = startTime.toLowerCase().contains("pm");
        bool containsAm = startTime.toLowerCase().contains("am");
        bool contains12 = startTime.toLowerCase().contains("12");
        String title = task.title!;
        startTime = startTime.replaceAll(' AM', '').replaceAll(' PM', '');
        List<String> startTimeParts = startTime.split(':');
        if (startTimeParts.length == 2) {
          int hour = int.tryParse(startTimeParts[0])!;
          if (containsPm ){
            if (contains12){
              hour = hour;
            }else {
            hour= (hour + 12);

          }
          }
           if(containsAm) {
            if (contains12){
            hour= 0;
          }
           else hour = hour;}
           int? minutes = int.tryParse(startTimeParts[1])!;
          setState(() {
            tasks.add(TimePlannerTask(
            key: ValueKey(task.id),
            dateTime: TimePlannerDateTime(
              day:  taskDate.day - startDate.day ,
              hour: hour,
              minutes: minutes,
            ),
            daysDuration: calculatdayduration(task),
              minutesDuration: calculateTaskDuration(task),
            color: colors[Random().nextInt(colors.length)],

              onTap: () {
                showBottomSheet(context,task);
                },
               child:Center(child:
               Align(
                 alignment: Alignment.center,

                 child :Text(
                 '${title ?? ''} (${task.note ?? ''})',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
               ))));
          });
        }
      }

    }
    return tasks;
  }

  int calculatdayduration(Task task) {
    String? taskrepeat = task.repeat;
    DateTime taskDate = DateFormat.yMd().parse(task.date!);
    DateTime currentDate = DateTime.now();
    DateTime startDate = currentDate.subtract(Duration(days: currentDate.weekday - 1));
    DateTime endDate = startDate.add(Duration(days: 6));
    int taskduration = 1;
    if (taskrepeat == "Daily"){
      taskduration = endDate.day - taskDate.day +1 ;
    }
    return taskduration; 
  }


  int calculateTaskDuration(Task task) {
    String startTimeString = task.startTime!;
    String taskDateString = task.date!;
    DateTime taskDate = DateFormat('M/d/yyyy').parse(taskDateString);
    String dateTimeString1 = '${DateFormat('yyyy-MM-dd').format(taskDate)} $startTimeString';
    DateTime? startTime =DateFormat('yyyy-MM-dd h:mm a').parse(dateTimeString1);
    String endTimeString = task.endTime!;
    String dateTimeString = '${DateFormat('yyyy-MM-dd').format(taskDate)} $endTimeString';
    DateTime endTime = DateFormat('yyyy-MM-dd h:mm a').parse(dateTimeString);
    int durationInMinutes = endTime.difference(startTime).inMinutes;
    return durationInMinutes;
  }
  showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(top: 4),
        height: task.isCompleted == 1
            ? SizeConfig.screenHeight * 0.20
            : SizeConfig.screenHeight * 0.35,
        width: SizeConfig.screenWidth,
        color: Get.isDarkMode ? darkHeaderClr : Colors.white,
        child: Column(children: [
          Container(
            height: 6,
            width: 120,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300]),
          ),
          _buildBottomSheetButton(
              label: "Delete Task",
              onTap: ()  {
                 _taskController.deleteTask(task);
                 setState(() {
                   tasks.removeWhere((element) => element.key == ValueKey(task.id));
                 });
                 Get.back();
              },
              clr: Colors.red[300]),
          SizedBox(
            height: 20,
          ),
          _buildBottomSheetButton(
              label: "Close",
              onTap: () {
                Get.back();
              },
              isClose: true),

        ]),
      ),
    );
  }
  _buildBottomSheetButton(
      {required String label, Function? onTap, Color? clr, bool isClose = false}) {
    return GestureDetector(
      onTap: onTap as void Function()?,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        height: 55,
        width: SizeConfig.screenWidth! * 0.9,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isClose
                ? Get.isDarkMode
                ? Colors.grey[600]!
                : Colors.grey[300]!
                : clr!,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isClose ? Colors.transparent : clr,
        ),
        child: Center(
            child: Text(
              label,
              style: isClose
                  ? titleTextStle
                  : titleTextStle.copyWith(color: Colors.white),
            )),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: tasks.isNotEmpty
            ? TimePlanner(
          key: UniqueKey(),
          startHour: 0,
          endHour: 23,
          style: TimePlannerStyle(
             cellHeight: 90,
             cellWidth: 90,
            showScrollBar: true,
            dividerColor: Colors.lightBlue,
              borderRadius:BorderRadius.all(Radius.circular(10)),

          ),
          headers: generateTimePlannerTitles(),
          tasks: tasks,
        )
            : Text('No Tasks available'),
      ),

    );
  }

  List<TimePlannerTitle> generateTimePlannerTitles() {
    List<TimePlannerTitle> titles = [];
    DateTime currentDate = DateTime.now();
    DateTime startDate = currentDate.subtract(
        Duration(days: currentDate.weekday - 1));

    for (int i = 0; i < 7; i++) {
      DateTime date = startDate.add(Duration(days: i));
      String formattedDate = DateFormat.Md().format(date);
      String weekday = DateFormat.E().format(date);
      titles.add(TimePlannerTitle(
        date: formattedDate,
        title: weekday,
      ));
    }

    return titles;
  }

}










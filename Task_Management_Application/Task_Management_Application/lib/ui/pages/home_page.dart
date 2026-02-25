import 'dart:async';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_management/controllers/task_controller.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/services/notification_services.dart';
import 'package:task_management/ui/pages/MonthlytasksPage.dart';
import 'package:task_management/ui/pages/add_task_page.dart';
import 'package:task_management/ui/size_config.dart';
import 'package:task_management/ui/theme.dart';
import 'package:task_management/ui/widgets/button.dart';
import 'package:intl/intl.dart';
import 'package:task_management/ui/widgets/task_tile.dart';
import '../../db/db_helper.dart';
import '../../services/theme_services.dart';
import 'EditTaskPage.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.parse(DateTime.now().toString());
  final _taskController = Get.put(TaskController());
  late var notifyHelper;
  bool animate=false;
  double left=630;
  double top=900;
  Timer? _timer;
  int? userId = DBHelper.loggedInUserId;
  @override
  void initState() {
    super.initState();
    notifyHelper = NotifyHelper();
    notifyHelper.initializeNotification();
    notifyHelper.requestIOSPermissions();
    _timer = Timer(Duration(milliseconds: 500), () {
      setState(() {
        animate=true;
        left=30;
        top=top/3;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: _appBar(),
      backgroundColor: context.theme.backgroundColor,
      body: Column(
        children: [
          _addTaskBar(),
          _dateBar(),
          SizedBox(
            height: 12,
          ),
          _showTasks(),
        ],
      ),
    );
  }

  _dateBar() {
    return Container(
      margin: EdgeInsets.only(bottom: 10, left: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: DatePicker(
          DateTime.now(),
          height: 100.0,
          width: 50,
          initialSelectedDate: DateTime.now(),
          selectionColor: primaryClr,
          selectedTextColor: Colors.white,
          dateTextStyle: GoogleFonts.lato(
            textStyle: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          dayTextStyle: GoogleFonts.lato(
            textStyle: TextStyle(
              fontSize: 13.0,
              color: Colors.grey,
            ),
          ),
          monthTextStyle: GoogleFonts.lato(
            textStyle: TextStyle(
              fontSize: 10.0,
              color: Colors.grey,
            ),
          ),
          onDateChange: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
      ),
    );
  }

  _addTaskBar() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMMd().format(DateTime.now()),
                style: subHeadingTextStyle,
              ),
              SizedBox(height: 10,),
              Text(
                "Today",
                style: headingTextStyle,
              ),
            ],
          ),
          MyButton(
            label: "+ Add Task",
            onTap: () async {
              await Get.to(AddTaskPage());
              _taskController.getTasks();
            },
          ),
        ],
      ),
    );
  }

  _appBar() {
    return AppBar(
        elevation: 0,
        backgroundColor: context.theme.backgroundColor,
        leading: GestureDetector(
          onTap: () {
            ThemeService().switchTheme();

          },
          child: Icon(
              Get.isDarkMode ? Icons.wb_sunny : Icons.shield_moon,
              color: Get.isDarkMode ? Colors.white : darkGreyClr),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today
            ),
            iconSize: 25.0 ,
            color: Colors.blue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MonthlytasksPage ()),
              );
            },
          ),
          SizedBox(
            width: 20,
          ),
          FutureBuilder<io.File?>(
            future: getProfilePhoto(userId!),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {

                return GestureDetector(
                  onTap: () {
                    _uploadPhoto(context, userId!);

                  },
                  child: CircleAvatar(
                    backgroundImage: FileImage(snapshot.data!),
                      radius: 30
                  ),
                );
              }  else {
                // Kein Foto in der Datenbank gefunden
                return IconButton(
                  onPressed: () {
                    _uploadPhoto(context, userId!);
                  },
                  color: Colors.blue,
                  padding: EdgeInsets.all(0),
                  constraints: BoxConstraints(),
                  iconSize: 36,
                  icon: _uploadedPhoto != null
                      ? CircleAvatar(
                    backgroundImage: FileImage(_uploadedPhoto!),
                  )
                      : Icon(Icons.account_box_outlined),
                );
              }
            },
          ),



        ],);
  }

  _showTasks() {
    return Expanded(
      child: Obx(() {
        if (_taskController.taskList.isEmpty) {
          return _noTaskMsg();
        } else {
          return ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _taskController.taskList.length,
            itemBuilder: (context, index) {
              Task task = _taskController.taskList[index];

              if (task.repeat == 'Daily') {
                DateTime date = DateFormat("M/d/yyyy hh:mm a").parse(task.date!+" "+task.startTime!);
                int? remaindMinutes = task.remind;
                Duration remaindDuration = Duration(minutes: remaindMinutes!);
                DateTime newStartTime = date.subtract(remaindDuration);
                var myTime1 = DateFormat("HH:mm").format(newStartTime);
                notifyHelper.scheduledNotification(
                  int.parse(myTime1.toString().split(":")[0]),
                  int.parse(myTime1.toString().split(":")[1]),
                  task,
                );
                return _buildTaskRow(task, index);
              }

              if ( task.repeat == 'None' && task.date == DateFormat.yMd().format(_selectedDate)) {
                  DateTime date = DateFormat("M/d/yyyy hh:mm a").parse(task.date!+" "+task.startTime!);
                  int? remaindMinutes = task.remind;
                  Duration remaindDuration = Duration(minutes: remaindMinutes!);
                  DateTime newStartTime = date.subtract(remaindDuration);
                  var myTime1 = DateFormat("HH:mm").format(newStartTime);
                  notifyHelper.scheduledNotification(
                    int.parse(myTime1.toString().split(":")[0]),
                    int.parse(myTime1.toString().split(":")[1]),
                    task,
                  );
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 1375),
                    child: SlideAnimation(
                      horizontalOffset: 300.0,
                      child: FadeInAnimation(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                                onTap: () {

                                  showBottomSheet(context, task);
                                },
                                child: TaskTile(task)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

              if (task.repeat == 'Weekly') {
                DateTime taskDate = DateFormat.yMd().parse(task.date!);
                DateTime selectedDate =
                DateFormat.yMd().parse(DateFormat.yMd().format(_selectedDate));
                int taskWeekday = taskDate.weekday;
                int selectedWeekday = selectedDate.weekday;
                int weeksDifference =
                    selectedDate.difference(taskDate).inDays ~/ 7;
                DateTime newTaskDate = taskDate.add(Duration(days: weeksDifference * 7));
                DateTime date = DateFormat("M/d/yyyy hh:mm a").parse(task.date!+" "+task.startTime!);
                int? remaindMinutes = task.remind;
                Duration remaindDuration = Duration(minutes: remaindMinutes!);
                DateTime newStartTime = date.subtract(remaindDuration);
                var myTime1 = DateFormat("HH:mm").format(newStartTime);
                notifyHelper.scheduledNotification(
                  int.parse(myTime1.toString().split(":")[0]),
                  int.parse(myTime1.toString().split(":")[1]),
                  task,
                );

                if (taskWeekday == selectedWeekday &&
                    (newTaskDate.isBefore(selectedDate) || newTaskDate == selectedDate)) {
                  return _buildTaskRow(task, index);
                }
              }

              if (task.repeat == 'Monthly') {
                DateTime taskDate = DateFormat.yMd().parse(task.date!);
                DateTime selectedDate =
                DateFormat.yMd().parse(DateFormat.yMd().format(_selectedDate));
                int taskDay = taskDate.day;
                DateTime date = DateFormat("M/d/yyyy hh:mm a").parse(task.date!+" "+task.startTime!);
                int? remaindMinutes = task.remind;
                Duration remaindDuration = Duration(minutes: remaindMinutes!);
                DateTime newStartTime = date.subtract(remaindDuration);
                var myTime1 = DateFormat("HH:mm").format(newStartTime);
                notifyHelper.scheduledNotification(
                  int.parse(myTime1.toString().split(":")[0]),
                  int.parse(myTime1.toString().split(":")[1]),
                  task,
                );

                DateTime currentMonthDate = DateTime(selectedDate.year, selectedDate.month, taskDay);
                DateTime newTaskDate;

                do {
                  int selectedMonth = currentMonthDate.month;
                  newTaskDate = DateTime(currentMonthDate.year, currentMonthDate.month, taskDay);

                  if (newTaskDate.isAtSameMomentAs(selectedDate)) {
                    return _buildTaskRow(task, index);
                  }

                  currentMonthDate = currentMonthDate.add(Duration(days: 30));
                } while (currentMonthDate.isBefore(DateTime(selectedDate.year + 1, selectedDate.month, taskDay)));
              }

              return Container();
            },
          );
        }
      }),
    );
  }

  Widget _buildTaskRow(Task task, int index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 1375),
      child: SlideAnimation(
        horizontalOffset: 300.0,
        child: FadeInAnimation(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  showBottomSheet(context, task);
                },
                child: TaskTile(task),
              ),
            ],
          ),
        ),
      ),
    );
  }


  showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: SizeConfig.screenHeight * 0.35,),
        padding: EdgeInsets.only(top: 4),
        color: Get.isDarkMode ? darkHeaderClr : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 6,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
            Spacer(),
            if (task.isCompleted == 0)
              _buildBottomSheetButton(
                label: "Task Completed",
                onTap: () {
                  _taskController.markTaskCompleted(task.id);
                  Get.back();
                },
                clr: primaryClr,
              ),
            _buildBottomSheetButton(
              label: "Delete Task",
              onTap: () {
                _taskController.deleteTask(task);
                Get.back();
              },
              clr: Colors.red[300],
            ),

            _buildBottomSheetButton(
              label: "Edit Task",
              onTap: () {
                Get.back();
                _editTask(task);
              },
              clr: Colors.orange[300],
            ),

            _buildBottomSheetButton(
              label: "Close",
              onTap: () {
                Get.back();
              },
              isClose: true,
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }


  void _editTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskPage(task: task),
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

  _noTaskMsg() {
    return Stack(
      children:[ AnimatedPositioned(
        duration: Duration(milliseconds: 2000),
        left: 75,
        top:top,
        child: Container(
         child : Center (
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "images/task.svg",
                color: primaryClr.withOpacity(0.5),
                height: 90,
                semanticsLabel: 'Task',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Center( child :Text(
                  "You do not have any tasks yet!",
                  textAlign: TextAlign.center,
                  style: subTitleTextStle,
                ),
              ),),
              SizedBox(
                height: 80,
              ),
            ],
          )
        ),
      ))],
    );
  }
  io.File? _uploadedPhoto;
  Future<void> _uploadPhoto(BuildContext context, int userId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      io.File uploadedFile = io.File(pickedFile.path);
      setState(() {
        _uploadedPhoto = uploadedFile;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Upload Successful'),
          content: Text('Photo uploaded successfully.'),
          actions: [
            TextButton(
              onPressed: () async {
                await saveImage(uploadedFile, userId);
                setState(() {
                  _uploadedPhoto = uploadedFile;
                });
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> saveImage(io.File imageFile, int userId) async {
    final databaseHelper = DBHelper();
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/saved_image.jpg';

    try {
      await imageFile.copy(imagePath);
      print('Bild erfolgreich gespeichert: $imagePath');

      await databaseHelper.insertPhoto(userId, imagePath);
      print('Foto erfolgreich in der Datenbank gespeichert.');
    } catch (e) {
      print('Fehler beim Speichern des Bildes: $e');
    }
  }
  Future<io.File?> getProfilePhoto(int userId) async {
    try {
      final databaseHelper = DBHelper();
      final photoPath = await databaseHelper.getPhotoPath(userId);
      if (_uploadedPhoto != null) {
        return _uploadedPhoto;
      }
      if (photoPath != null) {
        return io.File(photoPath);
      }
    } catch (e) {
      print('Fehler beim Abrufen des Profilfotos: $e');
    }

    return null;
  }

}




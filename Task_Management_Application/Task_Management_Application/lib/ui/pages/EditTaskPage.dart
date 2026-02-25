import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:task_management/models/task.dart';

import '../../controllers/task_controller.dart';
import '../../db/db_helper.dart';
import '../theme.dart';
import '../widgets/button.dart';

class EditTaskPage extends StatefulWidget {
  final Task task;


  EditTaskPage({required this.task});

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final TaskController _taskController = Get.find<TaskController>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int validTime = 1;

  DateTime _selectedDate = DateTime.now();
  String? _startTime = DateFormat('hh:mm a').format(DateTime.now()).toString();
  String? _endTime = "11:59 PM";
  int _selectedColor = 0;
  int _selectedRemind = 15;
  List<int> remindList = [15,
    30,
    60,
    120];
  String? _selectedRepeat = 'None';
  List<String> repeatList = ['None', 'Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title ?? '';
    _noteController.text = widget.task.note ?? '';
    _selectedDate = widget.task.date != null
        ? DateFormat.yMd().parse(widget.task.date!)
        : DateTime.now();
    _startTime = widget.task.startTime ?? DateFormat('hh:mm a').format(DateTime.now()).toString();
    _endTime = widget.task.endTime ?? "11:59 PM";
    _selectedColor = widget.task.color ?? 0;
    _selectedRemind = widget.task.remind ?? 5;
    _selectedRepeat = widget.task.repeat ?? 'None';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter title',
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Note',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Enter note',
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _selectDate,
                child: Text(
                  DateFormat.yMMMd().format(_selectedDate),
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Start Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _selectStartTime,
                child: Text(
                  _startTime!,
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'End Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _selectEndTime,
                child: Text(
                  _endTime!,
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                'Remind',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<int>(
                value: _selectedRemind,
                onChanged: (int? value) {
                  setState(() {
                    _selectedRemind = value!;
                  });
                },
                items: remindList.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value minutes early'),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              Text(
                'Repeat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _selectedRepeat,
                onChanged: (String? value) {
                  setState(() {
                    _selectedRepeat = value!;
                  });
                },
                items: repeatList.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _colorChips(),
                  MyButton(
                    label: "Save Changes",
                    onTap: () {
                      _saveChanges();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );

    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime.format(context);
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );

    if (pickedTime != null) {

      setState(() {
        _endTime = pickedTime.format(context);
      });
    }
    _compareTime();
  }
  _compareTime() {
    print("compare time");
    print(_startTime);
    print(_endTime);
    bool? containsPm = _startTime?.toLowerCase().contains("pm");
    bool? containsAm1 = _endTime?.toLowerCase().contains("am");
    bool? contains12am = _endTime?.toLowerCase().contains("12");
    validTime = 0;

    var startParts = _startTime!.split(' ');
    var endParts = _endTime!.split(' ');

    var _start = TimeOfDay(
      hour: int.parse(startParts[0].split(':')[0]),
      minute: int.parse(startParts[0].split(':')[1]),
    );

    var _end = TimeOfDay(
      hour: int.parse(endParts[0].split(':')[0]),
      minute: int.parse(endParts[0].split(':')[1]),
    );

    var startDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, _start.hour, _start.minute);
    var endDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, _end.hour, _end.minute);


    if ((containsPm! && containsAm1!)|| (contains12am! && containsAm1!)) {
      // Startzeit ist PM und Endzeit ist AM (ungültige Kombination)
      Get.snackbar(
        "Invalid!",
        "End time cannot be on a different day when the start time is PM.",
        snackPosition: SnackPosition.BOTTOM,
        overlayColor: context.theme.backgroundColor,
      ); }else if (_start.period == _end.period && startDateTime.isAfter(endDateTime)) {
      // Startzeit und Endzeit sind am selben Tag, aber Startzeit ist nach der Endzeit
      Get.snackbar(
        "Invalid!",
        "Time duration must be positive.",
        snackPosition: SnackPosition.BOTTOM,
        overlayColor: context.theme.backgroundColor,
      );
    }else {
      // Valid time interval, add task to DB and navigate back
      setState(() {
        validTime = 1;
      });
      print ( " valid Date");
    }
  }

  void _saveChanges() async {
    Task updatedTask = Task(
      id: widget.task.id,
      title: _titleController.text,
      note: _noteController.text,
      date: DateFormat.yMd().format(_selectedDate),
      startTime: _startTime,
      endTime: _endTime,
      color: _selectedColor,
      remind: _selectedRemind,
      repeat: _selectedRepeat,
      isCompleted: widget.task.isCompleted,

    );
    if (validTime == 1){
   _taskController.deleteTask(widget.task);
   int? id = DBHelper.loggedInUserId;
   await DBHelper.insert ( updatedTask,id!);
    _taskController.getTasks();
    // TODO: Save the updated task to the database or perform any necessary updates

    Navigator.pop(context);
  }  else {
      Get.snackbar(
        "Invalid Time!",
        "make sure you insert valid time-interval.",
        snackPosition: SnackPosition.BOTTOM,
        overlayColor: context.theme.backgroundColor,
      ); }
    }

  _colorChips() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "Color",
        style: titleTextStle,
      ),
      SizedBox(
        height: 8,
      ),
      Wrap(
        children: List<Widget>.generate(
          3,
              (int index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: index == 0
                      ? primaryClr
                      : index == 1
                      ? pinkClr
                      : yellowClr,
                  child: index == _selectedColor
                      ? Center(
                    child: Icon(
                      Icons.done,
                      color: Colors.white,
                      size: 18,
                    ),
                  )
                      : Container(),
                ),
              ),
            );
          },
        ).toList(),
      ),
    ]);
  }
  }



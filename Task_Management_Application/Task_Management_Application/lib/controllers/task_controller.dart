import 'package:get/get.dart';
import 'package:task_management/db/db_helper.dart';
import 'package:task_management/models/task.dart';

class TaskController extends GetxController {
  final RxList<Task> taskList = List<Task>.empty().obs;
  int? userId = DBHelper.loggedInUserId;


  @override
  void onReady() async{
   DBHelper dbHelper = DBHelper();
   await dbHelper.deleteExpiredTasks();
    getTasks();
    super.onReady();
  }


  Future<void> addTask({required Task task}) async {
    print("addtskcontoller called");
    if (userId != null) {
      task.userId = userId; // Set the userId for the task
      await DBHelper.insert(task, userId!);
      taskList.add(task);
      print("task added successfully");
    }
    getTasks();
  }

  void getTasks() async {
    if (userId != null) {
      print("Eingeloggter Benutzer-ID: $userId");
      List<Task> tasks = await DBHelper.query();
      taskList.assignAll(tasks);
    }
  }

  void deleteTask(Task task) async {
    print("delete task");
    if (userId != null) {
      await DBHelper.delete(task);
      print("task deleted");
    }
    getTasks();
  }

  void markTaskCompleted(int? id) async {
    await DBHelper.update(id);
    getTasks();
  }


  Future<List<Task>> getWeeklyTasks() async {
    if (userId != null) {
      return await DBHelper.getWeeklyTasks(userId!);
    }
    return [];
  }
}


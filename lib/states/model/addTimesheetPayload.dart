class AddTimesheetPayload {
  String timesheetDate;
  List<TimesheetLineModel> timesheetLineModel;

  AddTimesheetPayload({
    required this.timesheetDate,
    required this.timesheetLineModel,
  });

  factory AddTimesheetPayload.fromJson(Map<String, dynamic> json) {
    return AddTimesheetPayload(
      timesheetDate: json['timesheetDate'],
      timesheetLineModel: (json['timesheetLineModel'] as List)
          .map((e) => TimesheetLineModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timesheetDate': timesheetDate,
      'timesheetLineModel':
          timesheetLineModel.map((e) => e.toJson()).toList(),
    };
  }
}

class TimesheetLineModel {
  String name;
  String projectName;
  String projectModuleName;
  String taskName;
  String description;
  int estimateHours;
  bool active;
  bool deleted;
  int sortOrder;
  String targetMonth;
  int activitiesCount;
  AssignedTo assignedTo;
  Project project;
  Task task;
  ProjectModule projectModule;
  String id;
  bool editing;
  String projectId;
  String projectModuleId;
  String projectTaskId;
  String projectActivityId;
  String moduleName;
  String projectActivityName;
  int rowCounter;
  bool isMyTaskActivity;
  String flag;
  int hours;

  TimesheetLineModel({
    required this.name,
    required this.projectName,
    required this.projectModuleName,
    required this.taskName,
    required this.description,
    required this.estimateHours,
    required this.active,
    required this.deleted,
    required this.sortOrder,
    required this.targetMonth,
    required this.activitiesCount,
    required this.assignedTo,
    required this.project,
    required this.task,
    required this.projectModule,
    required this.id,
    required this.editing,
    required this.projectId,
    required this.projectModuleId,
    required this.projectTaskId,
    required this.projectActivityId,
    required this.moduleName,
    required this.projectActivityName,
    required this.rowCounter,
    required this.isMyTaskActivity,
    required this.flag,
    required this.hours,
  });

  factory TimesheetLineModel.fromJson(Map<String, dynamic> json) {
    return TimesheetLineModel(
      name: json['name'],
      projectName: json['projectName'],
      projectModuleName: json['projectModuleName'],
      taskName: json['taskName'],
      description: json['description'],
      estimateHours: json['estimateHours'],
      active: json['active'],
      deleted: json['deleted'],
      sortOrder: json['sortOrder'],
      targetMonth: json['targetMonth'],
      activitiesCount: json['activitiesCount'],
      assignedTo: AssignedTo.fromJson(json['assignedTo']),
      project: Project.fromJson(json['project']),
      task: Task.fromJson(json['task']),
      projectModule: ProjectModule.fromJson(json['projectModule']),
      id: json['id'],
      editing: json['editing'],
      projectId: json['projectId'],
      projectModuleId: json['projectModuleId'],
      projectTaskId: json['projectTaskId'],
      projectActivityId: json['projectActivityId'],
      moduleName: json['moduleName'],
      projectActivityName: json['projectActivityName'],
      rowCounter: json['rowCounter'],
      isMyTaskActivity: json['isMyTaskActivity'],
      flag: json['flag'],
      hours: json['hours'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'projectName': projectName,
      'projectModuleName': projectModuleName,
      'taskName': taskName,
      'description': description,
      'estimateHours': estimateHours,
      'active': active,
      'deleted': deleted,
      'sortOrder': sortOrder,
      'targetMonth': targetMonth,
      'activitiesCount': activitiesCount,
      'assignedTo': assignedTo.toJson(),
      'project': project.toJson(),
      'task': task.toJson(),
      'projectModule': projectModule.toJson(),
      'id': id,
      'editing': editing,
      'projectId': projectId,
      'projectModuleId': projectModuleId,
      'projectTaskId': projectTaskId,
      'projectActivityId': projectActivityId,
      'moduleName': moduleName,
      'projectActivityName': projectActivityName,
      'rowCounter': rowCounter,
      'isMyTaskActivity': isMyTaskActivity,
      'flag': flag,
      'hours': hours,
    };
  }
}

class AssignedTo {
  bool active;
  int estimateHrs;
  Person person;
  String id;

  AssignedTo({
    required this.active,
    required this.estimateHrs,
    required this.person,
    required this.id,
  });

  factory AssignedTo.fromJson(Map<String, dynamic> json) {
    return AssignedTo(
      active: json['active'],
      estimateHrs: json['estimateHrs'],
      person: Person.fromJson(json['person']),
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active': active,
      'estimateHrs': estimateHrs,
      'person': person.toJson(),
      'id': id,
    };
  }
}

class Person {
  String firstName;
  String lastName;
  bool isCustomer;
  bool personSiteFlag;

  Person({
    required this.firstName,
    required this.lastName,
    required this.isCustomer,
    required this.personSiteFlag,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      firstName: json['firstName'],
      lastName: json['lastName'],
      isCustomer: json['isCustomer'],
      personSiteFlag: json['personSiteFlag'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'isCustomer': isCustomer,
      'personSiteFlag': personSiteFlag,
    };
  }
}

class Project {
  int year;
  String name;
  bool active;
  bool editing;
  String createdOnUtc;
  String id;

  Project({
    required this.year,
    required this.name,
    required this.active,
    required this.editing,
    required this.createdOnUtc,
    required this.id,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      year: json['year'],
      name: json['name'],
      active: json['active'],
      editing: json['editing'],
      createdOnUtc: json['createdOnUtc'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'name': name,
      'active': active,
      'editing': editing,
      'createdOnUtc': createdOnUtc,
      'id': id,
    };
  }
}

class Task {
  int projectTaskNumber;
  String name;
  int estimateTime;
  bool active;
  bool isMoved;
  int sortOrder;
  bool isDuplicate;
  String createdOnUtc;
  String id;

  Task({
    required this.projectTaskNumber,
    required this.name,
    required this.estimateTime,
    required this.active,
    required this.isMoved,
    required this.sortOrder,
    required this.isDuplicate,
    required this.createdOnUtc,
    required this.id,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      projectTaskNumber: json['projectTaskNumber'],
      name: json['name'],
      estimateTime: json['estimateTime'],
      active: json['active'],
      isMoved: json['isMoved'],
      sortOrder: json['sortOrder'],
      isDuplicate: json['isDuplicate'],
      createdOnUtc: json['createdOnUtc'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectTaskNumber': projectTaskNumber,
      'name': name,
      'estimateTime': estimateTime,
      'active': active,
      'isMoved': isMoved,
      'sortOrder': sortOrder,
      'isDuplicate': isDuplicate,
      'createdOnUtc': createdOnUtc,
      'id': id,
    };
  }
}

class ProjectModule {
  String name;
  int projectModuleNumber;
  bool active;
  int sortOrder;
  bool isDuplicate;
  bool isMoved;
  String createdOnUtc;
  String id;

  ProjectModule({
    required this.name,
    required this.projectModuleNumber,
    required this.active,
    required this.sortOrder,
    required this.isDuplicate,
    required this.isMoved,
    required this.createdOnUtc,
    required this.id,
  });

  factory ProjectModule.fromJson(Map<String, dynamic> json) {
    return ProjectModule(
      name: json['name'],
      projectModuleNumber: json['projectModuleNumber'],
      active: json['active'],
      sortOrder: json['sortOrder'],
      isDuplicate: json['isDuplicate'],
      isMoved: json['isMoved'],
      createdOnUtc: json['createdOnUtc'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'projectModuleNumber': projectModuleNumber,
      'active': active,
      'sortOrder': sortOrder,
      'isDuplicate': isDuplicate,
      'isMoved': isMoved,
      'createdOnUtc': createdOnUtc,
      'id': id,
    };
  }
}

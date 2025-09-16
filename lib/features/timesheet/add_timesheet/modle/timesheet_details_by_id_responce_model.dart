class TimeInTimeOutDetailByIdResponseModel {
  String siteId;
  String employeeId;
  String timesheetDate;
  String createdById;
  String createdOnUtc;
  bool deleted;
  Sites sites;
  List<dynamic> timesheetLineModel;
  List<TimesheetLine> timesheetLines;
  List<dynamic> timesheetDataModel;
  List<dynamic> columns;
  String id;
  Map<String, dynamic> customProperties;

  TimeInTimeOutDetailByIdResponseModel({
    required this.siteId,
    required this.employeeId,
    required this.timesheetDate,
    required this.createdById,
    required this.createdOnUtc,
    required this.deleted,
    required this.sites,
    required this.timesheetLineModel,
    required this.timesheetLines,
    required this.timesheetDataModel,
    required this.columns,
    required this.id,
    required this.customProperties,
  });

  factory TimeInTimeOutDetailByIdResponseModel.fromJson(Map<String, dynamic> json) {
    return TimeInTimeOutDetailByIdResponseModel(
      siteId: json['siteId'],
      employeeId: json['employeeId'],
      timesheetDate: json['timesheetDate'],
      createdById: json['createdById'],
      createdOnUtc: json['createdOnUtc'],
      deleted: json['deleted'],
      sites: Sites.fromJson(json['sites']),
      timesheetLineModel: List<dynamic>.from(json['timesheetLineModel'] ?? []),
      timesheetLines: (json['timesheetLines'] as List)
          .map((e) => TimesheetLine.fromJson(e))
          .toList(),
      timesheetDataModel:
          List<dynamic>.from(json['timesheetDataModel'] ?? []),
      columns: List<dynamic>.from(json['columns'] ?? []),
      id: json['id'],
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siteId': siteId,
      'employeeId': employeeId,
      'timesheetDate': timesheetDate,
      'createdById': createdById,
      'createdOnUtc': createdOnUtc,
      'deleted': deleted,
      'sites': sites.toJson(),
      'timesheetLineModel': timesheetLineModel,
      'timesheetLines': timesheetLines.map((e) => e.toJson()).toList(),
      'timesheetDataModel': timesheetDataModel,
      'columns': columns,
      'id': id,
      'customProperties': customProperties,
    };
  }
}

class Sites {
  String name;
  String createdOnUtc;
  bool active;
  bool deleted;
  bool isDropdownGenerated;
  List<dynamic> sitesRoles;
  String id;

  Sites({
    required this.name,
    required this.createdOnUtc,
    required this.active,
    required this.deleted,
    required this.isDropdownGenerated,
    required this.sitesRoles,
    required this.id,
  });

  factory Sites.fromJson(Map<String, dynamic> json) {
    return Sites(
      name: json['name'],
      createdOnUtc: json['createdOnUtc'],
      active: json['active'],
      deleted: json['deleted'],
      isDropdownGenerated: json['isDropdownGenerated'],
      sitesRoles: List<dynamic>.from(json['sitesRoles'] ?? []),
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdOnUtc': createdOnUtc,
      'active': active,
      'deleted': deleted,
      'isDropdownGenerated': isDropdownGenerated,
      'sitesRoles': sitesRoles,
      'id': id,
    };
  }
}

class TimesheetLine {
  String projectActivityId;
  String description;
  double hours;
  double billableHours;
  bool deleted;
  String taskId;
  Project project;
  ProjectModule projectModule;
  Task task;
  ProjectActivity projectActivity;
  List<dynamic> timesheetDataModel;
  List<dynamic> columns;
  String id;
  Map<String, dynamic> customProperties;

  TimesheetLine({
    required this.projectActivityId,
    required this.description,
    required this.hours,
    required this.billableHours,
    required this.deleted,
    required this.taskId,
    required this.project,
    required this.projectModule,
    required this.task,
    required this.projectActivity,
    required this.timesheetDataModel,
    required this.columns,
    required this.id,
    required this.customProperties,
  });

  factory TimesheetLine.fromJson(Map<String, dynamic> json) {
    return TimesheetLine(
      projectActivityId: json['projectActivityId'],
      description: json['description'],
      hours: (json['hours'] as num).toDouble(),
      billableHours: (json['billableHours'] as num).toDouble(),
      deleted: json['deleted'],
      taskId: json['taskId'],
      project: Project.fromJson(json['project']),
      projectModule: ProjectModule.fromJson(json['projectModule']),
      task: Task.fromJson(json['task']),
      projectActivity: ProjectActivity.fromJson(json['projectActivity']),
      timesheetDataModel:
          List<dynamic>.from(json['timesheetDataModel'] ?? []),
      columns: List<dynamic>.from(json['columns'] ?? []),
      id: json['id'],
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectActivityId': projectActivityId,
      'description': description,
      'hours': hours,
      'billableHours': billableHours,
      'deleted': deleted,
      'taskId': taskId,
      'project': project.toJson(),
      'projectModule': projectModule.toJson(),
      'task': task.toJson(),
      'projectActivity': projectActivity.toJson(),
      'timesheetDataModel': timesheetDataModel,
      'columns': columns,
      'id': id,
      'customProperties': customProperties,
    };
  }
}

class Project {
  String name;
  int year;
  bool isPinned;
  bool isTemplate;
  bool active;
  int sortOrder;
  String createdOnUtc;
  bool deleted;
  String id;

  Project({
    required this.name,
    required this.year,
    required this.isPinned,
    required this.isTemplate,
    required this.active,
    required this.sortOrder,
    required this.createdOnUtc,
    required this.deleted,
    required this.id,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'],
      year: json['year'],
      isPinned: json['isPinned'],
      isTemplate: json['isTemplate'],
      active: json['active'],
      sortOrder: json['sortOrder'],
      createdOnUtc: json['createdOnUtc'],
      deleted: json['deleted'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'year': year,
      'isPinned': isPinned,
      'isTemplate': isTemplate,
      'active': active,
      'sortOrder': sortOrder,
      'createdOnUtc': createdOnUtc,
      'deleted': deleted,
      'id': id,
    };
  }
}

class ProjectModule {
  int projectModuleNumber;
  String name;
  bool isDuplicate;
  bool isMoved;
  int sortOrder;
  bool active;
  bool deleted;
  String createdOnUtc;
  String id;

  ProjectModule({
    required this.projectModuleNumber,
    required this.name,
    required this.isDuplicate,
    required this.isMoved,
    required this.sortOrder,
    required this.active,
    required this.deleted,
    required this.createdOnUtc,
    required this.id,
  });

  factory ProjectModule.fromJson(Map<String, dynamic> json) {
    return ProjectModule(
      projectModuleNumber: json['projectModuleNumber'],
      name: json['name'],
      isDuplicate: json['isDuplicate'],
      isMoved: json['isMoved'],
      sortOrder: json['sortOrder'],
      active: json['active'],
      deleted: json['deleted'],
      createdOnUtc: json['createdOnUtc'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectModuleNumber': projectModuleNumber,
      'name': name,
      'isDuplicate': isDuplicate,
      'isMoved': isMoved,
      'sortOrder': sortOrder,
      'active': active,
      'deleted': deleted,
      'createdOnUtc': createdOnUtc,
      'id': id,
    };
  }
}

class Task {
  int projectTaskNumber;
  String name;
  int estimateTime;
  bool isDuplicate;
  bool isMoved;
  bool active;
  int sortOrder;
  bool deleted;
  String createdOnUtc;
  String id;

  Task({
    required this.projectTaskNumber,
    required this.name,
    required this.estimateTime,
    required this.isDuplicate,
    required this.isMoved,
    required this.active,
    required this.sortOrder,
    required this.deleted,
    required this.createdOnUtc,
    required this.id,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      projectTaskNumber: json['projectTaskNumber'],
      name: json['name'],
      estimateTime: json['estimateTime'],
      isDuplicate: json['isDuplicate'],
      isMoved: json['isMoved'],
      active: json['active'],
      sortOrder: json['sortOrder'],
      deleted: json['deleted'],
      createdOnUtc: json['createdOnUtc'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectTaskNumber': projectTaskNumber,
      'name': name,
      'estimateTime': estimateTime,
      'isDuplicate': isDuplicate,
      'isMoved': isMoved,
      'active': active,
      'sortOrder': sortOrder,
      'deleted': deleted,
      'createdOnUtc': createdOnUtc,
      'id': id,
    };
  }
}

class ProjectActivity {
  String name;
  int estimateHours;
  bool active;
  int sortOrder;
  bool deleted;
  String createdOnUtc;
  int activitiesCount;
  String id;

  ProjectActivity({
    required this.name,
    required this.estimateHours,
    required this.active,
    required this.sortOrder,
    required this.deleted,
    required this.createdOnUtc,
    required this.activitiesCount,
    required this.id,
  });

  factory ProjectActivity.fromJson(Map<String, dynamic> json) {
    return ProjectActivity(
      name: json['name'],
      estimateHours: json['estimateHours'],
      active: json['active'],
      sortOrder: json['sortOrder'],
      deleted: json['deleted'],
      createdOnUtc: json['createdOnUtc'],
      activitiesCount: json['activitiesCount'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'estimateHours': estimateHours,
      'active': active,
      'sortOrder': sortOrder,
      'deleted': deleted,
      'createdOnUtc': createdOnUtc,
      'activitiesCount': activitiesCount,
      'id': id,
    };
  }
}

class ProjectTaskActivityModel {
  final bool editing;
  final List<ActivityData> data;
  final int total;
  final Map<String, dynamic> customProperties;

  ProjectTaskActivityModel({
    required this.editing,
    required this.data,
    required this.total,
    required this.customProperties,
  });

  factory ProjectTaskActivityModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskActivityModel(
      editing: json['editing'],
      data: List<ActivityData>.from(json['data'].map((x) => ActivityData.fromJson(x))),
      total: json['total'],
      customProperties: json['customProperties'],
    );
  }
}

class ActivityData {
  final String siteId;
  final String projectId;
  final String projectModuleId;
  final String name;
  final String projectName;
  final String projectModuleName;
  final String taskName;
  final String assignedToId;
  final double estimateHours;
  final bool active;
  final bool deleted;
  final int sortOrder;
  final String targetMonth;
  final int activitiesCount;
  final AssignedTo assignedTo;
  final Project project;
  final Task task;
  final ProjectModule projectModule;
  final ActivityStatus activityStatus;
  final String id;
  final Map<String, dynamic> customProperties;

  ActivityData({
    required this.siteId,
    required this.projectId,
    required this.projectModuleId,
    required this.name,
    required this.projectName,
    required this.projectModuleName,
    required this.taskName,
    required this.assignedToId,
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
    required this.activityStatus,
    required this.id,
    required this.customProperties,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      siteId: json['siteId'],
      projectId: json['projectId'],
      projectModuleId: json['projectModuleId'],
      name: json['name'],
      projectName: json['projectName'],
      projectModuleName: json['projectModuleName'],
      taskName: json['taskName'],
      assignedToId: json['assignedToId'],
      estimateHours: json['estimateHours'].toDouble(),
      active: json['active'],
      deleted: json['deleted'],
      sortOrder: json['sortOrder'],
      targetMonth: json['targetMonth'],
      activitiesCount: json['activitiesCount'],
      assignedTo: AssignedTo.fromJson(json['assignedTo']),
      project: Project.fromJson(json['project']),
      task: Task.fromJson(json['task']),
      projectModule: ProjectModule.fromJson(json['projectModule']),
      activityStatus: ActivityStatus.fromJson(json['activityStatus']),
      id: json['id'],
      customProperties: json['customProperties'],
    );
  }
}

class AssignedTo {
  final bool active;
  final double estimateHrs;
  final Person person;
  final String id;
  final Map<String, dynamic> customProperties;

  AssignedTo({
    required this.active,
    required this.estimateHrs,
    required this.person,
    required this.id,
    required this.customProperties,
  });

  factory AssignedTo.fromJson(Map<String, dynamic> json) {
    return AssignedTo(
      active: json['active'],
      estimateHrs: json['estimateHrs'].toDouble(),
      person: Person.fromJson(json['person']),
      id: json['id'],
      customProperties: json['customProperties'],
    );
  }
}

class Person {
  final String fullName;
  final String firstName;
  final String lastName;
  final bool isCustomer;
  final bool personSiteFlag;
  final Map<String, dynamic> customProperties;

  Person({
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.isCustomer,
    required this.personSiteFlag,
    required this.customProperties,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      fullName: json['fullName'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      isCustomer: json['isCustomer'],
      personSiteFlag: json['personSiteFlag'],
      customProperties: json['customProperties'],
    );
  }
}

class Project {
  final int year;
  final String name;
  final bool active;
  final bool editing;
  final int projectNotesCount;
  final int completedTaskCount;
  final int totalTaskCount;
  final int projectSwimlaneCount;
  final int completedIssueCount;
  final int totalIssueCount;
  final int completedRequirementCount;
  final int totalRequirementCount;
  final int totalTaskEstimateHours;
  final int totalActivityHours;
  final int totalModuleCount;
  final bool isTemplate;
  final bool isPinned;
  final int sortOrder;
  final String createdOnUtc;
  final bool deleted;
  final String id;
  final Map<String, dynamic> customProperties;

  Project({
    required this.year,
    required this.name,
    required this.active,
    required this.editing,
    required this.projectNotesCount,
    required this.completedTaskCount,
    required this.totalTaskCount,
    required this.projectSwimlaneCount,
    required this.completedIssueCount,
    required this.totalIssueCount,
    required this.completedRequirementCount,
    required this.totalRequirementCount,
    required this.totalTaskEstimateHours,
    required this.totalActivityHours,
    required this.totalModuleCount,
    required this.isTemplate,
    required this.isPinned,
    required this.sortOrder,
    required this.createdOnUtc,
    required this.deleted,
    required this.id,
    required this.customProperties,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      year: json['year'],
      name: json['name'],
      active: json['active'],
      editing: json['editing'],
      projectNotesCount: json['projectNotesCount'],
      completedTaskCount: json['completedTaskCount'],
      totalTaskCount: json['totalTaskCount'],
      projectSwimlaneCount: json['projectSwimlaneCount'],
      completedIssueCount: json['completedIssueCount'],
      totalIssueCount: json['totalIssueCount'],
      completedRequirementCount: json['completedRequirementCount'],
      totalRequirementCount: json['totalRequirementCount'],
      totalTaskEstimateHours: json['totalTaskEstimateHours'],
      totalActivityHours: json['totalActivityHours'],
      totalModuleCount: json['totalModuleCount'],
      isTemplate: json['isTemplate'],
      isPinned: json['isPinned'],
      sortOrder: json['sortOrder'],
      createdOnUtc: json['createdOnUtc'],
      deleted: json['deleted'],
      id: json['id'],
      customProperties: json['customProperties'],
    );
  }
}

class Task {
  final String projectId;
  final int projectTaskNumber;
  final String projectModuleId;
  final String name;
  final String description;
  final String priorityId;
  final double estimateTime;
  final bool active;
  final bool isMoved;
  final int sortOrder;
  final int activitiesCount;
  final bool isDuplicate;
  final int projectNotesCount;
  final int projectTaskNotesCount;
  final String startDate;
  final String endDate;
  final String createdOnUtc;
  final int totalTimesheetEstHours;
  final Status status;
  final String id;
  final Map<String, dynamic> customProperties;

  Task({
    required this.projectId,
    required this.projectTaskNumber,
    required this.projectModuleId,
    required this.name,
    required this.description,
    required this.priorityId,
    required this.estimateTime,
    required this.active,
    required this.isMoved,
    required this.sortOrder,
    required this.activitiesCount,
    required this.isDuplicate,
    required this.projectNotesCount,
    required this.projectTaskNotesCount,
    required this.startDate,
    required this.endDate,
    required this.createdOnUtc,
    required this.totalTimesheetEstHours,
    required this.status,
    required this.id,
    required this.customProperties,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      projectId: json['projectId'],
      projectTaskNumber: json['projectTaskNumber'],
      projectModuleId: json['projectModuleId'],
      name: json['name'],
      description: json['description'],
      priorityId: json['priorityId'],
      estimateTime: json['estimateTime'].toDouble(),
      active: json['active'],
      isMoved: json['isMoved'],
      sortOrder: json['sortOrder'],
      activitiesCount: json['activitiesCount'],
      isDuplicate: json['isDuplicate'],
      projectNotesCount: json['projectNotesCount'],
      projectTaskNotesCount: json['projectTaskNotesCount'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      createdOnUtc: json['createdOnUtc'],
      totalTimesheetEstHours: json['totalTimesheetEstHours'],
      status: Status.fromJson(json['status']),
      id: json['id'],
      customProperties: json['customProperties'],
    );
  }
}

class Status {
  final String dropDownValue;
  final int sortOrder;
  final bool active;
  final String id;
  final Map<String, dynamic> customProperties;

  Status({
    required this.dropDownValue,
    required this.sortOrder,
    required this.active,
    required this.id,
    required this.customProperties,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      dropDownValue: json['dropDownValue'],
      sortOrder: json['sortOrder'],
      active: json['active'],
      id: json['id'],
      customProperties: json['customProperties'],
    );
  }
}

class ProjectModule {
  final String name;
  final int projectModuleNumber;
  final bool active;
  final int sortOrder;
  final bool isDuplicate;
  final bool isMoved;
  final int projectTasksCount;
  final String createdOnUtc;
  final int projectModuleNotesCount;
  final String id;
  final Map<String, dynamic> customProperties;

  ProjectModule({
    required this.name,
    required this.projectModuleNumber,
    required this.active,
    required this.sortOrder,
    required this.isDuplicate,
    required this.isMoved,
    required this.projectTasksCount,
    required this.createdOnUtc,
    required this.projectModuleNotesCount,
    required this.id,
    required this.customProperties,
  });

  factory ProjectModule.fromJson(Map<String, dynamic> json) {
    return ProjectModule(
      name: json['name'],
      projectModuleNumber: json['projectModuleNumber'],
      active: json['active'],
      sortOrder: json['sortOrder'],
      isDuplicate: json['isDuplicate'],
      isMoved: json['isMoved'],
      projectTasksCount: json['projectTasksCount'],
      createdOnUtc: json['createdOnUtc'],
      projectModuleNotesCount: json['projectModuleNotesCount'],
      id: json['id'],
      customProperties: json['customProperties'],
    );
  }
}

class ActivityStatus {
  final String dropDownValue;
  final int sortOrder;
  final bool active;
  final String id;
  final Map<String, dynamic> customProperties;

  ActivityStatus({
    required this.dropDownValue,
    required this.sortOrder,
    required this.active,
    required this.id,
    required this.customProperties,
  });

  factory ActivityStatus.fromJson(Map<String, dynamic> json) {
    return ActivityStatus(
      dropDownValue: json['dropDownValue'],
      sortOrder: json['sortOrder'],
      active: json['active'],
      id: json['id'],
      customProperties: json['customProperties'],
    );
  }
}

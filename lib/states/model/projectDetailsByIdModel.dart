// ✅ Updated projectDetailsByIdModel with null safety fixes
class projectDetailsByIdModel {
  final String name;
  final String projectName;
  final String projectModuleName;
  final String taskName;
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
  final String id;
  final Map<String, dynamic> customProperties;

  projectDetailsByIdModel({
    required this.name,
    required this.projectName,
    required this.projectModuleName,
    required this.taskName,
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
    required this.customProperties,
  });

  factory projectDetailsByIdModel.fromJson(Map<String, dynamic> json) {
    return projectDetailsByIdModel(
      name: json['name'] ?? '',
      projectName: json['projectName'] ?? '',
      projectModuleName: json['projectModuleName'] ?? '',
      taskName: json['taskName'] ?? '',
      estimateHours: (json['estimateHours'] ?? 0).toDouble(),
      active: json['active'] ?? false,
      deleted: json['deleted'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      targetMonth: json['targetMonth'] ?? '',
      activitiesCount: json['activitiesCount'] ?? 0,
      assignedTo: json['assignedTo'] != null ? AssignedTo.fromJson(json['assignedTo']) : AssignedTo.empty(),
      project: json['project'] != null ? Project.fromJson(json['project']) : Project.empty(),
      task: json['task'] != null ? Task.fromJson(json['task']) : Task.empty(),
      projectModule: json['projectModule'] != null ? ProjectModule.fromJson(json['projectModule']) : ProjectModule.empty(),
      id: json['id'] ?? '',
      customProperties: json['customProperties'] ?? {},
    );
  }
}

class AssignedTo {
  final bool active;
  final int estimateHrs;
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
      active: json['active'] ?? false,
      estimateHrs: json['estimateHrs'] ?? 0,
      person: json['person'] != null ? Person.fromJson(json['person']) : Person.empty(),
      id: json['id'] ?? '',
      customProperties: json['customProperties'] ?? {},
    );
  }

  factory AssignedTo.empty() {
    return AssignedTo(
      active: false,
      estimateHrs: 0,
      person: Person.empty(),
      id: '',
      customProperties: {},
    );
  }
}

class Person {
  final String firstName;
  final String lastName;
  final bool isCustomer;
  final bool personSiteFlag;
  final Map<String, dynamic> customProperties;

  Person({
    required this.firstName,
    required this.lastName,
    required this.isCustomer,
    required this.personSiteFlag,
    required this.customProperties,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      isCustomer: json['isCustomer'] ?? false,
      personSiteFlag: json['personSiteFlag'] ?? false,
      customProperties: json['customProperties'] ?? {},
    );
  }

  factory Person.empty() {
    return Person(
      firstName: '',
      lastName: '',
      isCustomer: false,
      personSiteFlag: false,
      customProperties: {},
    );
  }
}

class Project {
  final String name;
  final String createdOnUtc;
  final String id;
  final bool active;
  final bool editing;
  final bool isTemplate;
  final bool isPinned;
  final bool deleted;
  final int year;
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
  final int sortOrder;
  final Map<String, dynamic> customProperties;

  Project({
    required this.name,
    required this.createdOnUtc,
    required this.id,
    required this.active,
    required this.editing,
    required this.isTemplate,
    required this.isPinned,
    required this.deleted,
    required this.year,
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
    required this.sortOrder,
    required this.customProperties,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'] ?? '',
      createdOnUtc: json['createdOnUtc'] ?? '',
      id: json['id'] ?? '',
      active: json['active'] ?? false,
      editing: json['editing'] ?? false,
      isTemplate: json['isTemplate'] ?? false,
      isPinned: json['isPinned'] ?? false,
      deleted: json['deleted'] ?? false,
      year: json['year'] ?? 0,
      projectNotesCount: json['projectNotesCount'] ?? 0,
      completedTaskCount: json['completedTaskCount'] ?? 0,
      totalTaskCount: json['totalTaskCount'] ?? 0,
      projectSwimlaneCount: json['projectSwimlaneCount'] ?? 0,
      completedIssueCount: json['completedIssueCount'] ?? 0,
      totalIssueCount: json['totalIssueCount'] ?? 0,
      completedRequirementCount: json['completedRequirementCount'] ?? 0,
      totalRequirementCount: json['totalRequirementCount'] ?? 0,
      totalTaskEstimateHours: json['totalTaskEstimateHours'] ?? 0,
      totalActivityHours: json['totalActivityHours'] ?? 0,
      totalModuleCount: json['totalModuleCount'] ?? 0,
      sortOrder: json['sortOrder'] ?? 0,
      customProperties: json['customProperties'] ?? {},
    );
  }

  factory Project.empty() {
    return Project(
      name: '',
      createdOnUtc: '',
      id: '',
      active: false,
      editing: false,
      isTemplate: false,
      isPinned: false,
      deleted: false,
      year: 0,
      projectNotesCount: 0,
      completedTaskCount: 0,
      totalTaskCount: 0,
      projectSwimlaneCount: 0,
      completedIssueCount: 0,
      totalIssueCount: 0,
      completedRequirementCount: 0,
      totalRequirementCount: 0,
      totalTaskEstimateHours: 0,
      totalActivityHours: 0,
      totalModuleCount: 0,
      sortOrder: 0,
      customProperties: {},
    );
  }
}

class Task {
  final String name;
  final String createdOnUtc;
  final String id;
  final int projectTaskNumber;
  final int estimateTime;
  final int sortOrder;
  final int activitiesCount;
  final int projectNotesCount;
  final int projectTaskNotesCount;
  final int totalTimesheetEstHours;
  final bool active;
  final bool isMoved;
  final bool isDuplicate;
  final Map<String, dynamic> customProperties;

  Task({
    required this.name,
    required this.createdOnUtc,
    required this.id,
    required this.projectTaskNumber,
    required this.estimateTime,
    required this.sortOrder,
    required this.activitiesCount,
    required this.projectNotesCount,
    required this.projectTaskNotesCount,
    required this.totalTimesheetEstHours,
    required this.active,
    required this.isMoved,
    required this.isDuplicate,
    required this.customProperties,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      name: json['name'] ?? '',
      createdOnUtc: json['createdOnUtc'] ?? '',
      id: json['id'] ?? '',
      projectTaskNumber: json['projectTaskNumber'] ?? 0,
      estimateTime: json['estimateTime'] ?? 0,
      sortOrder: json['sortOrder'] ?? 0,
      activitiesCount: json['activitiesCount'] ?? 0,
      projectNotesCount: json['projectNotesCount'] ?? 0,
      projectTaskNotesCount: json['projectTaskNotesCount'] ?? 0,
      totalTimesheetEstHours: json['totalTimesheetEstHours'] ?? 0,
      active: json['active'] ?? false,
      isMoved: json['isMoved'] ?? false,
      isDuplicate: json['isDuplicate'] ?? false,
      customProperties: json['customProperties'] ?? {},
    );
  }

  factory Task.empty() {
    return Task(
      name: '',
      createdOnUtc: '',
      id: '',
      projectTaskNumber: 0,
      estimateTime: 0,
      sortOrder: 0,
      activitiesCount: 0,
      projectNotesCount: 0,
      projectTaskNotesCount: 0,
      totalTimesheetEstHours: 0,
      active: false,
      isMoved: false,
      isDuplicate: false,
      customProperties: {},
    );
  }
}

class ProjectModule {
  final String name;
  final String createdOnUtc;
  final String id;
  final int projectModuleNumber;
  final int sortOrder;
  final int projectTasksCount;
  final int projectModuleNotesCount;
  final bool active;
  final bool isDuplicate;
  final bool isMoved;
  final Map<String, dynamic> customProperties;

  ProjectModule({
    required this.name,
    required this.createdOnUtc,
    required this.id,
    required this.projectModuleNumber,
    required this.sortOrder,
    required this.projectTasksCount,
    required this.projectModuleNotesCount,
    required this.active,
    required this.isDuplicate,
    required this.isMoved,
    required this.customProperties,
  });

  factory ProjectModule.fromJson(Map<String, dynamic> json) {
    return ProjectModule(
      name: json['name'] ?? '',
      createdOnUtc: json['createdOnUtc'] ?? '',
      id: json['id'] ?? '',
      projectModuleNumber: json['projectModuleNumber'] ?? 0,
      sortOrder: json['sortOrder'] ?? 0,
      projectTasksCount: json['projectTasksCount'] ?? 0,
      projectModuleNotesCount: json['projectModuleNotesCount'] ?? 0,
      active: json['active'] ?? false,
      isDuplicate: json['isDuplicate'] ?? false,
      isMoved: json['isMoved'] ?? false,
      customProperties: json['customProperties'] ?? {},
    );
  }

  factory ProjectModule.empty() {
    return ProjectModule(
      name: '',
      createdOnUtc: '',
      id: '',
      projectModuleNumber: 0,
      sortOrder: 0,
      projectTasksCount: 0,
      projectModuleNotesCount: 0,
      active: false,
      isDuplicate: false,
      isMoved: false,
      customProperties: {},
    );
  }
}
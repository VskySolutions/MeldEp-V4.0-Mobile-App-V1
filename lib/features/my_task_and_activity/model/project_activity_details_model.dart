class ProjectActivityDetailsModel {
  final String id;
  final String siteId;
  final String projectId;
  final String taskId;
  final String projectModuleId;
  final String activityStatusId;
  final String name;
  final String projectName;
  final String projectModuleName;
  final String taskName;
  final String description;
  final String assignedToId;
  final double estimateHours;
  final bool active;
  final bool deleted;
  final int sortOrder;
  final String activityNameDescription;
  final int activitiesCount;
  final AssignedTo assignedTo;
  final Project project;
  final Task task;
  final ProjectModule projectModule;
  final ActivityStatus activityStatus;
  final CreatedByUser createdByUser;
  final UpdatedByUser updatedByUser;

  ProjectActivityDetailsModel({
    required this.id,
    required this.siteId,
    required this.projectId,
    required this.taskId,
    required this.projectModuleId,
    required this.activityStatusId,
    required this.name,
    required this.projectName,
    required this.projectModuleName,
    required this.taskName,
    required this.description,
    required this.assignedToId,
    required this.estimateHours,
    required this.active,
    required this.deleted,
    required this.sortOrder,
    required this.activityNameDescription,
    required this.activitiesCount,
    required this.assignedTo,
    required this.project,
    required this.task,
    required this.projectModule,
    required this.activityStatus,
    required this.createdByUser,
    required this.updatedByUser,
  });

  factory ProjectActivityDetailsModel.fromJson(Map<String, dynamic> json) {
    return ProjectActivityDetailsModel(
      id: json['id'] ?? '',
      siteId: json['siteId'] ?? '',
      projectId: json['projectId'] ?? '',
      taskId: json['taskId'] ?? '',
      projectModuleId: json['projectModuleId'] ?? '',
      activityStatusId: json['activityStatusId'] ?? '',
      name: json['name'] ?? '',
      projectName: json['projectName'] ?? '',
      projectModuleName: json['projectModuleName'] ?? '',
      taskName: json['taskName'] ?? '',
      description: json['description'] ?? '',
      assignedToId: json['assignedToId'] ?? '',
      estimateHours: (json['estimateHours'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] ?? false,
      deleted: json['deleted'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      activityNameDescription: json['activityNameDescription'] ?? '',
      activitiesCount: json['activitiesCount'] ?? 0,
      assignedTo: AssignedTo.fromJson(json['assignedTo'] ?? {}),
      project: Project.fromJson(json['project'] ?? {}),
      task: Task.fromJson(json['task'] ?? {}),
      projectModule: ProjectModule.fromJson(json['projectModule'] ?? {}),
      activityStatus: ActivityStatus.fromJson(json['activityStatus'] ?? {}),
      createdByUser: CreatedByUser.fromJson(json['createdByUser'] ?? {}),
      updatedByUser: UpdatedByUser.fromJson(json['updatedByUser'] ?? {}),
    );
  }
}

class AssignedTo {
  final bool active;
  final double estimateHrs;
  final Person person;
  final String id;

  AssignedTo({
    required this.active,
    required this.estimateHrs,
    required this.person,
    required this.id,
  });

  factory AssignedTo.fromJson(Map<String, dynamic> json) {
    return AssignedTo(
      active: json['active'] ?? false,
      estimateHrs: (json['estimateHrs'] as num?)?.toDouble() ?? 0.0,
      person: Person.fromJson(json['person'] ?? {}),
      id: json['id'] ?? '',
    );
  }
}

class Person {
  final String firstName;
  final String lastName;
  final bool isCustomer;
  final bool personSiteFlag;

  Person({
    required this.firstName,
    required this.lastName,
    required this.isCustomer,
    required this.personSiteFlag,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      isCustomer: json['isCustomer'] ?? false,
      personSiteFlag: json['personSiteFlag'] ?? false,
    );
  }
}

class Project {
  final int year;
  final String name;
  final bool active;
  final String id;

  Project({
    required this.year,
    required this.name,
    required this.active,
    required this.id,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      year: json['year'] ?? 0,
      name: json['name'] ?? '',
      active: json['active'] ?? false,
      id: json['id'] ?? '',
    );
  }
}

class Task {
  final String projectId;
  final String name;
  final String description;
  final double estimateTime;
  final String startDate;
  final String endDate;
  final String id;
  final Status status;

  Task({
    required this.projectId,
    required this.name,
    required this.description,
    required this.estimateTime,
    required this.startDate,
    required this.endDate,
    required this.id,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      projectId: json['projectId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      estimateTime: (json['estimateTime'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      id: json['id'] ?? '',
      status: Status.fromJson(json['status'] ?? {}),
    );
  }
}

class Status {
  final String dropDownValue;

  Status({required this.dropDownValue});

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      dropDownValue: json['dropDownValue'] ?? '',
    );
  }
}

class ProjectModule {
  final String name;
  final String id;

  ProjectModule({required this.name, required this.id});

  factory ProjectModule.fromJson(Map<String, dynamic> json) {
    return ProjectModule(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
    );
  }
}

class ActivityStatus {
  final String dropDownValue;

  ActivityStatus({required this.dropDownValue});

  factory ActivityStatus.fromJson(Map<String, dynamic> json) {
    return ActivityStatus(
      dropDownValue: json['dropDownValue'] ?? '',
    );
  }
}

class CreatedByUser {
  final bool active;
  final bool deleted;
  final PersonWithFullName person;
  final String id;

  CreatedByUser({
    required this.active,
    required this.deleted,
    required this.person,
    required this.id,
  });

  factory CreatedByUser.fromJson(Map<String, dynamic> json) {
    return CreatedByUser(
      active: json['active'] ?? false,
      deleted: json['deleted'] ?? false,
      person: PersonWithFullName.fromJson(json['person'] ?? {}),
      id: json['id'] ?? '',
    );
  }
}

class UpdatedByUser {
  final bool active;
  final bool deleted;
  final PersonWithFullName person;
  final String id;

  UpdatedByUser({
    required this.active,
    required this.deleted,
    required this.person,
    required this.id,
  });

  factory UpdatedByUser.fromJson(Map<String, dynamic> json) {
    return UpdatedByUser(
      active: json['active'] ?? false,
      deleted: json['deleted'] ?? false,
      person: PersonWithFullName.fromJson(json['person'] ?? {}),
      id: json['id'] ?? '',
    );
  }
}

class PersonWithFullName {
  final bool deleted;
  final bool isCustomer;
  final String fullName;

  PersonWithFullName({
    required this.deleted,
    required this.isCustomer,
    required this.fullName,
  });

  factory PersonWithFullName.fromJson(Map<String, dynamic> json) {
    return PersonWithFullName(
      deleted: json['deleted'] ?? false,
      isCustomer: json['isCustomer'] ?? false,
      fullName: json['fullName'] ?? '',
    );
  }
}
import 'dart:convert';

class TaskAndActivityDetailsModel {
  final bool editing;
  final List<ProjectActivityListItem> data;
  final int total;
  final Map<String, dynamic> customProperties;

  TaskAndActivityDetailsModel({
    required this.editing,
    required this.data,
    required this.total,
    required this.customProperties,
  });

  factory TaskAndActivityDetailsModel.fromJson(Map<String, dynamic> json) {
    return TaskAndActivityDetailsModel(
      editing: json['editing'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectActivityListItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'editing': editing,
        'data': data.map((e) => e.toJson()).toList(),
        'total': total,
        'customProperties': customProperties,
      };
}

class ProjectActivityListItem {
  final String siteId;
  final String projectId;
  final String projectModuleId;
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

  final String createdOnUtc;
  final List<dynamic> projectActivities;
  final List<dynamic> projectActivityLines;
  final List<dynamic> projectEmployeeMappings;
  final List<dynamic> projectTaskActivityFilesList;
  final List<dynamic> projectTasks;
  final List<dynamic> storyBoards;

  final String id;
  final Map<String, dynamic> customProperties;

  ProjectActivityListItem({
    required this.siteId,
    required this.projectId,
    required this.projectModuleId,
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
    required this.createdOnUtc,
    required this.projectActivities,
    required this.projectActivityLines,
    required this.projectEmployeeMappings,
    required this.projectTaskActivityFilesList,
    required this.projectTasks,
    required this.storyBoards,
    required this.id,
    required this.customProperties,
  });

  factory ProjectActivityListItem.fromJson(Map<String, dynamic> json) {
    return ProjectActivityListItem(
      siteId: json['siteId'] ?? '',
      projectId: json['projectId'] ?? '',
      projectModuleId: json['projectModuleId'] ?? '',
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
      assignedTo: AssignedTo.fromJson(json['assignedTo'] ?? const {}),
      project: Project.fromJson(json['project'] ?? const {}),
      task: Task.fromJson(json['task'] ?? const {}),
      projectModule: ProjectModule.fromJson(json['projectModule'] ?? const {}),
      activityStatus:
          ActivityStatus.fromJson(json['activityStatus'] ?? const {}),
      createdOnUtc: json['createdOnUtc'] ?? '',
      projectActivities:
          List<dynamic>.from(json['projectActivities'] ?? const []),
      projectActivityLines:
          List<dynamic>.from(json['projectActivityLines'] ?? const []),
      projectEmployeeMappings:
          List<dynamic>.from(json['projectEmployeeMappings'] ?? const []),
      projectTaskActivityFilesList:
          List<dynamic>.from(json['projectTaskActivityFilesList'] ?? const []),
      projectTasks: List<dynamic>.from(json['projectTasks'] ?? const []),
      storyBoards: List<dynamic>.from(json['storyBoards'] ?? const []),
      id: json['id'] ?? '',
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'siteId': siteId,
        'projectId': projectId,
        'projectModuleId': projectModuleId,
        'name': name,
        'projectName': projectName,
        'projectModuleName': projectModuleName,
        'taskName': taskName,
        'description': description,
        'assignedToId': assignedToId,
        'estimateHours': estimateHours,
        'active': active,
        'deleted': deleted,
        'sortOrder': sortOrder,
        'activityNameDescription': activityNameDescription,
        'activitiesCount': activitiesCount,
        'assignedTo': assignedTo.toJson(),
        'project': project.toJson(),
        'task': task.toJson(),
        'projectModule': projectModule.toJson(),
        'activityStatus': activityStatus.toJson(),
        'createdOnUtc': createdOnUtc,
        'projectActivities': projectActivities,
        'projectActivityLines': projectActivityLines,
        'projectEmployeeMappings': projectEmployeeMappings,
        'projectTaskActivityFilesList': projectTaskActivityFilesList,
        'projectTasks': projectTasks,
        'storyBoards': storyBoards,
        'id': id,
        'customProperties': customProperties,
      };
}

// ------------------ Nested / Reusable Models ------------------

class AssignedTo {
  final bool active;
  final double estimateHrs;
  final Person person;
  final String id;

  final List<dynamic> employeeTypeModel;
  final List<dynamic> employeeStatusModel;
  final List<dynamic> employeeDepartmentModel;
  final List<dynamic> employeeDesignationModel;
  final List<dynamic> employeeOrgLocationModel;
  final List<dynamic> employeeClientLocationModel;
  final List<dynamic> employeeDepartment;
  final List<dynamic> employeeDesignation;
  final List<dynamic> employeeStatuses;
  final List<dynamic> employeeType;
  final List<dynamic> employeeOrgLocation;
  final List<dynamic> employeeClientLocation;
  final List<dynamic> employeeAssignedHours;
  final Map<String, dynamic> customProperties;

  AssignedTo({
    required this.active,
    required this.estimateHrs,
    required this.person,
    required this.id,
    required this.employeeTypeModel,
    required this.employeeStatusModel,
    required this.employeeDepartmentModel,
    required this.employeeDesignationModel,
    required this.employeeOrgLocationModel,
    required this.employeeClientLocationModel,
    required this.employeeDepartment,
    required this.employeeDesignation,
    required this.employeeStatuses,
    required this.employeeType,
    required this.employeeOrgLocation,
    required this.employeeClientLocation,
    required this.employeeAssignedHours,
    required this.customProperties,
  });

  factory AssignedTo.fromJson(Map<String, dynamic> json) {
    return AssignedTo(
      active: json['active'] ?? false,
      estimateHrs: (json['estimateHrs'] as num?)?.toDouble() ?? 0.0,
      person: Person.fromJson(json['person'] ?? const {}),
      id: json['id'] ?? '',
      employeeTypeModel:
          List<dynamic>.from(json['employeeTypeModel'] ?? const []),
      employeeStatusModel:
          List<dynamic>.from(json['employeeStatusModel'] ?? const []),
      employeeDepartmentModel:
          List<dynamic>.from(json['employeeDepartmentModel'] ?? const []),
      employeeDesignationModel:
          List<dynamic>.from(json['employeeDesignationModel'] ?? const []),
      employeeOrgLocationModel:
          List<dynamic>.from(json['employeeOrgLocationModel'] ?? const []),
      employeeClientLocationModel:
          List<dynamic>.from(json['employeeClientLocationModel'] ?? const []),
      employeeDepartment:
          List<dynamic>.from(json['employeeDepartment'] ?? const []),
      employeeDesignation:
          List<dynamic>.from(json['employeeDesignation'] ?? const []),
      employeeStatuses:
          List<dynamic>.from(json['employeeStatuses'] ?? const []),
      employeeType: List<dynamic>.from(json['employeeType'] ?? const []),
      employeeOrgLocation:
          List<dynamic>.from(json['employeeOrgLocation'] ?? const []),
      employeeClientLocation:
          List<dynamic>.from(json['employeeClientLocation'] ?? const []),
      employeeAssignedHours:
          List<dynamic>.from(json['employeeAssignedHours'] ?? const []),
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'active': active,
        'estimateHrs': estimateHrs,
        'person': person.toJson(),
        'id': id,
        'employeeTypeModel': employeeTypeModel,
        'employeeStatusModel': employeeStatusModel,
        'employeeDepartmentModel': employeeDepartmentModel,
        'employeeDesignationModel': employeeDesignationModel,
        'employeeOrgLocationModel': employeeOrgLocationModel,
        'employeeClientLocationModel': employeeClientLocationModel,
        'employeeDepartment': employeeDepartment,
        'employeeDesignation': employeeDesignation,
        'employeeStatuses': employeeStatuses,
        'employeeType': employeeType,
        'employeeOrgLocation': employeeOrgLocation,
        'employeeClientLocation': employeeClientLocation,
        'employeeAssignedHours': employeeAssignedHours,
        'customProperties': customProperties,
      };
}

class Person {
  final String firstName;
  final String lastName;
  final String fullName;
  final bool isCustomer;
  final bool personSiteFlag;
  final Map<String, dynamic> customProperties;

  Person({
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.isCustomer,
    required this.personSiteFlag,
    required this.customProperties,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      isCustomer: json['isCustomer'] ?? false,
      personSiteFlag: json['personSiteFlag'] ?? false,
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'isCustomer': isCustomer,
        'personSiteFlag': personSiteFlag,
        'customProperties': customProperties,
      };
}

class Project {
  final int year;
  final String name;
  final bool active;
  final String id;

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
  final int totalTasksCount;
  final bool isTemplate;
  final bool isPinned;
  final int sortOrder;
  final String createdOnUtc;
  final bool deleted;
  final bool isCharter;

  final Status? projectStatus;

  final List<dynamic> projectActivities;
  final List<dynamic> projectEmployeeMappings;
  final List<dynamic> projectFileList;
  final List<dynamic> projectTasks;
  final List<dynamic> storyBoards;
  final List<dynamic> projectModules;
  final List<dynamic> projectsMessages;
  final List<dynamic> projectUserMappings;
  final List<dynamic> projectTags;
  final List<dynamic> issue;
  final List<dynamic> requirement;
  final List<dynamic> testPlans;
  final List<dynamic> timesheetLine;
  final List<dynamic> projectWeeklyPlans;
  final List<dynamic> weeklyPlan;
  final List<dynamic> monthlyPlan;
  final Map<String, dynamic> customProperties;

  Project({
    required this.year,
    required this.name,
    required this.active,
    required this.id,
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
    required this.totalTasksCount,
    required this.isTemplate,
    required this.isPinned,
    required this.sortOrder,
    required this.createdOnUtc,
    required this.deleted,
    required this.isCharter,
    required this.projectStatus,
    required this.projectActivities,
    required this.projectEmployeeMappings,
    required this.projectFileList,
    required this.projectTasks,
    required this.storyBoards,
    required this.projectModules,
    required this.projectsMessages,
    required this.projectUserMappings,
    required this.projectTags,
    required this.issue,
    required this.requirement,
    required this.testPlans,
    required this.timesheetLine,
    required this.projectWeeklyPlans,
    required this.weeklyPlan,
    required this.monthlyPlan,
    required this.customProperties,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      year: json['year'] ?? 0,
      name: json['name'] ?? '',
      active: json['active'] ?? false,
      id: json['id'] ?? '',
      editing: json['editing'] ?? false,
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
      totalTasksCount: json['totalTasksCount'] ?? 0,
      isTemplate: json['isTemplate'] ?? false,
      isPinned: json['isPinned'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      createdOnUtc: json['createdOnUtc'] ?? '',
      deleted: json['deleted'] ?? false,
      isCharter: json['isCharter'] ?? false,
      projectStatus: json['projectStatus'] != null
          ? Status.fromJson(json['projectStatus'])
          : null,
      projectActivities:
          List<dynamic>.from(json['projectActivities'] ?? const []),
      projectEmployeeMappings:
          List<dynamic>.from(json['projectEmployeeMappings'] ?? const []),
      projectFileList: List<dynamic>.from(json['projectFileList'] ?? const []),
      projectTasks: List<dynamic>.from(json['projectTasks'] ?? const []),
      storyBoards: List<dynamic>.from(json['storyBoards'] ?? const []),
      projectModules: List<dynamic>.from(json['projectModules'] ?? const []),
      projectsMessages:
          List<dynamic>.from(json['projectsMessages'] ?? const []),
      projectUserMappings:
          List<dynamic>.from(json['projectUserMappings'] ?? const []),
      projectTags: List<dynamic>.from(json['projectTags'] ?? const []),
      issue: List<dynamic>.from(json['issue'] ?? const []),
      requirement: List<dynamic>.from(json['requirement'] ?? const []),
      testPlans: List<dynamic>.from(json['testPlans'] ?? const []),
      timesheetLine: List<dynamic>.from(json['timesheetLine'] ?? const []),
      projectWeeklyPlans:
          List<dynamic>.from(json['projectWeeklyPlans'] ?? const []),
      weeklyPlan: List<dynamic>.from(json['weeklyPlan'] ?? const []),
      monthlyPlan: List<dynamic>.from(json['monthlyPlan'] ?? const []),
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'name': name,
        'active': active,
        'id': id,
        'editing': editing,
        'projectNotesCount': projectNotesCount,
        'completedTaskCount': completedTaskCount,
        'totalTaskCount': totalTaskCount,
        'projectSwimlaneCount': projectSwimlaneCount,
        'completedIssueCount': completedIssueCount,
        'totalIssueCount': totalIssueCount,
        'completedRequirementCount': completedRequirementCount,
        'totalRequirementCount': totalRequirementCount,
        'totalTaskEstimateHours': totalTaskEstimateHours,
        'totalActivityHours': totalActivityHours,
        'totalModuleCount': totalModuleCount,
        'totalTasksCount': totalTasksCount,
        'isTemplate': isTemplate,
        'isPinned': isPinned,
        'sortOrder': sortOrder,
        'createdOnUtc': createdOnUtc,
        'deleted': deleted,
        'isCharter': isCharter,
        'projectStatus': projectStatus?.toJson(),
        'projectActivities': projectActivities,
        'projectEmployeeMappings': projectEmployeeMappings,
        'projectFileList': projectFileList,
        'projectTasks': projectTasks,
        'storyBoards': storyBoards,
        'projectModules': projectModules,
        'projectsMessages': projectsMessages,
        'projectUserMappings': projectUserMappings,
        'projectTags': projectTags,
        'issue': issue,
        'requirement': requirement,
        'testPlans': testPlans,
        'timesheetLine': timesheetLine,
        'projectWeeklyPlans': projectWeeklyPlans,
        'weeklyPlan': weeklyPlan,
        'monthlyPlan': monthlyPlan,
        'customProperties': customProperties,
      };
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
  final bool isIssueConverted;
  final bool isRequirementConverted;
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

  final List<dynamic> projectActivityModel;
  final List<dynamic> projectActivities;
  final List<dynamic> projectTaskStatusLog;
  final List<dynamic> projectTaskFilesList;
  final List<dynamic> projectTaskTags;
  final List<dynamic> projectTaskRelatedMappings;
  final List<ProjectWeeklyPlanDatesReqTaskIssueMapping>
      projectWeeklyPlanDatesReqTaskIssueMappingList;
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
    required this.isIssueConverted,
    required this.isRequirementConverted,
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
    required this.projectActivityModel,
    required this.projectActivities,
    required this.projectTaskStatusLog,
    required this.projectTaskFilesList,
    required this.projectTaskTags,
    required this.projectTaskRelatedMappings,
    required this.projectWeeklyPlanDatesReqTaskIssueMappingList,
    required this.id,
    required this.customProperties,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      projectId: json['projectId'] ?? '',
      projectTaskNumber: json['projectTaskNumber'] ?? 0,
      projectModuleId: json['projectModuleId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      priorityId: json['priorityId'] ?? '',
      estimateTime: (json['estimateTime'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] ?? false,
      isMoved: json['isMoved'] ?? false,
      isIssueConverted: json['isIssueConverted'] ?? false,
      isRequirementConverted: json['isRequirementConverted'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      activitiesCount: json['activitiesCount'] ?? 0,
      isDuplicate: json['isDuplicate'] ?? false,
      projectNotesCount: json['projectNotesCount'] ?? 0,
      projectTaskNotesCount: json['projectTaskNotesCount'] ?? 0,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      createdOnUtc: json['createdOnUtc'] ?? '',
      totalTimesheetEstHours: json['totalTimesheetEstHours'] ?? 0,
      status: Status.fromJson(json['status'] ?? const {}),
      projectActivityModel:
          List<dynamic>.from(json['projectActivityModel'] ?? const []),
      projectActivities:
          List<dynamic>.from(json['projectActivities'] ?? const []),
      projectTaskStatusLog:
          List<dynamic>.from(json['projectTaskStatusLog'] ?? const []),
      projectTaskFilesList:
          List<dynamic>.from(json['projectTaskFilesList'] ?? const []),
      projectTaskTags: List<dynamic>.from(json['projectTask_Tags'] ?? const []),
      projectTaskRelatedMappings:
          List<dynamic>.from(json['projectTaskRelatedMappings'] ?? const []),
      // projectWeeklyPlanDatesReqTaskIssueMappingList: ProjectWeeklyPlanDatesReqTaskIssueMappingList.fromJson(
      //     json['projectWeeklyPlanDatesReqTaskIssueMappingList'] ?? const []),
      projectWeeklyPlanDatesReqTaskIssueMappingList:
          (json['projectWeeklyPlanDatesReqTaskIssueMappingList']
                      as List<dynamic>? ??
                  [])
              .map((e) => ProjectWeeklyPlanDatesReqTaskIssueMapping.fromJson(
                  e as Map<String, dynamic>))
              .toList(),
      id: json['id'] ?? '',
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'projectTaskNumber': projectTaskNumber,
        'projectModuleId': projectModuleId,
        'name': name,
        'description': description,
        'priorityId': priorityId,
        'estimateTime': estimateTime,
        'active': active,
        'isMoved': isMoved,
        'isIssueConverted': isIssueConverted,
        'isRequirementConverted': isRequirementConverted,
        'sortOrder': sortOrder,
        'activitiesCount': activitiesCount,
        'isDuplicate': isDuplicate,
        'projectNotesCount': projectNotesCount,
        'projectTaskNotesCount': projectTaskNotesCount,
        'startDate': startDate,
        'endDate': endDate,
        'createdOnUtc': createdOnUtc,
        'totalTimesheetEstHours': totalTimesheetEstHours,
        'status': status.toJson(),
        'projectActivityModel': projectActivityModel,
        'projectActivities': projectActivities,
        'projectTaskStatusLog': projectTaskStatusLog,
        'projectTaskFilesList': projectTaskFilesList,
        'projectTask_Tags': projectTaskTags,
        'projectTaskRelatedMappings': projectTaskRelatedMappings,
        'projectWeeklyPlanDatesReqTaskIssueMappingList':
            projectWeeklyPlanDatesReqTaskIssueMappingList,
        'id': id,
        'customProperties': customProperties,
      };
}

class ProjectWeeklyPlanDatesReqTaskIssueMappingList {
  final List<ProjectWeeklyPlanDatesReqTaskIssueMapping>
      projectWeeklyPlanDatesReqTaskIssueMappingList;

  ProjectWeeklyPlanDatesReqTaskIssueMappingList({
    required this.projectWeeklyPlanDatesReqTaskIssueMappingList,
  });

  factory ProjectWeeklyPlanDatesReqTaskIssueMappingList.fromJson(
      Map<String, dynamic> json) {
    return ProjectWeeklyPlanDatesReqTaskIssueMappingList(
      projectWeeklyPlanDatesReqTaskIssueMappingList:
          (json['projectWeeklyPlanDatesReqTaskIssueMappingList']
                      as List<dynamic>? ??
                  [])
              .map((e) => ProjectWeeklyPlanDatesReqTaskIssueMapping.fromJson(
                  e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'projectWeeklyPlanDatesReqTaskIssueMappingList':
            projectWeeklyPlanDatesReqTaskIssueMappingList
                .map((e) => e.toJson())
                .toList(),
      };
}

class ProjectWeeklyPlanDatesReqTaskIssueMapping {
  final String createdOnUtc;
  final bool deleted;
  final ProjectWeeklyPlanDates projectWeeklyPlanDates;
  final String id;

  ProjectWeeklyPlanDatesReqTaskIssueMapping({
    required this.createdOnUtc,
    required this.deleted,
    required this.projectWeeklyPlanDates,
    required this.id,
  });

  factory ProjectWeeklyPlanDatesReqTaskIssueMapping.fromJson(
      Map<String, dynamic> json) {
    return ProjectWeeklyPlanDatesReqTaskIssueMapping(
      createdOnUtc: json['createdOnUtc'] as String? ?? '',
      deleted: json['deleted'] as bool? ?? false,
      projectWeeklyPlanDates: ProjectWeeklyPlanDates.fromJson(
          json['projectWeeklyPlanDates'] as Map<String, dynamic>? ?? {}),
      id: json['id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'createdOnUtc': createdOnUtc,
        'deleted': deleted,
        'projectWeeklyPlanDates': projectWeeklyPlanDates.toJson(),
        'id': id,
      };
}

class ProjectWeeklyPlanDates {
  final String weekDate;
  final bool isApproved;
  final bool isCompleted;
  final int completionPercentage;
  final String createdOnUtc;
  final String updatedOnUtc;
  final bool deleted;
  final List<dynamic> projectWeeklyPlanDatesLines;
  final List<dynamic> projectWeeklyPlanDatesReqTaskIssueMapping;
  final List<dynamic> employeeEstimateHoursForWeekSummaryList;
  final String id;

  ProjectWeeklyPlanDates({
    required this.weekDate,
    required this.isApproved,
    required this.isCompleted,
    required this.completionPercentage,
    required this.createdOnUtc,
    required this.updatedOnUtc,
    required this.deleted,
    required this.projectWeeklyPlanDatesLines,
    required this.projectWeeklyPlanDatesReqTaskIssueMapping,
    required this.employeeEstimateHoursForWeekSummaryList,
    required this.id,
  });

  factory ProjectWeeklyPlanDates.fromJson(Map<String, dynamic> json) {
    return ProjectWeeklyPlanDates(
      weekDate: json['weekDate'] as String? ?? '',
      isApproved: json['isApproved'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completionPercentage: json['completionPercentage'] as int? ?? 0,
      createdOnUtc: json['createdOnUtc'] as String? ?? '',
      updatedOnUtc: json['updatedOnUtc'] as String? ?? '',
      deleted: json['deleted'] as bool? ?? false,
      projectWeeklyPlanDatesLines:
          json['projectWeeklyPlanDatesLines'] as List<dynamic>? ?? [],
      projectWeeklyPlanDatesReqTaskIssueMapping:
          json['projectWeeklyPlanDatesReqTaskIssueMapping'] as List<dynamic>? ??
              [],
      employeeEstimateHoursForWeekSummaryList:
          json['employeeEstimateHoursForWeekSummaryList'] as List<dynamic>? ??
              [],
      id: json['id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'weekDate': weekDate,
        'isApproved': isApproved,
        'isCompleted': isCompleted,
        'completionPercentage': completionPercentage,
        'createdOnUtc': createdOnUtc,
        'updatedOnUtc': updatedOnUtc,
        'deleted': deleted,
        'projectWeeklyPlanDatesLines': projectWeeklyPlanDatesLines,
        'projectWeeklyPlanDatesReqTaskIssueMapping':
            projectWeeklyPlanDatesReqTaskIssueMapping,
        'employeeEstimateHoursForWeekSummaryList':
            employeeEstimateHoursForWeekSummaryList,
        'id': id,
      };
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
      dropDownValue: json['dropDownValue'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      active: json['active'] ?? false,
      id: json['id'] ?? '',
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'dropDownValue': dropDownValue,
        'sortOrder': sortOrder,
        'active': active,
        'id': id,
        'customProperties': customProperties,
      };
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
  final bool isIssueConverted;
  final bool isRequirementConverted;
  final List<dynamic> projectActivities;
  final List<dynamic> projectTasks;
  final List<dynamic> projectModuleDocumentModel;
  final List<dynamic> projectTaskModel;
  final List<dynamic> projectModuleFilesList;
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
    required this.isIssueConverted,
    required this.isRequirementConverted,
    required this.projectActivities,
    required this.projectTasks,
    required this.projectModuleDocumentModel,
    required this.projectTaskModel,
    required this.projectModuleFilesList,
    required this.id,
    required this.customProperties,
  });

  factory ProjectModule.fromJson(Map<String, dynamic> json) {
    return ProjectModule(
      name: json['name'] ?? '',
      projectModuleNumber: json['projectModuleNumber'] ?? 0,
      active: json['active'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      isDuplicate: json['isDuplicate'] ?? false,
      isMoved: json['isMoved'] ?? false,
      projectTasksCount: json['projectTasksCount'] ?? 0,
      createdOnUtc: json['createdOnUtc'] ?? '',
      projectModuleNotesCount: json['projectModuleNotesCount'] ?? 0,
      isIssueConverted: json['isIssueConverted'] ?? false,
      isRequirementConverted: json['isRequirementConverted'] ?? false,
      projectActivities:
          List<dynamic>.from(json['projectActivities'] ?? const []),
      projectTasks: List<dynamic>.from(json['projectTasks'] ?? const []),
      projectModuleDocumentModel:
          List<dynamic>.from(json['projectModuleDocumentModel'] ?? const []),
      projectTaskModel:
          List<dynamic>.from(json['projectTaskModel'] ?? const []),
      projectModuleFilesList:
          List<dynamic>.from(json['projectModuleFilesList'] ?? const []),
      id: json['id'] ?? '',
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'projectModuleNumber': projectModuleNumber,
        'active': active,
        'sortOrder': sortOrder,
        'isDuplicate': isDuplicate,
        'isMoved': isMoved,
        'projectTasksCount': projectTasksCount,
        'createdOnUtc': createdOnUtc,
        'projectModuleNotesCount': projectModuleNotesCount,
        'isIssueConverted': isIssueConverted,
        'isRequirementConverted': isRequirementConverted,
        'projectActivities': projectActivities,
        'projectTasks': projectTasks,
        'projectModuleDocumentModel': projectModuleDocumentModel,
        'projectTaskModel': projectTaskModel,
        'projectModuleFilesList': projectModuleFilesList,
        'id': id,
        'customProperties': customProperties,
      };
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
      dropDownValue: json['dropDownValue'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      active: json['active'] ?? false,
      id: json['id'] ?? '',
      customProperties:
          Map<String, dynamic>.from(json['customProperties'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'dropDownValue': dropDownValue,
        'sortOrder': sortOrder,
        'active': active,
        'id': id,
        'customProperties': customProperties,
      };
}

class CreatedByUser {
  final bool active;
  final bool deleted;
  final PersonWithFullName person;
  final String id;
  final bool emailConfirmed;
  final String securityStamp;
  final String concurrencyStamp;
  final bool phoneNumberConfirmed;
  final bool twoFactorEnabled;
  final bool lockoutEnabled;
  final int accessFailedCount;

  CreatedByUser({
    required this.active,
    required this.deleted,
    required this.person,
    required this.id,
    required this.emailConfirmed,
    required this.securityStamp,
    required this.concurrencyStamp,
    required this.phoneNumberConfirmed,
    required this.twoFactorEnabled,
    required this.lockoutEnabled,
    required this.accessFailedCount,
  });

  factory CreatedByUser.fromJson(Map<String, dynamic> json) {
    return CreatedByUser(
      active: json['active'] ?? false,
      deleted: json['deleted'] ?? false,
      person: PersonWithFullName.fromJson(json['person'] ?? const {}),
      id: json['id'] ?? '',
      emailConfirmed: json['emailConfirmed'] ?? false,
      securityStamp: json['securityStamp'] ?? '',
      concurrencyStamp: json['concurrencyStamp'] ?? '',
      phoneNumberConfirmed: json['phoneNumberConfirmed'] ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      lockoutEnabled: json['lockoutEnabled'] ?? false,
      accessFailedCount: json['accessFailedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'active': active,
        'deleted': deleted,
        'person': person.toJson(),
        'id': id,
        'emailConfirmed': emailConfirmed,
        'securityStamp': securityStamp,
        'concurrencyStamp': concurrencyStamp,
        'phoneNumberConfirmed': phoneNumberConfirmed,
        'twoFactorEnabled': twoFactorEnabled,
        'lockoutEnabled': lockoutEnabled,
        'accessFailedCount': accessFailedCount,
      };
}

class UpdatedByUser {
  final bool active;
  final bool deleted;
  final PersonWithFullName person;
  final String id;
  final bool emailConfirmed;
  final String securityStamp;
  final String concurrencyStamp;
  final bool phoneNumberConfirmed;
  final bool twoFactorEnabled;
  final bool lockoutEnabled;
  final int accessFailedCount;

  UpdatedByUser({
    required this.active,
    required this.deleted,
    required this.person,
    required this.id,
    required this.emailConfirmed,
    required this.securityStamp,
    required this.concurrencyStamp,
    required this.phoneNumberConfirmed,
    required this.twoFactorEnabled,
    required this.lockoutEnabled,
    required this.accessFailedCount,
  });

  factory UpdatedByUser.fromJson(Map<String, dynamic> json) {
    return UpdatedByUser(
      active: json['active'] ?? false,
      deleted: json['deleted'] ?? false,
      person: PersonWithFullName.fromJson(json['person'] ?? const {}),
      id: json['id'] ?? '',
      emailConfirmed: json['emailConfirmed'] ?? false,
      securityStamp: json['securityStamp'] ?? '',
      concurrencyStamp: json['concurrencyStamp'] ?? '',
      phoneNumberConfirmed: json['phoneNumberConfirmed'] ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      lockoutEnabled: json['lockoutEnabled'] ?? false,
      accessFailedCount: json['accessFailedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'active': active,
        'deleted': deleted,
        'person': person.toJson(),
        'id': id,
        'emailConfirmed': emailConfirmed,
        'securityStamp': securityStamp,
        'concurrencyStamp': concurrencyStamp,
        'phoneNumberConfirmed': phoneNumberConfirmed,
        'twoFactorEnabled': twoFactorEnabled,
        'lockoutEnabled': lockoutEnabled,
        'accessFailedCount': accessFailedCount,
      };
}

class PersonWithFullName {
  final bool deleted;
  final bool isCustomer;
  final String fullName;
  final List<dynamic> personSitesMapping;

  PersonWithFullName({
    required this.deleted,
    required this.isCustomer,
    required this.fullName,
    required this.personSitesMapping,
  });

  factory PersonWithFullName.fromJson(Map<String, dynamic> json) {
    return PersonWithFullName(
      deleted: json['deleted'] ?? false,
      isCustomer: json['isCustomer'] ?? false,
      fullName: json['fullName'] ?? '',
      personSitesMapping:
          List<dynamic>.from(json['personSitesMapping'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() => {
        'deleted': deleted,
        'isCustomer': isCustomer,
        'fullName': fullName,
        'personSitesMapping': personSitesMapping,
      };
}

// ------------------ End of models ------------------

// Convenience helpers
TaskAndActivityDetailsModel TaskAndActivityDetailsModelFromJson(String str) =>
    TaskAndActivityDetailsModel.fromJson(
        json.decode(str) as Map<String, dynamic>);

String TaskAndActivityDetailsModelToJson(TaskAndActivityDetailsModel data) =>
    json.encode(data.toJson());

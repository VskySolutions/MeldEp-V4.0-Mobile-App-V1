class TimeInTimeOutOnIdResponseModel {
  final String? timeInDate;
  final double? timeIn;
  final double? timeOut;
  final double? totalHours;
  final double? totalBreak;
  final double? actualHours;
  final String? createdOnUtc;
  final String? updatedOnUtc;
  final bool? deleted;
  final String? timeInStr;
  final String? timeOutStr;
  final Employee? employee;
  final CreatedBy? createdBy;
  final UpdatedBy? updatedBy;

  // added both collections
  final List<BreakDetail>? timeInTimeOutBreakDetailModel;
  final List<BreakDetail>? timeInTimeOutBreakDetailList;

  TimeInTimeOutOnIdResponseModel({
    this.timeInTimeOutBreakDetailModel,
    this.timeInTimeOutBreakDetailList,
    this.timeInDate,
    this.timeIn,
    this.timeOut,
    this.totalHours,
    this.totalBreak,
    this.actualHours,
    this.createdOnUtc,
    this.updatedOnUtc,
    this.deleted,
    this.timeInStr,
    this.timeOutStr,
    this.employee,
    this.createdBy,
    this.updatedBy,
  });

  factory TimeInTimeOutOnIdResponseModel.fromJson(Map<String, dynamic> json) {
    // helper to parse a list of BreakDetail
    List<BreakDetail> parseBreaks(dynamic list) {
      if (list is List) {
        return list.map((e) => BreakDetail.fromJson(e)).toList();
      }
      return [];
    }

    return TimeInTimeOutOnIdResponseModel(
      timeInDate: json['timeInDate'] as String?,
      timeIn: (json['timeIn'] as num?)?.toDouble(),
      timeOut: (json['timeOut'] as num?)?.toDouble(),
      totalHours: (json['totalHours'] as num?)?.toDouble(),
      totalBreak: (json['totalBreak'] as num?)?.toDouble(),
      actualHours: (json['actualHours'] as num?)?.toDouble(),
      createdOnUtc: json['createdOnUtc'] as String?,
      updatedOnUtc: json['updatedOnUtc'] as String?,
      deleted: json['deleted'] as bool?,
      timeInStr: json['timeInStr'] as String?,
      timeOutStr: json['timeOutStr'] as String?,
      employee: json['employee'] != null
          ? Employee.fromJson(json['employee'] as Map<String, dynamic>)
          : null,
      createdBy: json['createdBy'] != null
          ? CreatedBy.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      updatedBy: json['updatedBy'] != null
          ? UpdatedBy.fromJson(json['updatedBy'] as Map<String, dynamic>)
          : null,

      // parse both arrays
      timeInTimeOutBreakDetailModel:
          parseBreaks(json['timeInTimeOutBreakDetailModel']),
      timeInTimeOutBreakDetailList:
          parseBreaks(json['timeInTimeOutBreakDetailList']),
    );
  }
}

class Employee {
  final Person? person;
  final String? id;

  Employee({this.person, this.id});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      person: json['person'] != null
          ? Person.fromJson(json['person'] as Map<String, dynamic>)
          : null,
      id: json['id'] as String?,
    );
  }
}

class Person {
  final String? fullName;

  Person({this.fullName});

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      fullName: json['fullName'] as String?,
    );
  }
}

class CreatedBy {
  final Person? person;

  CreatedBy({this.person});

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      person: json['person'] != null
          ? Person.fromJson(json['person'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UpdatedBy {
  final Person? person;

  UpdatedBy({this.person});

  factory UpdatedBy.fromJson(Map<String, dynamic> json) {
    return UpdatedBy(
      person: json['person'] != null
          ? Person.fromJson(json['person'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BreakDetail {
  final String? timeInTimeOutId;
  final double? breakIn;
  final double? breakOut;
  final double? totalBreak;
  final String? breakReason;
  final String? createdOnUtc;
  final bool? deleted;
  final String? breakInStr;
  final String? breakOutStr;
  final String? id;

  BreakDetail({
    this.timeInTimeOutId,
    this.breakIn,
    this.breakOut,
    this.totalBreak,
    this.breakReason,
    this.createdOnUtc,
    this.deleted,
    this.breakInStr,
    this.breakOutStr,
    this.id,
  });

  factory BreakDetail.fromJson(Map<String, dynamic> json) {
    return BreakDetail(
      timeInTimeOutId: json['timeInTimeOutId'] as String?,
      breakIn: (json['breakIn'] as num?)?.toDouble(),
      breakOut: (json['breakOut'] as num?)?.toDouble(),
      totalBreak: (json['totalBreak'] as num?)?.toDouble(),
      breakReason: json['breakReason'] as String?,
      createdOnUtc: json['createdOnUtc'] as String?,
      deleted: json['deleted'] as bool?,
      breakInStr: json['breakInStr'] as String?,
      breakOutStr: json['breakOutStr'] as String?,
      id: json['id'] as String?,
    );
  }
}

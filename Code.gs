// Google Apps Script (Code.gs) for WebTask Manager — Complete 4-Sheet Live REST API
// এই কোডটি আপনার Google Sheet (1ruS1ovIgL2EUpcfINXNVVV87Ym4U76osnIqb4enNgMk)-এর Extensions > Apps Script-এ পেস্ট করে Web App হিসেবে ডিপ্লয় করুন।

function doGet(e) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  
  var taskSheet = ss.getSheetByName("Tasks_Database");
  var updateSheet = ss.getSheetByName("Website_Updates_Log");
  var auditSheet = ss.getSheetByName("Audit_Logs");
  var userSheet = ss.getSheetByName("Users_Database");
  
  var taskData = taskSheet ? taskSheet.getDataRange().getValues() : [];
  var updateData = updateSheet ? updateSheet.getDataRange().getValues() : [];
  var auditData = auditSheet ? auditSheet.getDataRange().getValues() : [];
  var userData = userSheet ? userSheet.getDataRange().getValues() : [];
  
  var result = {
    status: "success",
    tasks: formatTasks(taskData),
    updates: formatUpdates(updateData),
    auditLogs: formatAuditLogs(auditData),
    users: formatUsers(userData)
  };
  
  return ContentService.createTextOutput(JSON.stringify(result))
    .setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  try {
    var params = JSON.parse(e.postData.contents);
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var nowStr = Utilities.formatDate(new Date(), "GMT+6", "yyyy-MM-dd HH:mm:ss");
    var shortNow = Utilities.formatDate(new Date(), "GMT+6", "yyyy-MM-dd HH:mm");
    
    // 1. Task Operations
    if (params.type === "ADD_TASK") {
      var taskSheet = getOrCreateSheet(ss, "Tasks_Database", [
        "Task_ID", "Title", "Website_Page", "Category", "Status", "Priority",
        "Assigned_To", "Release_Version", "Due_Date", "Last_Updated", "Notes"
      ]);
      var t = params.task;
      taskSheet.appendRow([
        t.id, t.title, t.page, t.category, t.status, t.priority,
        t.assignedTo, t.version, t.dueDate, t.lastUpdated || shortNow, t.notes || ""
      ]);
    } else if (params.type === "UPDATE_TASK") {
      var taskSheet = ss.getSheetByName("Tasks_Database");
      if (taskSheet) {
        var t = params.task;
        updateRowById(taskSheet, 0, t.id, [
          t.id, t.title, t.page, t.category, t.status, t.priority,
          t.assignedTo, t.version, t.dueDate, t.lastUpdated || shortNow, t.notes || ""
        ]);
      }
    } else if (params.type === "DELETE_TASK") {
      var taskSheet = ss.getSheetByName("Tasks_Database");
      if (taskSheet) {
        deleteRowById(taskSheet, 0, params.taskId);
      }
    }
    
    // 2. Website Update Log Operations
    else if (params.type === "ADD_UPDATE") {
      var updateSheet = getOrCreateSheet(ss, "Website_Updates_Log", [
        "Log_ID", "Release_Version", "Update_Title", "Page_Affected", "Deployed_At", "Status", "Summary"
      ]);
      var u = params.update;
      updateSheet.appendRow([
        u.id, u.version, u.title, u.page, u.date, u.status, u.summary
      ]);
    } else if (params.type === "DELETE_UPDATE") {
      var updateSheet = ss.getSheetByName("Website_Updates_Log");
      if (updateSheet) {
        deleteRowById(updateSheet, 0, params.updateId);
      }
    }
    
    // 3. Audit Log Operations
    else if (params.type === "ADD_AUDIT_LOG") {
      var auditSheet = getOrCreateSheet(ss, "Audit_Logs", [
        "Log_ID", "Timestamp", "User_Name", "User_Role", "Action_Type", "Target_Item", "Details_Log", "Severity"
      ]);
      var a = params.audit;
      auditSheet.appendRow([
        a.id, a.timestamp || nowStr, a.userName, a.userRole, a.actionType, a.targetItem, a.details, a.severity || "Low"
      ]);
    }
    
    // 4. User & Auth Operations
    else if (params.type === "ADD_USER") {
      var userSheet = getOrCreateSheet(ss, "Users_Database", [
        "User_ID", "Full_Name", "Email", "Password", "Role", "Department", "Status", "Last_Login"
      ]);
      var usr = params.user;
      userSheet.appendRow([
        usr.id, usr.name, usr.email, usr.password, usr.role, usr.department, usr.status || "Active", usr.lastLogin || "-"
      ]);
    } else if (params.type === "UPDATE_USER") {
      var userSheet = ss.getSheetByName("Users_Database");
      if (userSheet) {
        var usr = params.user;
        updateRowById(userSheet, 0, usr.id, [
          usr.id, usr.name, usr.email, usr.password, usr.role, usr.department, usr.status || "Active", usr.lastLogin || shortNow
        ]);
      }
    } else if (params.type === "DELETE_USER") {
      var userSheet = ss.getSheetByName("Users_Database");
      if (userSheet) {
        deleteRowById(userSheet, 0, params.userId);
      }
    } else if (params.type === "USER_LOGIN") {
      var userSheet = ss.getSheetByName("Users_Database");
      if (userSheet) {
        updateCellById(userSheet, 0, params.userId, 7, params.lastLogin || shortNow);
      }
    }
    
    // Optional piggybacked audit log
    if (params.audit && params.type !== "ADD_AUDIT_LOG") {
      var auditSheet = getOrCreateSheet(ss, "Audit_Logs", [
        "Log_ID", "Timestamp", "User_Name", "User_Role", "Action_Type", "Target_Item", "Details_Log", "Severity"
      ]);
      var a = params.audit;
      auditSheet.appendRow([
        a.id, a.timestamp || nowStr, a.userName, a.userRole, a.actionType, a.targetItem, a.details, a.severity || "Low"
      ]);
    }
    
    return ContentService.createTextOutput(JSON.stringify({ status: "success" }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ status: "error", message: err.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function getOrCreateSheet(ss, name, headers) {
  var sheet = ss.getSheetByName(name);
  if (!sheet) {
    sheet = ss.insertSheet(name);
    sheet.appendRow(headers);
  }
  return sheet;
}

function updateRowById(sheet, idColIndex, targetId, newRowValues) {
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][idColIndex]) === String(targetId)) {
      sheet.getRange(i + 1, 1, 1, newRowValues.length).setValues([newRowValues]);
      return true;
    }
  }
  sheet.appendRow(newRowValues);
  return false;
}

function updateCellById(sheet, idColIndex, targetId, targetColIndex, newValue) {
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][idColIndex]) === String(targetId)) {
      sheet.getRange(i + 1, targetColIndex + 1).setValue(newValue);
      return true;
    }
  }
  return false;
}

function deleteRowById(sheet, idColIndex, targetId) {
  var data = sheet.getDataRange().getValues();
  for (var i = data.length - 1; i >= 1; i--) {
    if (String(data[i][idColIndex]) === String(targetId)) {
      sheet.deleteRow(i + 1);
      return true;
    }
  }
  return false;
}

function formatRows(data) {
  if (!data || data.length <= 1) return [];
  var headers = data[0];
  var rows = [];
  for (var i = 1; i < data.length; i++) {
    var item = {};
    for (var j = 0; j < headers.length; j++) {
      item[headers[j]] = data[i][j];
    }
    rows.push(item);
  }
  return rows;
}

function formatTasks(data) {
  return formatRows(data).map(function(r) {
    return {
      id: String(r.Task_ID || r.id || ""),
      title: String(r.Title || r.title || ""),
      page: String(r.Website_Page || r.page || "/"),
      category: String(r.Category || r.category || "Feature"),
      status: String(r.Status || r.status || "To Do"),
      priority: String(r.Priority || r.priority || "Medium"),
      assignedTo: String(r.Assigned_To || r.assignedTo || "Unassigned"),
      version: String(r.Release_Version || r.version || "v1.0.0"),
      dueDate: formatDateVal(r.Due_Date || r.dueDate),
      lastUpdated: formatDateTimeVal(r.Last_Updated || r.lastUpdated),
      notes: String(r.Notes || r.notes || "")
    };
  });
}

function formatUpdates(data) {
  return formatRows(data).map(function(r) {
    return {
      id: String(r.Log_ID || r.id || ""),
      version: String(r.Release_Version || r.version || ""),
      title: String(r.Update_Title || r.title || ""),
      page: String(r.Page_Affected || r.page || "/all"),
      date: formatDateVal(r.Deployed_At || r.date),
      status: String(r.Status || r.status || "Live"),
      summary: String(r.Summary || r.summary || "")
    };
  });
}

function formatAuditLogs(data) {
  return formatRows(data).map(function(r) {
    return {
      id: String(r.Log_ID || r.id || ""),
      timestamp: formatDateTimeVal(r.Timestamp || r.timestamp),
      userName: String(r.User_Name || r.userName || ""),
      userRole: String(r.User_Role || r.userRole || ""),
      actionType: String(r.Action_Type || r.actionType || ""),
      targetItem: String(r.Target_Item || r.targetItem || ""),
      details: String(r.Details_Log || r.details || ""),
      severity: String(r.Severity || r.severity || "Low")
    };
  });
}

function formatUsers(data) {
  return formatRows(data).map(function(r) {
    return {
      id: String(r.User_ID || r.id || ""),
      name: String(r.Full_Name || r.name || ""),
      email: String(r.Email || r.email || ""),
      password: String(r.Password || r.password || ""),
      role: String(r.Role || r.role || "Viewer"),
      department: String(r.Department || r.department || ""),
      status: String(r.Status || r.status || "Active"),
      lastLogin: formatDateTimeVal(r.Last_Login || r.lastLogin)
    };
  });
}

function formatDateVal(val) {
  if (!val) return "";
  if (Object.prototype.toString.call(val) === "[object Date]") {
    return Utilities.formatDate(val, "GMT+6", "yyyy-MM-dd");
  }
  return String(val).substring(0, 10);
}

function formatDateTimeVal(val) {
  if (!val) return "";
  if (Object.prototype.toString.call(val) === "[object Date]") {
    return Utilities.formatDate(val, "GMT+6", "yyyy-MM-dd HH:mm");
  }
  return String(val);
}

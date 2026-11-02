// Google Apps Script (Code.gs) for WebTask Database
// এই কোডটি আপনার Google Sheet-এর Extensions > Apps Script-এ পেস্ট করে Web App হিসেবে ডিপ্লয় করুন।

function doGet(e) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var taskSheet = ss.getSheetByName("Tasks_Database");
  var updateSheet = ss.getSheetByName("Website_Updates_Log");
  
  var taskData = taskSheet ? taskSheet.getDataRange().getValues() : [];
  var updateData = updateSheet ? updateSheet.getDataRange().getValues() : [];
  
  var result = {
    status: "success",
    tasks: formatRows(taskData),
    updates: formatRows(updateData)
  };
  return ContentService.createTextOutput(JSON.stringify(result))
    .setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  try {
    var params = JSON.parse(e.postData.contents);
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    
    if (params.type === "ADD_TASK") {
      var sheet = ss.getSheetByName("Tasks_Database");
      sheet.appendRow([
        params.task.id,
        params.task.title,
        params.task.page,
        params.task.category,
        params.task.status,
        params.task.priority,
        params.task.assignedTo,
        params.task.version,
        params.task.dueDate,
        Utilities.formatDate(new Date(), "GMT+6", "yyyy-MM-dd HH:mm"),
        params.task.notes
      ]);
    } else if (params.type === "ADD_UPDATE") {
      var sheet = ss.getSheetByName("Website_Updates_Log");
      sheet.appendRow([
        params.update.id,
        params.update.version,
        params.update.title,
        params.update.page,
        params.update.date,
        params.update.status,
        params.update.summary
      ]);
    }
    return ContentService.createTextOutput(JSON.stringify({status: "success"}))
      .setMimeType(ContentService.MimeType.JSON);
  } catch(err) {
    return ContentService.createTextOutput(JSON.stringify({status: "error", message: err.toString()}))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function formatRows(data) {
  if (data.length <= 1) return [];
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

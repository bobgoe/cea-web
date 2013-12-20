'use strict';
define([], function() {
  var tasks = {
    'available' : [
      { id: "overview",
        title: "Overview",
        controller: "OverviewController",
        templateUrl: "overview.html",
        requires: [],
        resets: [] },
      { id: "results",
        title: "Results",
        controller: 'ResultsController',
        templateUrl: 'results.html',
        requires: ['scale-ranges', 'partial-value-functions'],
        resets: []}
    ]};

  var defaultView = "overview";

  var createPath = function(workspaceId, scenarioId, taskId) {
    taskId = taskId ? taskId : defaultView;
    return "#/workspaces/" + workspaceId + "/scenarios/" + scenarioId + "/" + taskId;
  };

  return {
    tasks: tasks,
    defaultView: defaultView,
    createPath: createPath
  };
});

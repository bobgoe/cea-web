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
      { id: "disease-state-model",
        title: "Disease State Model",
        controller: 'DiseaseStateModelController',
        templateUrl: 'diseaseStateModel.html',
        requires: [],
        resets: []},
      { id: "costaccounting",
        title: "Account Costs",
        controller: 'AccountCostsController',
        templateUrl: 'accountCosts.html',
        requires: [], //'disease-state-model', 'partial-value-functions'
        resets: []},
      { id: "results",
        title: "Results",
        controller: 'ResultsController',
        templateUrl: 'results.html',
        requires: [], //'scale-ranges', 'partial-value-functions'
        resets: []},
      { id: "graph-creator",
        title: "Graph Creator TEST",
        controller: 'GraphCreatorController',
        templateUrl: 'graphCreator.html',
        requires: [], //'scale-ranges', 'partial-value-functions'
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

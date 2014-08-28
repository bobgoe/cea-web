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
      { id: "patient-characteristics",
        title: "Patient Characteristics",
        controller: 'PatientCharacteristicsController',
        templateUrl: 'patientCharacteristics.html',
        requires: [], 
        resets: []},  
      { id: "state-transition-model",
        title: "State Transition Model",
        controller: 'StateTransitionModelController',
        templateUrl: 'stateTransitionModel.html',
        requires: [],
        resets: []},
      { id: "trial-network",
        title: "Trial Network",
        controller: 'TrialNetworkController',
        templateUrl: 'trialNetwork.html',
        requires: [],
        resets: []},
      { id: "simulation-parameters",
        title: "Simulation Parameters",
        controller: 'SimulationParametersController',
        templateUrl: 'simulationParameters.html',
        requires: [], 
        resets: []},
      { id: "results",
        title: "Results",
        controller: 'ResultsController',
        templateUrl: 'results.html',
        requires: [], 
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

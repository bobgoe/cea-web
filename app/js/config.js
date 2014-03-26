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
      { id: "disease-states",
        title: "Alter Disease States",
        controller: 'DiseaseStatesController',
        templateUrl: 'diseaseStates.html',
        requires: [], 
        resets: []},  
      { id: "transition-probabilities",
        title: "Transition Probabilities",
        controller: 'TransitionProbabilitiesController',
        templateUrl: 'transitionProbabilities.html',
        requires: [],
        resets: []},
      { id: "account-effects",
        title: "Account Effects",
        controller: 'AccountEffectsController',
        templateUrl: 'accountEffects.html',
        requires: [],
        resets: []},
      { id: "account-costs",
        title: "Account Costs",
        controller: 'AccountCostsController',
        templateUrl: 'accountCosts.html',
        requires: [], //'disease-state-model', 'partial-value-functions'
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

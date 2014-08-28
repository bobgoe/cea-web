'use strict';
define(function(require) {
  var angular = require('angular');
    return angular.module('elicit.controllers', [])
          .controller('ChooseProblemController', require('controllers/chooseProblem'))
          .controller('WorkspaceController', require('controllers/workspace'))
          .controller('OverviewController', require('controllers/overview'))
          .controller('ResultsController', require('controllers/results'))
          .controller('PatientCharacteristicsController', require('controllers/patientCharacteristics'))
          .controller('SimulationParametersController', require('controllers/simulationParameters'))
          .controller('StateTransitionModelController', require('controllers/stateTransitionModel'))
          .controller('TrialNetworkController', require('controllers/trialNetwork'));
});
'use strict';
define(function(require) {
  var angular = require('angular');
    return angular.module('elicit.controllers', [])
          .controller('ChooseProblemController', require('controllers/chooseProblem'))
          .controller('WorkspaceController', require('controllers/workspace'))
          .controller('OverviewController', require('controllers/overview'))
          .controller('ResultsController', require('controllers/results'))
          .controller('DiseaseStateModelController', require('controllers/diseaseStateModel'))
          .controller('AccountCostsController', require('controllers/accountCosts'));
});
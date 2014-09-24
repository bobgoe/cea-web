'use strict';
define(['angular', 'lib/patavi', 'underscore'], function(angular, patavi, _) {
  return function($scope, currentScenario, taskDefinition) {
    var alternatives;
    var criteria;
    var scenario = angular.copy(currentScenario);
    
    $scope.covarState = scenario.state.problem.states[0].sojournTimeRate.values.treatments;
    
    console.log($scope.covarState);
    
    $scope.currentStep = taskDefinition.clean(currentScenario.state);
    
    $scope.save = function(currentState) {
      var state = angular.copy(currentState);
      scenario.update(state);
      scenario.redirectToDefaultView();
    };
  };
});
'use strict';
define(['angular', 'lib/patavi', 'underscore'], function(angular, patavi, _) {
  return function($scope, currentScenario, taskDefinition) {
    var alternatives;
    var criteria;
    var scenario = angular.copy(currentScenario);
    
    $scope.currentStep = taskDefinition.clean(currentScenario.state);
    
    $scope.iterableStateCosts = _.object(
        _.map(_.pairs(scenario.state.problem.alternatives), function(alternative) {
          var stateCosts = alternative[1].stateCosts;
          var states = _.pluck(scenario.state.problem.states, "title");
          function makeCellsNamed(rows) {
            return _.map(_.zip(states, rows), function(row) { return _.object(['state', 'value'], row) });
          }
          return [alternative[1].title, makeCellsNamed(stateCosts)];
        }));
    
    $scope.save = function(currentState) {
      var state = angular.copy(currentState);
      _.each(state.problem.alternatives, function(alternative) {
        function mapStateCosts(stateCosts) {
          return _.pluck(stateCosts, "value");
        };
        alternative.stateCosts = mapStateCosts($scope.iterableStateCosts[alternative.title]);
      });
      scenario.update(state);
      scenario.redirectToDefaultView();
    };
  };
});

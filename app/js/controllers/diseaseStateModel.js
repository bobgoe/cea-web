'use strict';
define(['angular', 'lib/patavi', 'underscore'], function(angular, patavi, _) {
  return function($scope, currentScenario, taskDefinition) {
    var alternatives;
    var criteria;
    var scenario = currentScenario;
    
    var run = function(state) {
      state = angular.copy(state);
      var data = state.problem;
      var task = patavi.submit('cea', data);

      var successHandler = function(results) {
        $scope.$root.$safeApply($scope, function() {
          state.results = results.results;
        });
      };

      var errorHandler = function(code, error) {
        var message = { code: (code && code.desc) ? code.desc : code,
                        cause: error };
        $scope.$root.$broadcast("patavi.error", message);
      };

      var updateHandler = _.throttle(function(update) {
        var progress = parseInt(update);
        if(progress > state.progress) {
          NProgress.set(progress / 100);
        }
      }, 30);

      state.progress = 0;
      task.results.then(successHandler, errorHandler, updateHandler);
      return state;
    };
    
    var initialize = function(state) {
      var next = _.extend(state, {});
      return run(next);
    };
    
    $scope.iterableTransitions = _.object(
      _.map(_.pairs(scenario.state.problem.alternatives), function(alternative) {
        var transitions = alternative[1].transition;
        var states = _.pluck(scenario.state.problem.states, "title");
        function makeCellsNamed(cells) { 
          return _.map(_.zip(states, cells), function(cell) { return _.object(['state', 'value'], cell) });
        }
        function makeRowsNamed(rows) {
          return _.map(_.zip(states, rows), function(row) { return _.object(['state', 'cells'], row) });
        }
        return [alternative[0], makeRowsNamed(_.map(transitions, makeCellsNamed))];
      }));
    
    $scope.currentStep = initialize(taskDefinition.clean(currentScenario.state));
    
    $scope.save = function(currentState) {
      var state = angular.copy(currentState);
      _.each(state.problem.alternatives, function(alternative) {
        function mapTransitions(transitions) {
          return _.map(_.pluck(transitions, "cells"), function(row) { return _.pluck(row, "value") });
        };
        alternative.transition = mapTransitions($scope.iterableTransitions[alternative.title]);
      });
      scenario.update(state);
      scenario.redirectToDefaultView();
    };
  };
});

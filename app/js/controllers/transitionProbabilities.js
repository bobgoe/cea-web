'use strict';
define(['angular', 'lib/patavi', 'underscore'], function(angular, patavi, _) {
  return function($scope, currentScenario, taskDefinition) {
    var alternatives;
    var criteria;
    var scenario = angular.copy(currentScenario);
    
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
        return [alternative[1].title, makeRowsNamed(_.map(transitions, makeCellsNamed))];
      }));
    
    $scope.currentStep = taskDefinition.clean(currentScenario.state);
    
    $scope.simulationApproaches = [
                                  {
                                    "id": 0, 
                                    "name":"Deterministic, WIP", 
                                    "approach":"Deterministic", 
                                    "value": "Deterministic"
                                   },
                                   {
                                     "id": 1, 
                                     "name":"Deterministic, relative effect, WIP", 
                                     "approach":"Deterministic", 
                                     "value": "DeterministicRelativeEffect"
                                    },
                                    {
                                     "id": 2, 
                                     "name":"Probabilistic", 
                                     "approach":"Probabilistic", 
                                     "value": "Probabilistic"
                                    },
                                    {
                                      "id": 3, 
                                      "name":"Probabilistic, relative effect", 
                                      "approach":"Probabilistic", 
                                      "value": "ProbabilisticRelativeEffect"
                                    }
                                  ];
    
    $scope.simulationApproachInitialize = $scope.simulationApproaches[scenario.state.problem.simulationApproach.id];
    
    $scope.simulationApproach = $scope.simulationApproaches;
    
    $scope.disable = function(value) {
      if ( value == null ) {
        return true;
      }
      return false;
    }
    
    $scope.save = function(currentState) {
      var state = angular.copy(currentState);
      _.each(state.problem.alternatives, function(alternative) {
        function mapTransitions(transitions) {
          return _.map(_.pluck(transitions, "cells"), function(row) { return _.pluck(row, "value") });
        };
        alternative.transition = mapTransitions($scope.iterableTransitions[alternative.title]);
      });
      state.problem.simulationApproach = $scope.simulationApproaches[$scope.simulationApproach.id];
      scenario.update(state);
      scenario.redirectToDefaultView();
    };
    
  };
});

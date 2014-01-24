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
    
    $scope.currentStep = initialize(taskDefinition.clean(currentScenario.state));
    
    $scope.save = function(currentState) {
      var state = angular.copy(currentState);
      scenario.update(state);
      scenario.redirectToDefaultView();
    };
  };
});

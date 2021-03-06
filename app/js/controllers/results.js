'use strict';
define(['angular', 'lib/patavi', 'underscore', 'NProgress'], function(angular, patavi, _, NProgress) {
  return function($rootScope, $scope, currentScenario, taskDefinition) {
    var alternatives;
    var criteria;

    $rootScope.noProgress = true;

    var run = function(state) {
      state = angular.copy(state);
      var data = state.problem;
      
      // Take care of all null values we use in the web space
      for (var a in data.alternatives){
        for (var b in data.alternatives[a].transition){
          for (var c in data.alternatives[a].transition[b]){
            if (data.alternatives[a].transition[b][c] == null) data.alternatives[a].transition[b][c] = 0;
          }
        }
      }
      
      var task = patavi.submit('cea', data);

      var successHandler = function(results) {
        $scope.$root.$safeApply($scope, function() {
          state.results = results.results;
          $rootScope.noProgress = false;
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

    var alternativeTitle = function(id) {
      return alternatives[id].title;
    };
    
    var getCEAC = _.memoize(function(state) {
      var data = state.results;
      var result = [];
      
      for(var i in data) {
        var resultLine = {};
        var line = data[i];
        resultLine.key = i;
        resultLine.values = [];
        
        for(var j in line) {
          var value = {};
          value.x = line[j].x;
          value.y = line[j].y;
          resultLine.values.push(value);
        }
        result.push(resultLine);
      }
      return result;
    });
    
    var initialize = function(state) {
      var next = _.extend(state, {});
      return run(next);
    };

    $scope.currentStep = initialize(taskDefinition.clean(currentScenario.state));
    $scope.CEAC = getCEAC;
  };
});

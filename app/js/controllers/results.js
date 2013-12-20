'use strict';
define(['angular', 'lib/patavi', 'underscore', 'NProgress'], function(angular, patavi, _, NProgress) {
  return function($rootScope, $scope, currentScenario, taskDefinition) {
    var alternatives;
    var criteria;

    $rootScope.noProgress = true;

    var run = function(state) {
      state = angular.copy(state);
      var data = state.problem;
      console.log("data: ", data)
      var task = patavi.submit('cea', data);
      console.log("task: ", task)

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

    var getCentralWeights = _.memoize(function(state) {
      var data = state.results.cw.data;
      var result = [];
      _.each(_.pairs(data), function(alternative) {
        var values = _.map(_.pairs(alternative[1]['w']), function(criterion, index) {
          return { x: index, label: criterion[0], y: criterion[1] };
        });
        var labels = _.map(_.pluck(values, 'label'), function(id) { return criteria[id].title; });
        result.push({ key: alternativeTitle(alternative[0]), labels: labels, values: values });
      });
      return result;
    });
    
    var getCEAC = _.memoize(function(state) {
      var data = state.results;
      var result = [];
      
      for(var i in data) {
        var resultLine = {};
        var line = data[i];
        
        resultLine.key = i;
        resultLine.labels = [];
        resultLine.values = [];
        for(var j in line) {
          var value = {};
          value.series = 0;
          value.x = line[j].x;
          value.y = line[j].y;
          resultLine.values.push(value);
          var hoi = line[j].x;
          console.log("xlabel: ", hoi);
          resultLine.labels.push(hoi);
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

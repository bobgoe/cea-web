'use strict';
define(['angular', 'underscore'], function(angular, _) {

  return function($scope, Tasks, TaskDependencies, currentScenario, taskDefinition) {
    var scenario = currentScenario;
    $scope.scenario = scenario;

    var state = taskDefinition.clean(scenario.state);
    var problem = state.problem;

    var tasks = _.map(Tasks.available, function(task) {
      return { 'task': task,
               'accessible': TaskDependencies.isAccessible(task, state),
               'safe': TaskDependencies.isSafe(task, state) }; });

    $scope.tasks = {
      'accessible' : _.filter(tasks, function(task) {
        return task.accessible.accessible && task.safe.safe; }),
      'destructive': _.filter(tasks, function(task) {
        return task.accessible.accessible && !task.safe.safe; }),
      'inaccessible': _.filter(tasks, function(task) {
        return !task.accessible.accessible; })
    };

    $scope.dependenciesString = function(dependencies) {
      var result = "";
      _.each(dependencies, function(dep) {
        result = result + "<br> - " + TaskDependencies.definitions[dep].title;
      });
      return result;
    };

    $scope.problem = problem;
  };

});

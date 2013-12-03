'use strict';
define(
  ['angular',
   'require',
   'underscore',
   'jQuery',
   'NProgress',
   'config',
   'angular-ui-router',
   'services/decisionProblem',
   'services/workspaces',
   'services/taskDependencies',
   'foundation.dropdown',
   'foundation.tooltip',
   'controllers',
   'directives',
   'filters'],
  function(angular, require, _, $, NProgress, Config) {
    var dependencies = [
      'ui.router',
      'elicit.problem-resource',
      'elicit.workspaces',
      'elicit.directives',
      'elicit.filters',
      'elicit.controllers',
      'elicit.taskDependencies'];
    var app = angular.module('elicit', dependencies);

    app.run(['$rootScope', function($rootScope) {
      $rootScope.$on('$viewContentLoaded', function () {
        $(document).foundation();
      });

      // from http://stackoverflow.com/questions/16952244/what-is-the-best-way-to-close-a-dropdown-in-zurb-foundation-4-when-clicking-on-a
      $('.f-dropdown').click(function() {
        if ($(this).hasClass('open')) {
          $('[data-dropdown="'+$(this).attr('id')+'"]').trigger('click');
        }
      });

      $rootScope.$safeApply = function($scope, fn) {
        var phase = $scope.$root.$$phase;
        if(phase == '$apply' || phase == '$digest') {
          this.$eval(fn);
        }
        else {
          this.$apply(fn);
        }
      };
      $rootScope.$on('patavi.error', function(e, message) {
        $rootScope.$safeApply($rootScope, function() {
          $rootScope.error = message;
        });
      });

      $rootScope.$on('$stateChangeStart', function(e, state) {
        $rootScope.inTransition = true;
        !$rootScope.noProgress && NProgress.start();
      });

      $rootScope.$on('$stateChangeSuccess', function(e, state) {
        $rootScope.inTransition = false;
        !$rootScope.noProgress && NProgress.done();
      });

      $rootScope.$on('$viewContentLoading', function(e, state) {
        NProgress.inc();
      });




    }]);
    app.constant('Tasks', Config.tasks);


    app.config(['Tasks', '$stateProvider', '$urlRouterProvider', function(Tasks, $stateProvider, $urlRouterProvider) {
      var baseTemplatePath = "app/views/";

      $stateProvider.state("workspace", {
        url: '/workspaces/:workspaceId/scenarios/:scenarioId',
        templateUrl: baseTemplatePath + 'workspace.html',
        resolve: {
          currentWorkspace: function($stateParams, Workspaces) {
            return Workspaces.get($stateParams.workspaceId);
          },
          currentScenario: function($stateParams, currentWorkspace) {
            return currentWorkspace.getScenario($stateParams.scenarioId);
          }
        },
        controller: 'WorkspaceController'
      });


      _.each(Tasks.available, function(task) {
        var camelCase = function (str) { return str.replace(/-([a-z])/g, function (g) { return g[1].toUpperCase(); }); };
        var templateUrl = baseTemplatePath + task.templateUrl;
        $stateProvider.state(task.id, {
          parent: 'workspace',
          url: '/' + task.id,
          templateUrl: templateUrl,
          controller: task.controller,
          resolve : {
            taskDefinition: function(currentScenario, TaskDependencies) {
              var def = TaskDependencies.extendTaskDefinition(task);
              return def;
            }
          }
        });
      });

      // Default route
      $stateProvider.state('choose-problem',
                           { url: '/choose-problem',
                             templateUrl: baseTemplatePath + 'chooseProblem.html',
                             controller: "ChooseProblemController" });
      $urlRouterProvider.otherwise('/choose-problem');
    }]);

    return app;
  });

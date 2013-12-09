'use strict';
define(['angular', 'underscore', 'lib/patavi'], function(angular, _, patavi) {

return function($scope){
	
	var hoi = 2
	
	$scope.patavi = function() {
		
		hoi = hoi + 1
		$scope.test = hoi;
	
	};
	
	$scope.method = "smaa";
	  $scope.input = "{}";
	
	  $scope.submit = function(method, input) {
	    var task = patavi.submit(method, angular.fromJson(input));
	    $scope.error = null;
	    $scope.status = null;
	    $scope.results = null;
	
	    var handlerFactory = function(type) {
	      return function(x) {
	        $scope[type] = x;
	        $scope.$apply();
	      };
	    };
	
	    var progressHandler = handlerFactory("status");
	    var errorHandler = handlerFactory("error");
	    var successHandler = handlerFactory("results");
	
	    task.results.then(successHandler, errorHandler, progressHandler);
	  };
	
};
	
});
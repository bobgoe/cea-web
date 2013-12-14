'use strict';
define(['angular', 'underscore', 'lib/patavi'], function(angular, _, patavi) {

return function($scope){
	
	var hoi = 2
	
	$scope.patavi = function() {
		
		hoi = hoi + 1
		$scope.test = hoi;
	
	};
	
	$scope.method = "test";
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
	  
	  var getBobFunctie = _.memoize(function(state) {
	        var data = {
	        	"Placebo": [
	        	  { x:0,
	        		y: 1
	        	  },
	        	  { x:1,
	          		y: 0
	          	  },
	        	  { x:2,
	          		y: 0
	          	  },     
	        	],
	        	"Blaat": [
             	  { x:0,
              		y: 0
              	  },
              	  { x:1,
                	y: 0.2
                  },
              	  { x:2,
                	y: 0.8
                  },     
	            ],
	            "Leuke naam": [
             	  { x:0,
             		y: 0
             	  },
             	  { x:1,
               		y: 0.8
               	  },
             	  { x:2,
               		y: 0.2
               	  },     
             	],
	        }
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
	        		resultLine.labels.push(j);
	        	}
	        	
	        	result.push(resultLine);
	        }
	        console.log('dit hebben we gemaakt', result);
	        return result;
	      });
	  
	  var initialize = function(state) {
	      var next = _.extend(state, {
	        bobFunctie: getBobFunctie
	      });
	      return run(next);
	    };
	    
	    $scope.bobFunctie = getBobFunctie;
};
	
});
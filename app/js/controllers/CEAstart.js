'use strict';
define(['angular', 'underscore', 'lib/patavi'], function(angular, _, patavi) {

return function($scope,$http){
	
	  $scope.submit = function(method, input) {
		  
		// Define inputs for Patavi, method is test which relates to test worker started in virtual server
		$scope.method = "test";
		//$scope.input, for the input of the model we get the data from a json file, if we get the data we use it.
		$http.get('/examples/CEA/CEAexample.json')
	    .then(function(results){
	        //Success;
	        console.log("Success: ", results.data);
	        $scope.input = results.data;
	        
	        // send the data to patavi, which runs the R script for us.
	        var task = patavi.submit($scope.method, $scope.input);
		    $scope.error = null;
		    $scope.status = null;
		    $scope.results = null;
		
		    var handlerFactory = function(type) {
		      return function(x) {
		        $scope[type] = x;
		        $scope.$apply();
		      };
		    };
		
		    // Post results, if something goes wrong also post that
		    var progressHandler = handlerFactory("status");
		    var errorHandler = handlerFactory("error");
		    var successHandler = handlerFactory("results");
		
		    task.results.then(successHandler, errorHandler, progressHandler);
	        
		    // if we do not get the data post the error
	    }, function(results){
	        //error
	    	task.results.then("Error: " + results.data + "; "
	                              + results.status);
	    }); 
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
	          	  { x:3,
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
                  { x:3,
  	          		y: 1
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
               	  { x:3,
  	          		y: 0
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